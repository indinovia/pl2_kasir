  import 'package:flutter/material.dart';
  import 'package:supabase_flutter/supabase_flutter.dart';

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
        appBar: AppBar(
          backgroundColor:const Color.fromARGB(0, 255, 138, 241),
          title: const Text('History'),
        ),
        body: ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            return Card(
              elevation: 5,
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: ListTile(
                title: Text('Total: Rp. ${transaction['total_harga']}'),
                subtitle: Text('Date: ${transaction['tanggal_penjualan']}'),
              ),
            );
          },
        ),
      );
    }
  }
