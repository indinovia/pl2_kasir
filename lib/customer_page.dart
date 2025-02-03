import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CustomerPage extends StatefulWidget {
  final VoidCallback onCustomerUpdated;

  const CustomerPage({Key? key, required this.onCustomerUpdated})
      : super(key: key);

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
      String nama, String alamat, String nomorTelepon) async {
    try {
      await supabase.from('pelanggan').insert({
        'nama_pelanggan': nama,
        'alamat': alamat,
        'nomor_telepon': nomorTelepon,
      });
      _fetchCustomers();
      widget.onCustomerUpdated(); // Panggil callback
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
      }).eq('pelanggan_id', id);
      _fetchCustomers();
      widget.onCustomerUpdated(); // Panggil callback
    } catch (e) {
      _showError('Failed to update customer: $e');
    }
  }

  Future<void> _confirmDeleteCustomer(int id) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi'),
          content:
              const Text('Apakah Anda yakin ingin menghapus pelanggan ini?'),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, false), // Tidak jadi hapus
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Lanjutkan hapus
              child: const Text('Ya'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      try {
        await supabase.from('pelanggan').delete().eq('pelanggan_id', id);
        _fetchCustomers();
        widget.onCustomerUpdated(); // Panggil callback
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pelanggan berhasil dihapus')),
        );
      } catch (e) {
        _showError('Gagal menghapus pelanggan: $e');
      }
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
                    DataColumn(label: Text('No.')),
                    DataColumn(label: Text('Nama')),
                    DataColumn(label: Text('Alamat')),
                    DataColumn(label: Text('Nomor Telepon')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: customers.asMap().entries.map((entry) {
                    final index = entry.key + 1;
                    final customer = entry.value;
                    return DataRow(cells: [
                      DataCell(Text(index.toString())),
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
                            onPressed: () => _confirmDeleteCustomer(
                                customer['pelanggan_id']),
                          ),
                        ],
                      )),
                    ]);
                  }).toList(),
                ),
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
        backgroundColor: const Color.fromARGB(255, 255, 178, 240),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCustomerDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController namaController = TextEditingController();
    final TextEditingController alamatController = TextEditingController();
    final TextEditingController nomorTeleponController =
        TextEditingController();
    final TextEditingController usernameController = TextEditingController();
    final TextEditingController passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Customer'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: namaController,
                    decoration: const InputDecoration(labelText: 'Nama'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: alamatController,
                    decoration: const InputDecoration(labelText: 'Alamat'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Alamat tidak boleh kosong';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: nomorTeleponController,
                    decoration:
                        const InputDecoration(labelText: 'Nomor Telepon'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nomor telepon tidak boleh kosong';
                      }
                      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                        return 'Nomor telepon harus berupa angka';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: usernameController,
                    decoration: const InputDecoration(labelText: 'Username'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username tidak boleh kosong';
                      }
                      if (value.length < 4) {
                        return 'Username harus memiliki minimal 4 karakter';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true, // Menyembunyikan teks input
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password tidak boleh kosong';
                      }
                      if (value.length < 6) {
                        return 'Password harus memiliki minimal 6 karakter';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  // Validasi berhasil
                  _addCustomer(
                    namaController.text,
                    alamatController.text,
                    nomorTeleponController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  void _editCustomerDialog(Map<String, dynamic> customer) {
    final _formKey = GlobalKey<FormState>();
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
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: alamatController,
                  decoration: const InputDecoration(labelText: 'Alamat'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Alamat tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: nomorTeleponController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nomor telepon tidak boleh kosong';
                    }
                    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
                      return 'Nomor telepon harus berupa angka';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _updateCustomer(
                    customer['pelanggan_id'],
                    namaController.text,
                    alamatController.text,
                    nomorTeleponController.text,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}
