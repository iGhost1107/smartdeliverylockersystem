import 'package:flutter/material.dart';
import 'package:last/CustomerUI/Home_page.dart';
import 'package:last/CustomerUI/Locker_page.dart';
import 'package:last/CustomerUI/Setting_page.dart';




class CustomerUI extends StatefulWidget {
  final String customerPhone;
  const CustomerUI({Key? key, required this.customerPhone}) : super(key: key);
  // CustomerUI({super.key});

  @override
  State<CustomerUI> createState() => _CustomerUIState();
}

class _CustomerUIState extends State<CustomerUI> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {

    final List<Widget> _pages = [
      HomePage(customerPhone: widget.customerPhone),
      LockerPage(customerPhone: widget.customerPhone),
      SettingPage(customerPhone: widget.customerPhone),
    ];

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








