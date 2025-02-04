import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SalesHistoryPage extends StatefulWidget {
  @override
  _SalesHistoryPageState createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  List<Map<String, dynamic>> filteredTransactions = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    final response = await supabase.from('penjualan').select();
    
    print("Response dari Supabase: $response"); // Debugging

    setState(() {
      transactions = List<Map<String, dynamic>>.from(response);
      filteredTransactions = transactions; // Set daftar transaksi awal
    });
  }

  void _filterTransactions(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredTransactions = transactions;
      } else {
        filteredTransactions = transactions.where((transaction) {
          if (transaction['tanggal_penjualan'] != null) {
            DateTime dateTime = DateTime.parse(transaction['tanggal_penjualan']);
            String formattedDate = '${dateTime.day}-${dateTime.month}-${dateTime.year}';
            return formattedDate.contains(query);
          }
          return false;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xFFd500f9),
        title: Text('History Penjualan'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchField(),
            Expanded(
              child: ListView.builder(
                itemCount: filteredTransactions.length,
                itemBuilder: (context, index) {
                  final transaction = filteredTransactions[index];

                  // Mengambil dan memformat tanggal transaksi (tanpa jam dan menit)
                  String formattedDate = "Tanggal Tidak Diketahui";
                  if (transaction['tanggal_penjualan'] != null) {
                    DateTime dateTime = DateTime.parse(transaction['tanggal_penjualan']);
                    formattedDate = '${dateTime.day}-${dateTime.month}-${dateTime.year}';
                  }

                  return Card(
                    elevation: 8,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      leading: Icon(Icons.shopping_cart, color: Color(0xFFd500f9)),
                      title: Text(
                        'Total: Rp. ${transaction['total_harga']}',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Tanggal: $formattedDate'), // Hanya menampilkan tanggal
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          labelText: 'Cari berdasarkan tanggal (dd-mm-yyyy)...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Color(0xfff2f2f3),
        ),
        onChanged: (query) {
          _filterTransactions(query);
        },
      ),
    );
  }
}
