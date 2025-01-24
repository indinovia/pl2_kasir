import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerPage extends StatefulWidget {
  const CustomerPage({Key? key}) : super(key: key);

  @override
  _CustomerPageState createState() => _CustomerPageState();
}

class _CustomerPageState extends State<CustomerPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> customers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await supabase.from('pelanggan').select();
      setState(() {
        customers = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      _showError('Failed to fetch customers: $e');
    }
  }

  Future<void> _addCustomer(
      int id, String nama, String alamat, String nomorTelepon) async {
    try {
      await supabase.from('pelanggan').insert({
        'pelanggan_id': id,
        'nama_pelanggan': nama,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      });
      _fetchCustomers();
    } catch (e) {
      _showError('Failed to add customer: $e');
    }
  }

  Future<void> _updateCustomer(
      int id, String nama, String alamat, String nomorTelepon) async {
    try {
      await supabase.from('pelanggan').update({
        'nama_pelanggan': nama,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      }).eq('pelanggan_id', id) ;
      _fetchCustomers();
    } catch (e) {
      _showError('Failed to update customer: $e');
    }
  }

  Future<void> _deleteCustomer(int id) async {
    try {
      await supabase.from('pelanggan').delete().eq('pelanggan_id', id);
      _fetchCustomers();
    } catch (e) {
      _showError('Failed to delete customer: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildCustomerTable() {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : customers.isEmpty
            ? const Center(child: Text('No customers found'))
            : SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('ID')),
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Alamat')),
                    DataColumn(label: Text('Nomor Telepon')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: customers.map((customer) {
                    return DataRow(cells: [
                      DataCell(Text(customer['pelanggan_id'].toString())),
                      DataCell(Text(customer['nama_pelanggan'])),
                      DataCell(Text(customer['alamat'])),
                      DataCell(Text(customer['nomor_telepon'])),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editCustomerDialog(customer),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteCustomer(customer['pelanggan_id']),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
              );
  }

  void _editCustomerDialog(Map<String, dynamic> customer) {
    final TextEditingController idController =
        TextEditingController(text: customer['pelanggan_id'].toString());
    final TextEditingController namaController =
        TextEditingController(text: customer['nama_pelanggan']);
    final TextEditingController alamatController =
        TextEditingController(text: customer['alamat']);
    final TextEditingController nomorTeleponController =
        TextEditingController(text: customer['nomor_telepon']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID Pelanggan'),
                keyboardType: TextInputType.number,
                enabled: false,
              ),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              TextField(
                controller: nomorTeleponController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateCustomer(
                  int.parse(idController.text),
                  namaController.text,
                  alamatController.text,
                  nomorTeleponController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Simpan'),
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
        title: const Text('Customers'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildCustomerTable(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addCustomerDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCustomerDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController namaController = TextEditingController();
    final TextEditingController alamatController = TextEditingController();
    final TextEditingController nomorTeleponController =
        TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idController,
                decoration: const InputDecoration(labelText: 'ID Pelanggan'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: namaController,
                decoration: const InputDecoration(labelText: 'Nama'),
              ),
              TextField(
                controller: alamatController,
                decoration: const InputDecoration(labelText: 'Alamat'),
              ),
              TextField(
                controller: nomorTeleponController,
                decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                keyboardType: TextInputType.phone,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                _addCustomer(
                  int.parse(idController.text),
                  namaController.text,
                  alamatController.text,
                  nomorTeleponController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }
}
