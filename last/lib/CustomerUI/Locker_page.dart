// import 'package:flutter/material.dart';
//
//
// class LockerPage extends StatelessWidget {
//   const LockerPage({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Text("Locker Page"),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Map/OpenMap.dart';

class LockerPage extends StatefulWidget {
  final String customerPhone;
  const LockerPage({Key? key, required this.customerPhone}) : super(key: key);

  @override
  State<LockerPage> createState() => _LockerPageState();
}

class _LockerPageState extends State<LockerPage> {
  List<String> _floors = [];
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchFloorsFromLockers();
  }

  Future<void> fetchFloorsFromLockers() async {
    final snapshot = await FirebaseFirestore.instance.collection('Lockers').get();
    final floors = snapshot.docs.map((doc) => doc['collection'] as String).toList();
    setState(() {
      _floors = floors;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredFloors = _searchQuery.isEmpty
        ? _floors
        : _floors.where((floor) => floor.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Available Lockers"),
      ),
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
            padding: const EdgeInsets.all(8.0),
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
                ? const Center(child: Text("No matching locations found"))
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
                                  padding: EdgeInsets.all(8.0),
                                  child: Text("No locker found"),
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
                                  final itemDetected = data['itemDetected'] == true;
                                  final isOccupied = (data['locked'] == true && data['itemDetected'] == true);
                                  final status = data['status'] == true;

                                  return Opacity(
                                    opacity: isOccupied || status ? 0.4 : 1.0,
                                    child: ListTile(
                                      leading: Icon(
                                        Icons.circle,
                                        color: itemDetected ? Colors.red : Colors.green,
                                        size: 16,
                                      ),
                                      title: Text("Locker $id [$size]"),
                                      subtitle: Text(
                                        '${status ? '❌ Unavailable' : '✅ Available'} • ${isOccupied ?  '📦 Occupied' : '❌ Empty'}',
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
