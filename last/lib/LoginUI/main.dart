import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // thêm dòng này
import 'login_page.dart';
import '../AdminUI/AdminUI.dart';
import '../Firebase/firebase_options.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Role Based App',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
      ),
      home: const LoginPage(),
      routes: {
        '/adminPage': (context) => AdminUI(),
        // '/customerPage': (context) => CustomerUI(),
        // '/shipperPage': (context) => ShipperUI(),
      },
    );
  }
}

