import 'package:flutter/material.dart'; // Import paket Material Design untuk tampilan UI
import 'package:pl2_kasir/customer_page.dart'; // Import halaman pelanggan
import 'package:pl2_kasir/sales_history_page.dart';
import 'package:pl2_kasir/transaction_page.dart'; // Import halaman transaksi
import 'package:supabase_flutter/supabase_flutter.dart'; // Import Supabase untuk mengakses backend
import 'login_form.dart';
import 'registrasi.dart'; // Import halaman login

// HomeScreen adalah widget yang digunakan sebagai halaman utama
class HomeScreen extends StatefulWidget {
  final int userId;
  final String username;
  final String role;

  const HomeScreen(
      {Key? key,
      required this.userId,
      required this.username,
      required this.role})
      : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final SupabaseClient supabase =
      Supabase.instance.client; // Menyimpan instance Supabase
  List<Map<String, dynamic>> products = []; // Daftar produk
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true; // Status untuk menampilkan loading
  int _currentIndex = 0;
  String searchQuery = ''; // Variabel untuk menyimpan query pencarian
  
  List<Widget> get _pages {
    if (widget.role == 'Admin') {
      return [
        _buildHomePage(),
        _buildCustomerPage(),
        RegistrasiPage(),
      ];
    } else {
      return [
        _buildHomePage(),
        _buildTransactionPage(),
        SalesHistoryPage(),
      ];
    }
  }

  @override
  void initState() {
    super.initState(); // Ambil data pengguna saat halaman pertama kali dibuka
    _fetchProducts();
  }

  // Fungsi untuk mengambil data pengguna dari Supabase

  Future<void> _fetchProducts() async {
    try {
      final SupabaseQueryBuilder query = supabase.from('produk'); // Query ke tabel 'produk'
      final List<dynamic> response = await query.select(); // Ambil data produk
      setState(() {
        products = List<Map<String, dynamic>>.from(response); // Menyimpan data produk ke dalam list
        filteredProducts = products; // Inisialisasi daftar produk yang difilter
        isLoading = false; // Menandakan bahwa data sudah selesai diambil
      });
    } catch (e) {
      _showError('An error occurred: $e'); // Menampilkan error jika gagal mengambil data
    }
  }

    void _filterProducts(String query) {
    setState(() {
      searchQuery = query; // Simpan query pencarian
      filteredProducts = products.where((product) {
        final productName = product['nama_produk'].toLowerCase();
        return productName.contains(query.toLowerCase()); // Filter produk berdasarkan nama
      }).toList();
    });
  }


  // Fungsi untuk menambah produk baru ke database
  Future<void> _addProduct(String namaProduk, double harga, int stok) async {
    try {
      await supabase.from('produk').insert({
        // Menambah data ke tabel 'produk'
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      });
      _fetchProducts(); // Mengambil ulang data produk setelah menambah produk baru
    } catch (e) {
      _showError(
          'Gagal menambahkan produk: $e'); // Menampilkan error jika gagal menambah produk
    }
  }

  // Fungsi untuk memperbarui produk yang sudah ada
  Future<void> _updateProduct(
      int id, String namaProduk, double harga, int stok) async {
    try {
      await supabase.from('produk').update({
        // Memperbarui data produk di database
        'nama_produk': namaProduk,
        'harga': harga,
        'stok': stok,
      }).eq('produk_id', id); // Menentukan produk berdasarkan ID

      await _fetchProducts(); // Mengambil ulang data produk
      ScaffoldMessenger.of(context).showSnackBar(
        // Menampilkan pesan sukses
        const SnackBar(content: Text('Produk berhasil diperbarui')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        // Menampilkan pesan error
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  // Fungsi untuk menghapus produk berdasarkan ID
  Future<void> _deleteProduct(int id) async {
    try {
      await supabase
          .from('produk')
          .delete()
          .eq('produk_id', id); // Menghapus produk berdasarkan ID
      await _fetchProducts(); // Mengambil ulang data produk
      ScaffoldMessenger.of(context).showSnackBar(
        // Menampilkan pesan sukses
        const SnackBar(content: Text('Produk berhasil dihapus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        // Menampilkan pesan error
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  // Fungsi untuk mengkonfirmasi penghapusan produk dengan dialog
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
                Navigator.pop(
                    context); // Menutup dialog jika tidak jadi menghapus
              },
              child: const Text('Tidak'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Menutup dialog
                await _deleteProduct(id); // Menghapus produk jika diiyakan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, // Warna merah untuk tombol hapus
              ),
              child: const Text('Iya'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan pesan error menggunakan SnackBar
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // Widget untuk halaman utama (Home) yang menampilkan daftar produk
  Widget _buildHomePage() {
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterProducts, // Panggil fungsi filter saat input berubah
                decoration: InputDecoration(
                  labelText: 'Cari Produk',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) // Menampilkan indikator loading
                  : filteredProducts.isEmpty
                      ? const Center(
                          child: Text(
                            'No products found!', // Pesan jika tidak ada produk
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        )
                      : GridView.builder(
                          // Menampilkan produk dalam grid
                          padding: const EdgeInsets.all(16),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 5 : 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1.0,
                          ),
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index]; // Ambil produk berdasarkan index
                            return Card(
                              elevation: 4, // Elevasi efek bayangan
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10), // Sudut card melengkung
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      product['nama_produk'] ?? 'Unknown', // Menampilkan nama produk
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Rp${product['harga']}', // Menampilkan harga produk
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green, // Warna harga hijau
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Stok: ${product['stok']}'), // Menampilkan stok produk
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit), // Tombol edit produk
                                          onPressed: () {
                                            _editProductDialog(product); // Panggil dialog edit produk
                                          },
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete), // Tombol hapus produk
                                          onPressed: () {
                                            _confirmDeleteProduct(product['produk_id']); // Konfirmasi hapus produk
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
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            backgroundColor: const Color.fromARGB(255, 255, 178, 240), // Warna tombol tambah produk
            onPressed: _addProductDialog, // Panggil dialog tambah produk
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }



  // Fungsi untuk menampilkan dialog tambah produk
  void _addProductDialog() {
    final _formKey = GlobalKey<FormState>();
    final TextEditingController namaProdukController = TextEditingController();
    final TextEditingController hargaController = TextEditingController();
    final TextEditingController stokController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Produk'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaProdukController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    final double? harga = double.tryParse(value);
                    if (harga == null || harga <= 0) {
                      return 'Masukkan harga yang valid (angka)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: stokController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok tidak boleh kosong';
                    }
                    final int? stok = int.tryParse(value);
                    if (stok == null || stok < 0) {
                      return 'Masukkan stok yang valid ';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog jika batal
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String namaProduk = namaProdukController.text;
                  final double harga = double.parse(hargaController.text);
                  final int stok = int.parse(stokController.text);

                  _addProduct(namaProduk, harga, stok); // Tambah produk baru
                  Navigator.pop(context); // Tutup dialog setelah sukses
                }
              },
              child: const Text('Tambah Produk'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan dialog edit produk
  void _editProductDialog(Map<String, dynamic> product) {
    final _formKey = GlobalKey<FormState>();
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
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: namaProdukController,
                  decoration: const InputDecoration(labelText: 'Nama Produk'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Nama produk tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: hargaController,
                  decoration: const InputDecoration(labelText: 'Harga'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Harga tidak boleh kosong';
                    }
                    final double? harga = double.tryParse(value);
                    if (harga == null || harga <= 0) {
                      return 'Masukkan harga yang valid (angka)';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: stokController,
                  decoration: const InputDecoration(labelText: 'Stok'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Stok tidak boleh kosong';
                    }
                    final int? stok = int.tryParse(value);
                    if (stok == null || stok < 0) {
                      return 'Masukkan stok yang valid';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Tutup dialog jika batal
              },
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  final String namaProduk = namaProdukController.text;
                  final double harga = double.parse(hargaController.text);
                  final int stok = int.parse(stokController.text);

                  _updateProduct(product['produk_id'], namaProduk, harga,
                      stok); // Update produk
                  Navigator.pop(context); // Tutup dialog setelah sukses
                }
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );
  }

  // Fungsi untuk menampilkan halaman pelanggan
  Widget _buildCustomerPage() {
    return CustomerPage(onCustomerUpdated: () {}); // Halaman pelanggan
  }

  // Fungsi untuk menampilkan halaman transaksi
  Widget _buildTransactionPage() {
    return TransactionPage(userId: 1, username: 'JohnDoe');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Kasir - ${widget.role}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        foregroundColor: Colors.white,
        backgroundColor:
            const Color.fromARGB(255, 255, 183, 247), // Warna background AppBa
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;

            // Refresh halaman tertentu jika diperlukan
            if (_currentIndex == 0) {
              _fetchProducts(); // Refresh data produk pada tab Home
            } else if (_currentIndex == 1) {
              // Tambahkan refresh data untuk halaman lainnya jika dibutuhkan
            }
          });
        },
        items: widget.role == 'Admin'
            ? [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.people), label: "Data Pelanggan"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.admin_panel_settings),
                    label: "Data Petugas"),
              ]
            : [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
                BottomNavigationBarItem(
                    icon: Icon(Icons.shopping_cart), label: "Transaksi"),
                 BottomNavigationBarItem(
                  icon: Icon(Icons.history), label: "Riwayat Penjualan"),
              ],
      ),
    );
  }
}
