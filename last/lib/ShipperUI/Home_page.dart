// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'package:last/Firebase/firestore.dart';
//
// class HomePage extends StatefulWidget {
//   final String shipperPhone;
//   const HomePage({super.key, required this.shipperPhone});
//
//   @override
//   State<HomePage> createState() => _HomePageState();
// }
//
// class _HomePageState extends State<HomePage> {
//   final FireStoreService fireStoreService = FireStoreService();
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Package Viewer")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: fireStoreService.getPackagesByShipper(widget.shipperPhone),
//         builder: (context, snapshot) {
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No packages yet..."));
//           }
//
//           final packageList = snapshot.data!.docs;
//
//           return ListView.builder(
//             itemCount: packageList.length,
//             itemBuilder: (context, index) {
//               final doc = packageList[index];
//               final data = doc.data() as Map<String, dynamic>;
//
//               final customerPhone = data['customerPhone'] ?? 'Unknown';
//               final lockerLocation = data['lockerLocation'] ?? 'Unknown';
//               final slotId = data['slotId'] ?? 'Unknown';
//               final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
//
//               return FutureBuilder<QuerySnapshot>(
//                 future: FirebaseFirestore.instance
//                     .collection('users')
//                     .where('phone', isEqualTo: customerPhone)
//                     .get(),
//                 builder: (context, userSnapshot) {
//                   String customerName = 'Unknown';
//
//                   if (userSnapshot.hasData &&
//                       userSnapshot.data!.docs.isNotEmpty) {
//                     final userData = userSnapshot.data!.docs.first.data()
//                     as Map<String, dynamic>;
//                     final otherInfo = userData['otherInfo'] as Map<String, dynamic>?;
//                     customerName = otherInfo?['name'] ?? 'Unknown';
//                   }
//
//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     child: ListTile(
//                       title: Text('To: $customerName'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('📱 Phone: $customerPhone'),
//                           Text('📍 Location: $lockerLocation'),
//                           Text('🔐 Locker: $slotId'),
//                           if (createdAt != null)
//                             Text('🕒 Created: ${createdAt.toLocal()}'),
//                         ],
//                       ),
//                     ),
//                   );
//                 },
//               );
//             },
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:last/Firebase/firestore.dart';

class HomePage extends StatefulWidget {
  final String shipperPhone;
  const HomePage({super.key, required this.shipperPhone});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FireStoreService fireStoreService = FireStoreService();
  final TextEditingController customerPhoneController = TextEditingController();
  final TextEditingController lockerLocationController = TextEditingController();
  String selectedSize = 'M'; // default

  void openPackageDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Package'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: customerPhoneController,
                decoration: const InputDecoration(labelText: 'Customer Phone'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: lockerLocationController,
                decoration: const InputDecoration(labelText: 'Locker Location'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedSize,
                decoration: const InputDecoration(labelText: 'Size'),
                items: ['S', 'M', 'L'].map((size) {
                  return DropdownMenuItem<String>(
                    value: size,
                    child: Text(size),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedSize = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final customerPhone = customerPhoneController.text.trim();
              final lockerLocation = lockerLocationController.text.trim();

              if (customerPhone.isNotEmpty && lockerLocation.isNotEmpty) {
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
                  'customerPhone': customerPhone,
                  'lockerLocation': lockerLocation,
                  'size': selectedSize,
                  'shipperPhone': widget.shipperPhone,
                });

                Navigator.of(context, rootNavigator: true).pop(); // Close loading

                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Package added successfully")),
                  );
                  customerPhoneController.clear();
                  lockerLocationController.clear();
                  setState(() {
                    selectedSize = 'M';
                  });
                  Navigator.pop(context); // Close dialog
                }
              }
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Package Viewer")),
      floatingActionButton: FloatingActionButton(
        onPressed: openPackageDialog,
        child: const Icon(Icons.add),
        tooltip: "Add Package",
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fireStoreService.getPackagesByShipper(widget.shipperPhone),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No packages yet..."));
          }

          final packageList = snapshot.data!.docs;

          return ListView.builder(
            itemCount: packageList.length,
            itemBuilder: (context, index) {
              final doc = packageList[index];
              final data = doc.data() as Map<String, dynamic>;

              final customerPhone = data['customerPhone'] ?? 'Unknown';
              final lockerLocation = data['lockerLocation'] ?? 'Unknown';
              final slotId = data['slotId'] ?? 'Unknown';
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('phone', isEqualTo: customerPhone)
                    .get(),
                builder: (context, userSnapshot) {
                  String customerName = 'Unknown';

                  if (userSnapshot.hasData &&
                      userSnapshot.data!.docs.isNotEmpty) {
                    final userData = userSnapshot.data!.docs.first.data()
                    as Map<String, dynamic>;
                    final otherInfo = userData['otherInfo'] as Map<String, dynamic>?;
                    customerName = otherInfo?['name'] ?? 'Unknown';
                  }

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      title: Text('To: $customerName'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('📱 Phone: $customerPhone'),
                          Text('📍 Location: $lockerLocation'),
                          Text('🔐 Locker: $slotId'),
                          if (createdAt != null)
                            Text('🕒 Created: ${createdAt.toLocal()}'),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
