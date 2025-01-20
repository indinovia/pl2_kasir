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
  List<Map<String, dynamic>> transactions = []; // Menyimpan riwayat transaksi
  Map<String, dynamic>? selectedCustomer;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
    _fetchTransactions(); // Ambil transaksi yang sudah ada
  }

  // Ambil data produk, pelanggan, dan transaksi
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

  // Ambil riwayat transaksi dari Supabase
  Future<void> _fetchTransactions() async {
    try {
      final transactionResponse = await supabase.from('penjualan').select().order('tanggal_penjualan', ascending: false);
      setState(() {
        transactions = List<Map<String, dynamic>>.from(transactionResponse);
      });
    } catch (e) {
      _showError('Failed to fetch transactions: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // Kirim transaksi ke Supabase
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

        await supabase.from('produk').update({
          'stok': item['stok'] - item['jumlah'],
        }).eq('produk_id', item['produk_id']);
      }

      setState(() {
        cart.clear();
        selectedCustomer = null;
      });

      _fetchTransactions(); // Update tabel transaksi setelah berhasil
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
        title: const Text('Transaction Page'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
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
                  const SizedBox(height: 8),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: ListView.builder(
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          return ListTile(
                            title: Text(product['nama_produk']),
                            subtitle: Text('Price: ${product['harga']}, Stock: ${product['stok']}'),
                            trailing: ElevatedButton(
                              onPressed: () => _addToCart(product),
                              child: const Text('Add to Cart'),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Divider(),
                  Text('Cart:', style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Product')),
                          DataColumn(label: Text('Quantity')),
                          DataColumn(label: Text('Subtotal')),
                        ],
                        rows: cart.map((item) {
                          return DataRow(cells: [
                            DataCell(Text(item['nama_produk'])),
                            DataCell(Text(item['jumlah'].toString())),
                            DataCell(Text('Rp. ${item['subtotal']}')),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitTransaction,
                    child: const Text('Submit Transaction'),
                  ),
                  const SizedBox(height: 16),
                  Text('Transaction History:', style: Theme.of(context).textTheme.titleLarge),
                  Expanded(
                    child: Card(
                      elevation: 4,
                      child: ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction = transactions[index];
                          return ListTile(
                            title: Text('Transaction #${transaction['penjualan_id']}'),
                            subtitle: Text('Date: ${transaction['tanggal_penjualan']}, Total: Rp. ${transaction['total_harga']}'),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
