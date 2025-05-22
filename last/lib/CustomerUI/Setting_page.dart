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

// import 'package:flutter/material.dart';
//
// class SettingPage extends StatefulWidget {
//   final String customerPhone;
//   const SettingPage({Key? key, required this.customerPhone}) : super(key: key);
//
//   @override
//   State<SettingPage> createState() => _SettingPageState();
// }
//
// class _SettingPageState extends State<SettingPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Center(
//       child: Text('Setting - ${widget.customerPhone}'),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../LoginUI/login_page.dart';

class SettingPage extends StatefulWidget {
  final String customerPhone;
  const SettingPage({Key? key, required this.customerPhone}) : super(key: key);

  @override
  State<SettingPage> createState() => _SettingPageState();
}

class _SettingPageState extends State<SettingPage> {
  void _signOut() async {
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
            onPressed: _signOut,
          ),
        ],
      ),
      body: Center(
        child: Text('Setting - ${widget.customerPhone}'),
      ),
    );
  }
}


