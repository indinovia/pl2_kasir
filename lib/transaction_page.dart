import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionPage extends StatefulWidget {
  final int userId;
  final String username;

  const TransactionPage({
    Key? key,
    required this.userId,
    required this.username,
  }) : super(key: key);

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> customers = [];
  List<Map<String, dynamic>> cart = [];
  Map<String, dynamic>? selectedCustomer;
  bool isLoading = true;
  bool isPaymentPage = false;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final productResponse = await supabase.from('produk').select();
      final customerResponse = await supabase.from('pelanggan').select();

      setState(() {
        products = List<Map<String, dynamic>>.from(productResponse);
        customers = List<Map<String, dynamic>>.from(customerResponse);
        isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch data: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submitTransaction() async {
    if (selectedCustomer == null || cart.isEmpty) {
      _showError('Please select a customer and add products to the cart.');
      return;
    }

    setState(() {
      isPaymentPage = true;
    });
  }

void _showReceipt(double totalHarga, String customerName) {
  final DateTime now = DateTime.now();
  final String formattedDate = "${now.day}/${now.month}/${now.year} ${now.hour}:${now.minute}:${now.second}";

showDialog(
  context: context,
  builder: (context) {
    return AlertDialog(
      title: const Text('Struk Pembayaran', textAlign: TextAlign.center),
      content: Container(
        width: double.maxFinite,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black.withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                'INOV CAFE',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const Divider(),
            Center(child: Text('Struk Pembayaran', style: TextStyle(fontSize: 16))),
            const Divider(),
            Text('Nama Pelanggan: $customerName'),
            const SizedBox(height: 8),
            Text('Tanggal: $formattedDate'),
            const SizedBox(height: 10),
            const Divider(),
            // Menampilkan list barang dengan quantity dan harga
            ...cart.map((item) {
              double price = item['harga']; // Harga satuan (ubah field ke harga)
              int qty = item['stok']; // Stok (ubah field ke stok)
              double subtotal = price * qty; // Menghitung subtotal

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Nama barang
                    Expanded(child: Text('${item['nama_produk']}')),
                    // Jika quantity lebih dari 1, tampilkan perhitungan
                    Text(qty > 1
                        ? 'Rp. $price x $qty = Rp. $subtotal'
                        : 'Rp. $price'), // Menampilkan harga satuan jika qty 1
                  ],
                ),
              );
            }).toList(),
            const Divider(),
            // Menampilkan total harga
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total:'),
                  Text(
                    'Rp. $totalHarga', // Total harga keseluruhan
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            const SizedBox(height: 10),
            Center(child: Text('Terima kasih atas kunjungannya!', style: TextStyle(fontStyle: FontStyle.italic))),
          ],
        ),
      ),
    );
  },
);

}


  void _completePayment() async {
    try {
      final totalHarga = cart.fold(0.0, (sum, item) => sum + item['subtotal']);
      final penjualanResponse = await supabase.from('penjualan').insert({
        'tanggal_penjualan': DateTime.now().toIso8601String(),
        'total_harga': totalHarga,
        'pelanggan_id': selectedCustomer!['pelanggan_id'],
      }).select();

      final penjualanId = penjualanResponse[0]['penjualan_id'];

      for (final item in cart) {
        await supabase.from('detail_penjualan').insert({
          'penjualan_id': penjualanId,
          'produk_id': item['produk_id'],
          'jumlah_produk': item['jumlah'],
          'subtotal': item['subtotal'],
        });

        await supabase.from('produk').update({
          'stok': item['stok'] - item['jumlah'],
        }).eq('produk_id', item['produk_id']);
      }

      final customerName = selectedCustomer!['nama_pelanggan'];

      setState(() {
        cart.clear();
        selectedCustomer = null;
        isPaymentPage = false;
      });

      _showReceipt(totalHarga, customerName);
    } catch (e) {
      _showError('Failed to complete transaction: $e');
    }
  }

  void _updateCartQuantity(int index, int change) {
    setState(() {
      final newQuantity = cart[index]['jumlah'] + change;
      if (newQuantity > 0 && newQuantity <= cart[index]['stok']) {
        cart[index]['jumlah'] = newQuantity;
        cart[index]['subtotal'] = cart[index]['harga'] * newQuantity;
      } else if (newQuantity == 0) {
        cart.removeAt(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(0, 150, 0, 125),
        title: const Text('Kasir - Transaksi'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!isPaymentPage)
                      DropdownButton<Map<String, dynamic>>(
                        value: selectedCustomer,
                        hint: const Text('Pilih Pelanggan'),
                        items: customers.map((customer) {
                          return DropdownMenuItem(
                            value: customer,
                            child: Text(customer['nama_pelanggan']),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            selectedCustomer = value;
                          });
                        },
                      ),
                    const SizedBox(height: 16),
                    if (!isPaymentPage)
                      const Text(
                        'Produk:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    if (!isPaymentPage)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return Card(
                            elevation: 5,
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(product['nama_produk']),
                              subtitle: Text(
                                  'Stok: ${product['stok']} | Harga: Rp. ${product['harga']}'),
                              trailing: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color.fromARGB(
                                      255, 255, 183, 247),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    cart.add({
                                      'produk_id': product['produk_id'],
                                      'nama_produk': product['nama_produk'],
                                      'jumlah': 1,
                                      'harga': product['harga'],
                                      'subtotal': product['harga'],
                                      'stok': product['stok'],
                                    });
                                  });
                                },
                                child: const Text('Tambah'),
                              ),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    const Text(
                      'Keranjang Belanja:',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return Card(
                          elevation: 5,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text(item['nama_produk']),
                            subtitle: Text(
                                'Qty: ${item['jumlah']} | Subtotal: Rp. ${item['subtotal']}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove),
                                  onPressed: () =>
                                      _updateCartQuantity(index, -1),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add),
                                  onPressed: () =>
                                      _updateCartQuantity(index, 1),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    if (!isPaymentPage)
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 255, 183, 247),
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize:
                              const Size(200, 50),
                        ),
                        onPressed: _submitTransaction,
                        child: const Text(
                          'Proses Pembayaran',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    if (isPaymentPage)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Ringkasan Pembayaran:',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cart.length,
                            itemBuilder: (context, index) {
                              final item = cart[index];
                              return ListTile(
                                title: Text(item['nama_produk']),
                                subtitle: Text(
                                    'Qty: ${item['jumlah']} | Subtotal: Rp. ${item['subtotal']}'),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Total Pembayaran: Rp. ${cart.fold(0.0, (sum, item) => sum + item['subtotal'])}',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 183, 247),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              minimumSize:
                                  const Size(200, 50),
                            ),
                            onPressed: _completePayment,
                            child: const Text('Selesaikan Pembayaran'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}