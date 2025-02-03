import 'package:flutter/material.dart'; // Mengimpor paket material dari Flutter untuk menggunakan widget dan komponen UI dasar.
import 'package:supabase_flutter/supabase_flutter.dart'; // Mengimpor paket Supabase untuk melakukan interaksi dengan backend menggunakan Supabase.
import 'home_page.dart'; // Mengimpor halaman home_page.dart, yang berisi halaman utama setelah login berhasil.

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key})
      : super(
            key:
                key); // Konstruktor untuk LoginPage, tidak memiliki parameter tambahan.

  @override
  _LoginPageState createState() =>
      _LoginPageState(); // Mengembalikan objek state untuk LoginPage.
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController =
      TextEditingController(); // Controller untuk mengontrol input teks di kolom username.
  final _passwordController =
      TextEditingController(); // Controller untuk mengontrol input teks di kolom password.
  bool _isObscured =
      true; // Variabel untuk mengatur visibilitas password (disembunyikan atau tidak).

  final _formKey = GlobalKey<FormState>(); // Key untuk form validation.

  // Fungsi validasi username
  //gerbang logika or
  String? _validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username tidak boleh kosong';
    }
    if (value.length < 4) {
      return 'Username minimal 4 karakter';
    }
    return null;
  }

  // Fungsi validasi password
  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password tidak boleh kosong';
    }
    if (value.length < 6) {
      return 'Password minimal 6 karakter';
    }
    return null;
  }

  // Fungsi untuk menangani proses login
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final response = await Supabase.instance.client
          .from('user')
          .select('id, username, role')
          .eq('username', username)
          .eq('password', password)
          .maybeSingle();

      if (response != null) {
        final userId = response['id'] as int;
        final userName = response['username'] as String;
        final userRole = response['role'] as String;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Selamat datang, $userName!')),
        );

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
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Login gagal. Username atau password salah.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(
          0xffffffff), // Memberikan warna latar belakang putih untuk tampilan login.
      body: Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(
              20), // Memberikan jarak di sekitar semua elemen dalam body.
          child: Column(
            mainAxisAlignment: MainAxisAlignment
                .center, // Menyusun elemen secara vertikal di tengah.
            crossAxisAlignment: CrossAxisAlignment
                .center, // Menyusun elemen secara horisontal di tengah.
            mainAxisSize: MainAxisSize
                .max, // Membuat kolom mengisi ruang secara maksimal.
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    0, 0, 0, 30), // Memberikan padding bawah sebesar 30.
                child: Text(
                  "Login", // Teks judul Login.
                  textAlign: TextAlign.start, // Menyusun teks di kiri.
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w600, // Menetapkan gaya teks menjadi tebal.
                    fontSize: 25, // Ukuran font.
                    color: Color(0xff000000), // Warna teks hitam.
                  ),
                ),
              ),
              // Kolom input untuk username
              Padding(
                padding: EdgeInsets.symmetric(vertical: 0, horizontal: 20),
                child: TextFormField(
                  controller: _usernameController,
                  validator: _validateUsername, // Validasi username.
                  decoration: InputDecoration(
                    labelText: "Username",
                    hintText: "Masukkan username",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    filled: true,
                    fillColor: Color(0xfff2f2f3),
                    prefixIcon: Icon(Icons.person, color: Color(0xff212435)),
                  ),
                ),
              ),
              // Kolom input untuk password
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                child: TextFormField(
                  controller: _passwordController,
                  validator: _validatePassword, // Validasi password.
                  obscureText: _isObscured,
                  decoration: InputDecoration(
                    labelText: "Password",
                    hintText: "Masukkan password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10.0)),
                    filled: true,
                    fillColor: Color(0xfff2f2f3),
                    prefixIcon: Icon(Icons.lock, color: Color(0xff212435)),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscured ? Icons.visibility_off : Icons.visibility,
                        color: Color(0xff212435),
                      ),
                      onPressed: () {
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
                  onPressed: _login,
                  color: const Color.fromARGB(255, 255, 183, 247),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                    side: BorderSide(color: Color(0xff808080), width: 1),
                  ),
                  padding: EdgeInsets.all(16),
                  child: Text(
                    "Login",
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  textColor: Color(0xffffffff),
                  height: 40,
                  minWidth: 140,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
