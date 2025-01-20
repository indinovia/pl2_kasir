import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_form.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://onajubbxgwyxxszegyhn.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9uYWp1YmJ4Z3d5eHhzemVneWhuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzYxMzIwODUsImV4cCI6MjA1MTcwODA4NX0.G2n2dlmLVR_AWQmKddqQtM0igcHA7X9VIVR3bqTWVpw',
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter CRUD App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: LoginPage(),
    );
  }
}
