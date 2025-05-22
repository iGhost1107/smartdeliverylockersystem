// import 'package:flutter/material.dart';
//
//
// class SettingPage extends StatelessWidget {
//   const SettingPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {return Scaffold(
//     body: Center(
//       child: Text("Setting Page"),
//     ),
//   );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../LoginUI/login_page.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: const Center(
        child: Text("Setting Page"),
      ),
    );
  }
}
