import 'package:flutter/material.dart';
import 'package:pl2_kasir/customer_page.dart';
import 'package:pl2_kasir/transaction_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_form.dart'; // Import halaman login

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required int userId, required String username})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> products = [];
  bool isLoading = true;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }  

  Future<void> _fetchProducts() async {
    try {
      final SupabaseQueryBuilder query = supabase.from('produk');
      final List<dynamic> response = await query.select();
      setState(() {
        products = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  Future<void> _addProduct(String namaProduk, double harga, int stok) async {
    try {
      await supabase.from('produk').insert({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      });
      _fetchProducts();
    } catch (e) {
      _showError('Gagal menambahkan produk: $e');
    }
  }

  Future<void> _updateProduct(
      int id, String namaProduk, double harga, int stok) async {
    try {
      await supabase.from('produk').update({
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      }).eq('produk_id', id);

      await _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _deleteProduct(int id) async {
    try {
      await supabase.from('produk').delete().eq('produk_id', id);
      await _fetchProducts();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  Future<void> _confirmDeleteProduct(int id) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus produk ini?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog
              },
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Tutup dialog
                await _deleteProduct(id); // Hapus produk jika dikonfirmasi
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('Iya'),
            ),
          ],
        );
      },
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Widget _buildHomePage() {
    return Stack(
      children: [
        isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : products.isEmpty
                ? const Center(
                    child: Text(
                      'No products found!',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: MediaQuery.of(context).size.width > 600
                          ? 5
                          : 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                product['nama_produk'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Rp${product['harga']}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Stok: ${product['stok']}'),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () {
                                      _editProductDialog(product);
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    onPressed: () {
                                      _confirmDeleteProduct(
                                          product['produk_id']);
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 255, 178, 240),
            onPressed: _addProductDialog,
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  void _addProductDialog() {
    final TextEditingController namaProdukController = TextEditingController();
    final TextEditingController hargaController = TextEditingController();
    final TextEditingController stokController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Produk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaProdukController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final String namaProduk = namaProdukController.text;
                final double harga =
                    double.tryParse(hargaController.text) ?? 0.0;
                final int stok = int.tryParse(stokController.text) ?? 0;

                if (namaProduk.isNotEmpty && harga > 0 && stok >= 0) {
                  _addProduct(namaProduk, harga, stok);
                  Navigator.pop(context);
                } else {
                  _showError('Mohon isi data dengan benar.');
                }
              },
              child: const Text('Tambah Produk'),
            ),
          ],
        );
      },
    );
  }

  void _editProductDialog(Map<String, dynamic> product) {
    final TextEditingController namaProdukController =
        TextEditingController(text: product['nama_produk']);
    final TextEditingController hargaController =
        TextEditingController(text: product['harga'].toString());
    final TextEditingController stokController =
        TextEditingController(text: product['stok'].toString());

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Produk'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaProdukController,
                decoration: const InputDecoration(labelText: 'Nama Produk'),
              ),
              TextField(
                controller: hargaController,
                decoration: const InputDecoration(labelText: 'Harga'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: stokController,
                decoration: const InputDecoration(labelText: 'Stok'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final String namaProduk = namaProdukController.text;
                final double harga = double.tryParse(hargaController.text) ?? 0.0;
                final int stok = int.tryParse(stokController.text) ?? 0;

                if (namaProduk.isNotEmpty && harga > 0 && stok >= 0) {
                  _updateProduct(product['produk_id'], namaProduk, harga, stok);
                  Navigator.pop(context);
                } else {
                  _showError('Mohon isi data dengan benar.');
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCustomerPage() {
    return CustomerPage(onCustomerUpdated: () {});
  }

  Widget _buildTransactionPage() {
    return TransactionPage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Kasir",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor: const Color.fromARGB(255, 148, 46, 136),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: () async {
              await supabase.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _currentIndex == 0
          ? _buildHomePage()
          : _currentIndex == 1
              ? _buildCustomerPage()
              : _buildTransactionPage(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;

            // Refresh the selected page
            if (_currentIndex == 0) {
              _fetchProducts(); // Refresh products when Home is selected
            }
          });
        },
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person), 
            label: 'Pelanggan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Transaksi',
          ),
        ],
      ),
    );
  }
}
