import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Map/OpenMap.dart';
import '../Firebase/firestore.dart';

class LockerPage extends StatefulWidget {
  final String shipperPhone;
  const LockerPage({super.key, required this.shipperPhone});

  @override
  State<LockerPage> createState() => _LockerPageState();
}

class _LockerPageState extends State<LockerPage> {
  List<String> _floors = [];
  String _searchQuery = "";
  final FireStoreService fireStoreService = FireStoreService();
  final TextEditingController customerPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFloorsFromLockers();
  }

  @override
  void dispose() {
    customerPhoneController.dispose();
    super.dispose();
  }

  Future<void> fetchFloorsFromLockers() async {
    final snapshot = await FirebaseFirestore.instance.collection('Lockers').get();
    final floors = snapshot.docs.map((doc) => doc['collection'] as String).toList();
    setState(() {
      _floors = floors;
    });
  }

  void _showAssignDialog(BuildContext context, String floor, String lockerId, String size) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Assign Locker $lockerId at $floor'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: customerPhoneController,
                decoration: const InputDecoration(
                  labelText: 'Customer Phone',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 10),
              Text('Package Size: $size', style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              customerPhoneController.clear();
              Navigator.of(context).pop();
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final phone = customerPhoneController.text.trim();
              if (phone.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please enter customer phone")),
                );
                return;
              }

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const AlertDialog(
                  content: Row(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 20),
                      Text("Processing..."),
                    ],
                  ),
                ),
              );

              final result = await fireStoreService.addPackage({
                'customerPhone': phone,
                'lockerLocation': floor,
                'size': size,
                'shipperPhone': widget.shipperPhone,
              });

              Navigator.of(context, rootNavigator: true).pop(); // Close loading

              if (result != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result)),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Package assigned successfully")),
                );
                customerPhoneController.clear();
                Navigator.pop(context); // Close dialog
              }
            },
            child: const Text('Assign'),
          ),
        ],
      ),
    );
  }

  Future<void> handleLockerTap(BuildContext context, String floor, String id, String size) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirm Open"),
        content: Text("Do you want to open locker $id at $floor?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection(floor)
                  .doc(id)
                  .update({'pendingCommand': true});
              Navigator.of(context).pop(true);
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Locker opened")),
    );

    _showAssignDialog(context, floor, id, size);
  }

  @override
  Widget build(BuildContext context) {
    final filteredFloors = _searchQuery.isEmpty
        ? _floors
        : _floors.where((floor) => floor.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Lockers Management")),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OpenstreetmapScreen(),
            ),
          );
        },
        child: const Icon(Icons.map),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search by location...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.trim();
                });
              },
            ),
          ),
          Expanded(
            child: filteredFloors.isEmpty
                ? const Center(child: Text("No matching locations"))
                : ListView.builder(
                    itemCount: filteredFloors.length,
                    itemBuilder: (context, index) {
                      final floor = filteredFloors[index];
                      return ExpansionTile(
                        title: Text("Location: $floor"),
                        children: [
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection(floor).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }

                              final lockers = snapshot.data!.docs;
                              if (lockers.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.all(8),
                                  child: Text("No lockers found"),
                                );
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: lockers.length,
                                itemBuilder: (context, i) {
                                  final locker = lockers[i];
                                  final id = locker.id;
                                  final data = locker.data() as Map<String, dynamic>;
                                  final size = data['size'] ?? 'N/A';
                                  final isUsed = data['status'] == true;
                                  final itemDetected = data['itemDetected'] == true;
                                  final canBeTapped = !isUsed && !itemDetected;

                                  return Opacity(
                                    opacity: isUsed ? 0.4 : 1.0,
                                    child: ListTile(
                                      onTap: canBeTapped ? () => handleLockerTap(context, floor, id, size) : null,
                                      leading: Icon(
                                        Icons.circle,
                                        color: itemDetected ? Colors.red : Colors.green,
                                        size: 16,
                                      ),
                                      title: Text('Locker $id [$size]'),
                                      subtitle: Text(
                                        '${isUsed ? 'Not available' : 'Available'} • ${itemDetected ? '📦 Object inside' : '❌ Empty'}',
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          )
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
