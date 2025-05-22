import 'package:flutter/material.dart';
import 'package:last/ShipperUI/Locker_page.dart';
import 'package:last/ShipperUI/Home_page.dart';
import 'package:last/ShipperUI/Setting_page.dart';


class ShipperUI extends StatefulWidget {
  final String shipperPhone;
  const ShipperUI({Key? key, required this.shipperPhone}) : super(key: key);

  @override
  State<ShipperUI> createState() => _ShipperUIState();
}

class _ShipperUIState extends State<ShipperUI> {
  int _selectedIndex = 0;

  void _navigateBottomBar(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      HomePage(shipperPhone: widget.shipperPhone),
      LockerPage(shipperPhone: widget.shipperPhone),
      SettingPage(shipperPhone: widget.shipperPhone),
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
