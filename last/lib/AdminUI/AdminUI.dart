import 'package:flutter/material.dart';
import 'package:last/AdminUI/Home_page.dart';
import 'package:last/AdminUI/Locker_page.dart';
import 'package:last/AdminUI/Setting_page.dart';


class AdminUI extends StatefulWidget {
  AdminUI({super.key});
  @override
  State<AdminUI> createState() => _AdminUIState();
}

class _AdminUIState extends State<AdminUI> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final List _pages = [
    HomePage(),
    LockerPage(),
    SettingPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Smart Delivery Locker")),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _navigateBottomBar,
        items: [
          // home
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home'
          ),

          // locker
          BottomNavigationBarItem(
              icon: Icon(Icons.cabin),
              label: 'Locker'
          ),

          // profile
          BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Setting'
          ),
        ],
      ),
    );
  }
}
