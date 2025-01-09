import 'package:flutter/material.dart'; // Import paket Flutter untuk membuat UI aplikasi berbasis Material Design.
import 'package:supabase_flutter/supabase_flutter.dart'; 
// Import paket Supabase untuk menghubungkan aplikasi ke backend Supabase.

import 'login_form.dart'; 
// Import file "login_form.dart" yang kemungkinan berisi kode untuk halaman login.

Future<void> main() async { 
  // Fungsi utama aplikasi, dijalankan pertama kali saat aplikasi dibuka.
  await Supabase.initialize(
    url: 'https://onajubbxgwyxxszegyhn.supabase.co', 
    // Alamat URL proyek Supabase.
    anonKey: '...', 
    // Kunci anon untuk autentikasi ke Supabase.
  );
  runApp(MyApp()); 
  // Memulai aplikasi dengan widget utama bernama MyApp.
}

class MyApp extends StatelessWidget { 
  // Widget utama aplikasi, bersifat statis (tidak berubah saat aplikasi berjalan).
  @override
  Widget build(BuildContext context) { 
    // Fungsi untuk membangun UI dari widget ini.
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      // Menyembunyikan tulisan "Debug" di pojok kanan atas aplikasi.
      home: LoginPage(), 
      // Menampilkan halaman LoginPage sebagai layar utama aplikasi.
    );
  }
}
