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

        await supabase.from('produk').update({
          'stok': item['stok'] - item['jumlah'],
        }).eq('produk_id', item['produk_id']);
      }

      setState(() {
        cart.clear();
        selectedCustomer = null;
      });

      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SalesHistoryPage()),
      );
    } catch (e) {
      _showError('Failed to submit transaction: $e');
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
        title: const Text('Transactions'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 16),
                  const Text('Products:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ListTile(
                          title: Text(product['nama_produk']),
                          subtitle: Text(
                              'Stock: ${product['stok']} | Price: Rp. ${product['harga']}'),
                          trailing: ElevatedButton(
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
                            child: const Text('Add'),
                          ),
                        );
                      },
                    ),
                  ),
                  const Text('Cart:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cart.length,
                      itemBuilder: (context, index) {
                        final item = cart[index];
                        return ListTile(
                          title: Text(item['nama_produk']),
                          subtitle: Text(
                              'Qty: ${item['jumlah']} | Subtotal: Rp. ${item['subtotal']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: () => _updateCartQuantity(index, -1),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () => _updateCartQuantity(index, 1),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _submitTransaction,
                    child: const Text('Checkout'),
                  ),
                ],
              ),
            ),
    );
  }
}

class SalesHistoryPage extends StatefulWidget {
  @override
  _SalesHistoryPageState createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final response = await supabase.from('penjualan').select();
    setState(() {
      transactions = List<Map<String, dynamic>>.from(response);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales History')),
      body: ListView.builder(
        itemCount: transactions.length,
        itemBuilder: (context, index) {
          final transaction = transactions[index];
          return ListTile(
            title: Text('Total: Rp. ${transaction['total_harga']}'),
            subtitle: Text('Date: ${transaction['tanggal_penjualan']}'),
          );
        },
      ),
    );
  }
}
