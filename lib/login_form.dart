import 'package:flutter/material.dart'; // Mengimpor paket material dari Flutter untuk menggunakan widget dan komponen UI dasar.
import 'package:supabase_flutter/supabase_flutter.dart'; // Mengimpor paket Supabase untuk melakukan interaksi dengan backend menggunakan Supabase.
import 'home_page.dart'; // Mengimpor halaman home_page.dart, yang berisi halaman utama setelah login berhasil.

class LoginPage extends StatefulWidget { // Membuat kelas LoginPage yang merupakan StatefulWidget.
  const LoginPage({Key? key}) : super(key: key); // Konstruktor untuk LoginPage, tidak memiliki parameter tambahan.

  @override
  _LoginPageState createState() => _LoginPageState(); // Mengembalikan objek state untuk LoginPage.
}

class _LoginPageState extends State<LoginPage> { // Kelas yang mengelola status login halaman.
  final _usernameController = TextEditingController(); // Controller untuk mengontrol input teks di kolom username.
  final _passwordController = TextEditingController(); // Controller untuk mengontrol input teks di kolom password.
  bool _isObscured = true; // Variabel untuk mengatur visibilitas password (disembunyikan atau tidak).

  final _formKey = GlobalKey<FormState>(); // Key untuk form validation, agar dapat mengakses status form.

  // Fungsi validasi username
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) { // Cek apakah username kosong.
      return 'Username tidak boleh kosong'; // Jika kosong, tampilkan pesan error.
    }
    if (value.length < 4) { // Cek apakah panjang username kurang dari 4 karakter.
      return 'Username minimal 4 karakter'; // Jika kurang, tampilkan pesan error.
    }
    return null; // Jika valid, return null (tidak ada error).
  }

  // Fungsi validasi password
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) { // Cek apakah password kosong.
      return 'Password tidak boleh kosong'; // Jika kosong, tampilkan pesan error.
    }
    if (value.length < 6) { // Cek apakah panjang password kurang dari 6 karakter.
      return 'Password minimal 6 karakter'; // Jika kurang, tampilkan pesan error.
    }
    return null; // Jika valid, return null (tidak ada error).
  }

  // Fungsi untuk menangani proses login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) { // Cek validasi form terlebih dahulu.
      return; // Jika form tidak valid, hentikan eksekusi.
    }

    final username = _usernameController.text.trim(); // Ambil teks username dari controller dan hapus spasi di awal/akhir.
    final password = _passwordController.text.trim(); // Ambil teks password dari controller dan hapus spasi di awal/akhir.

    try {
      // Mengirimkan permintaan ke database Supabase untuk memeriksa apakah username dan password cocok.
      final response = await Supabase.instance.client
          .from('user') // Mengakses tabel 'user' di Supabase.
          .select('id, username, role') // Memilih kolom 'id', 'username', dan 'role'.
          .eq('username', username) // Mencocokkan username yang dimasukkan.
          .eq('password', password) // Mencocokkan password yang dimasukkan.
          .maybeSingle(); // Mengambil satu data jika ada, atau null jika tidak ada.

      if (response != null) { // Jika data ditemukan.
        final userId = response['id'] as int; // Ambil id pengguna.
        final userName = response['username'] as String; // Ambil username pengguna.
        final userRole = response['role'] as String; // Ambil role pengguna.

        ScaffoldMessenger.of(context).showSnackBar( // Menampilkan snackbar (pesan sementara di bagian bawah layar).
          SnackBar(content: Text('Selamat datang, $userName!')), // Pesan selamat datang.
        );

        // Navigasi ke halaman home setelah login berhasil.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: userId,
              username: userName,
              role: userRole,
            ),
          ),
        );
      } else { // Jika login gagal.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Login gagal. Username atau password salah.')),
        );
      }
    } catch (e) { // Menangkap error jika terjadi kesalahan saat berkomunikasi dengan Supabase.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')), // Menampilkan pesan error.
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( // Scaffold untuk menyediakan struktur dasar layout aplikasi.
      backgroundColor: Color(0xffffffff), // Memberikan warna latar belakang putih untuk tampilan login.
      body: Form( // Form untuk menampung dan memvalidasi input pengguna.
        key: _formKey, // Menggunakan key untuk validasi form.
        child: Padding(
          padding: EdgeInsets.all(20), // Memberikan jarak di sekitar semua elemen dalam body.
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Menyusun elemen secara vertikal di tengah.
            crossAxisAlignment: CrossAxisAlignment.center, // Menyusun elemen secara horisontal di tengah.
            mainAxisSize: MainAxisSize.max, // Membuat kolom mengisi ruang secara maksimal.
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(0, 0, 0, 30), // Memberikan padding bawah sebesar 30.
                child: Text(
                  "Login", // Teks judul Login.
                  textAlign: TextAlign.start, // Menyusun teks di kiri.
                  style: TextStyle(
                    fontWeight: FontWeight.w600, // Menetapkan gaya teks menjadi tebal.
                    fontSize: 25, // Ukuran font.
                    color: Color(0xff000000), // Warna teks hitam.
                  ),
                ),
              ),
              // Kolom input untuk username
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: TextFormField(
                  controller: _usernameController, // Menghubungkan controller dengan field.
                  validator: _validateUsername, // Menambahkan validasi username.
                  decoration: InputDecoration(
                    labelText: "Username", // Label di dalam kolom input.
                    hintText: "Masukkan username", // Teks petunjuk di dalam kolom input.
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)), // Membuat border input dengan sudut melengkung.
                    filled: true, // Mengisi kolom input dengan warna.
                    fillColor: Color(0xfff2f2f3), // Warna latar belakang input.
                    prefixIcon: Icon(Icons.person, color: Color(0xff212435)), // Ikon di kiri kolom input.
                  ),
                ),
              ),
              // Kolom input untuk password
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: TextFormField(
                  controller: _passwordController, // Menghubungkan controller dengan field.
                  validator: _validatePassword, // Menambahkan validasi password.
                  obscureText: _isObscured, // Menyembunyikan atau menampilkan password.
                  decoration: InputDecoration(
                    labelText: "Password", // Label di dalam kolom input.
                    hintText: "Masukkan password", // Teks petunjuk di dalam kolom input.
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)), // Membuat border input dengan sudut melengkung.
                    filled: true, // Mengisi kolom input dengan warna.
                    fillColor: Color(0xfff2f2f3), // Warna latar belakang input.
                    prefixIcon: Icon(Icons.lock, color: Color(0xff212435)), // Ikon di kiri kolom input.
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility, // Ikon untuk menyembunyikan/memunculkan password.
                        color: Color(0xff212435),
                      ),
                      onPressed: () { // Ketika ikon diklik, toggle visibilitas password.
                        setState(() {
                          _isObscured = !_isObscured;
                        });
                      },
                    ),
                  ),
                ),
              ),
              // Tombol Login
              Padding(
                padding: EdgeInsets.fromLTRB(0, 20, 0, 0),
                child: MaterialButton(
                  onPressed: _login, // Menjalankan fungsi login ketika tombol ditekan.
                  color: const Color.fromARGB(255, 255, 183, 247), // Warna tombol.
                  elevation: 0, // Menetapkan elevation (bayangan tombol) ke 0.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0), // Membuat sudut tombol melengkung.
                    side: BorderSide(color: Color(0xff808080), width: 1), // Border tombol dengan warna abu-abu.
                  ),
                  padding: EdgeInsets.all(16), // Memberikan padding pada tombol.
                  child: Text(
                    "Login", // Teks di tombol login.
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500), // Gaya teks tombol.
                  ),
                  textColor: Color(0xffffffff), // Warna teks tombol putih.
                  height: 40, // Tinggi tombol.
                  minWidth: 140, // Lebar tombol minimal.
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
