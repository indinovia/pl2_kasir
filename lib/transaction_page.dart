import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({Key? key}) : super(key: key);

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

        // Update stock directly in the products list
        setState(() {
          final productIndex =
              products.indexWhere((p) => p['produk_id'] == item['produk_id']);
          if (productIndex != -1) {
            products[productIndex]['stok'] -= item['jumlah'];
          }
        });

        await supabase.from('produk').update({
          'stok': item['stok'] - item['jumlah'],
        }).eq('produk_id', item['produk_id']);
      }

      setState(() {
        cart.clear();
        selectedCustomer = null;
      });

      _showError('Transaction successfully recorded!');
    } catch (e) {
      _showError('Failed to submit transaction: $e');
    }
  }

  void _addToCart(Map<String, dynamic> product) {
    final TextEditingController quantityController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add ${product['nama_produk']} to Cart'),
          content: TextField(
            controller: quantityController,
            decoration: const InputDecoration(labelText: 'Quantity'),
            keyboardType: TextInputType.number,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final int quantity = int.tryParse(quantityController.text) ?? 0;
                if (quantity > 0 && quantity <= product['stok']) {
                  setState(() {
                    cart.add({
                      'produk_id': product['produk_id'],
                      'nama_produk': product['nama_produk'],
                      'jumlah': quantity,
                      'subtotal': product['harga'] * quantity,
                      'stok': product['stok'],
                    });
                  });
                  Navigator.pop(context);
                } else {
                  _showError('Invalid quantity');
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dropdown Pilihan Pelanggan
                    DropdownButton<Map<String, dynamic>>(
                      value: selectedCustomer,
                      hint: const Text('Select Customer'),
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

                    // Daftar Produk
                    const Text('Products:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product['nama_produk']),
                          subtitle: Text(
                              'Stock: ${product['stok']} | Price: Rp. ${product['harga']}'),
                          trailing: ElevatedButton(
                            onPressed: () => _addToCart(product),
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Keranjang Belanja
                    const Text('Cart:',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    cart.isEmpty
                        ? const Text('No items in cart.')
                        : ListView.builder(
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

                    // Tombol Submit Transaksi
                    ElevatedButton(
                      onPressed: _submitTransaction,
                      child: const Text('Submit Transaction'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
