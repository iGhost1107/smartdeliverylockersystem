import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'customer'; // Mặc định là customer
  int _age = 18; // Tuổi mặc định

  Future<void> register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty || password.isEmpty || phone.isEmpty || name.isEmpty) {
      _showMessage('Please insert all sections');
      return;
    }

    if (!email.contains('@') || !email.contains('.')) {
      _showMessage('Invalid email');
      return;
    }

    if (password.length < 6) {
      _showMessage('Password must be 6 digits at least');
      return;
    }

    if (!RegExp(r'^[0-9]+$').hasMatch(phone) || phone.length < 9) {
      _showMessage('Invalid phone number');
      return;
    }

    try {
      // ✅ Kiểm tra số điện thoại đã tồn tại
      final phoneExists = await FirebaseFirestore.instance
          .collection('users')
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();

      if (phoneExists.docs.isNotEmpty) {
        _showMessage('This phone number is already registered');
        return;
      }

      // ✅ Đăng ký người dùng mới
      UserCredential userCredential =
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'email': email,
        'phone': phone,
        'role': _role,
        'otherInfo': {
          'name': name,
          'age': _age,
        }
      });

      _showMessage('Registered successfully!');
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      _showMessage('Failed registering: ${e.message}');
    } catch (e) {
      _showMessage('Unknown error: $e');
    }
  }


  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[300],
      appBar: AppBar(title: const Text('Register')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  "Create Account",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                ),
                const SizedBox(height: 20),
                _buildTextField(_emailController, 'Email'),
                const SizedBox(height: 20),
                _buildTextField(_passwordController, 'Password', isPassword: true),
                const SizedBox(height: 20),
                _buildTextField(_phoneController, 'Phone Number'),
                const SizedBox(height: 20),
                _buildTextField(_nameController, 'Full Name'),
                const SizedBox(height: 20),
                _buildAgeDropdown(),
                const SizedBox(height: 20),
                _buildRoleSelector(),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: register,
                  child: const Text('Register'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hintText, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[200],
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: TextField(
            controller: controller,
            obscureText: isPassword,
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: hintText,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgeDropdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: DropdownButtonFormField<int>(
        value: _age,
        items: List.generate(101, (index) => DropdownMenuItem(value: index, child: Text('$index'))),
        onChanged: (value) {
          setState(() {
            _age = value!;
          });
        },
        decoration: const InputDecoration(labelText: 'Age'),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: DropdownButtonFormField<String>(
        value: _role,
        items: ['customer', 'shipper']
            .map((role) => DropdownMenuItem(value: role, child: Text(role)))
            .toList(),
        onChanged: (value) {
          setState(() {
            _role = value!;
          });
        },
        decoration: const InputDecoration(labelText: 'Role'),
      ),
    );
  }
}
