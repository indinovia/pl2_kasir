import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegistrasiPage extends StatefulWidget {
  const RegistrasiPage({Key? key}) : super(key: key);

  @override
  _RegistrasiPageState createState() => _RegistrasiPageState();
}

class _RegistrasiPageState extends State<RegistrasiPage> {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final response = await _supabase.from('user').select();
      setState(() {
        _users = List<Map<String, dynamic>>.from(response as List<dynamic>);
        isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching users: $error');
    }
  }

  Future<void> _addUser(String username, String password, String role) async {
    try {
      final response = await _supabase.from('user').insert([
        {
          'username': username,
          'password': password,
          'role': role,
        }
      ]).select();

      if (response.isNotEmpty) {
        debugPrint('User berhasil ditambahkan: $response');
        setState(() {
          _users.add(response.first);
        });

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User berhasil ditambahkan!')));
      } else {
        throw Exception('Gagal menambahkan user');
      }
    } catch (error) {
      debugPrint('Error saat menambahkan user: $error');
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambahkan user: $error')));
    }
  }

  Future<void> _editUser(
      int id, String username, String password, String role) async {
    try {
      await _supabase.from('user').update({
        'username': username,
        'password': password,
        'role': role,
      }).eq('id', id);
      _fetchUsers();
    } catch (error) {
      debugPrint('Error editing user: $error');
    }
  }

  Future<void> _deleteUser(int id) async {
    try {
      await _supabase.from('user').delete().eq('id', id);
      _fetchUsers();
    } catch (error) {
      debugPrint('Error deleting user: $error');
    }
  }

  void _showDeleteConfirmation(int id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Penghapusan'),
        content: const Text('Apakah Anda yakin ingin menghapus user ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Batal'),
            style: TextButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 81, 177, 255),
              foregroundColor: Colors.white,
            ),
          ),
          TextButton(
            onPressed: () {
              _deleteUser(id);
              Navigator.of(context).pop();
            },
            child: const Text('Hapus'),
            style: TextButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showUserDialog({Map<String, dynamic>? user}) {
    final TextEditingController usernameController = TextEditingController(
      text: user != null ? user['username'] : '',
    );
    final TextEditingController passwordController = TextEditingController(
      text: user != null ? user['password'] : '',
    );

    String? selectedRole = user != null ? user['role'] : null;
    final _formKey = GlobalKey<FormState>();
    bool obscureText = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(user == null ? 'Tambah User' : 'Edit User'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username'),
                      validator: (value) =>
                          value!.isEmpty ? 'Username tidak boleh kosong' : null,
                    ),
                    TextFormField(
                      controller: passwordController,
                      obscureText: obscureText,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureText
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              obscureText = !obscureText;
                            });
                          },
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Password tidak boleh kosong' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: selectedRole,
                      decoration: const InputDecoration(labelText: 'Role'),
                      items: const [
                        DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'Petugas', child: Text('Petugas')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedRole = value;
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Role tidak boleh kosong' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Batal'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 81, 177, 255),
                    foregroundColor: Colors.white,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      if (user == null) {
                        _addUser(usernameController.text,
                            passwordController.text, selectedRole!);
                      } else {
                        _editUser(user['id'], usernameController.text,
                            passwordController.text, selectedRole!);
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(user == null ? 'Tambah' : 'Simpan'),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 255, 183, 247),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Registrasi User',
          style: TextStyle(color: Color.fromARGB(255, 0, 0, 0)),
        ),
        backgroundColor: const Color.fromARGB(0, 255, 255, 255),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                    title: Text(user['username'],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(user['role']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                          onPressed: () => _showUserDialog(user: user),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                          onPressed: () => _showDeleteConfirmation(user['id']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showUserDialog(),
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
        backgroundColor: const Color.fromARGB(255, 255, 183, 247),
      ),
    );
  }
}
