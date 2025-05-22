// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:flutter/material.dart';
// import 'dart:async';
// import 'package:last/Firebase/firestore.dart';
//
// class HomePage extends StatefulWidget {
//   final String customerPhone;
//
//   const HomePage({super.key, required this.customerPhone});
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
//       appBar: AppBar(title: const Text("My Packages")),
//       body: StreamBuilder<QuerySnapshot>(
//         stream: fireStoreService.getPackagesByCustomer(widget.customerPhone),
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("You have no packages yet."));
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
//               final lockerLocation = data['lockerLocation'] ?? 'Unknown';
//               final slotId = data['slotId'] ?? 'Unknown';
//               final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
//
//               return FutureBuilder<DocumentSnapshot>(
//                 future: FirebaseFirestore.instance
//                     .collection(lockerLocation)
//                     .doc(slotId)
//                     .get(),
//                 builder: (context, lockerSnapshot) {
//                   String description = 'No description';
//
//                   if (lockerSnapshot.hasData && lockerSnapshot.data!.exists) {
//                     final lockerData =
//                     lockerSnapshot.data!.data() as Map<String, dynamic>;
//                     description = data['description'] ?? 'No description';
//                   }
//
//                   return Card(
//                     margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     child: ListTile(
//                       title: Text('📝 Description: $description'),
//                       subtitle: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text('📍 Location: $lockerLocation'),
//                           Text('🔐 Locker ID: $slotId'),
//                           if (createdAt != null)
//                             Text('🕒 Created: ${createdAt.toLocal()}'),
//                         ],
//                       ),
//                       trailing: IconButton(
//                         icon: const Icon(Icons.download_done_rounded, color: Colors.green),
//                         tooltip: "Receive",
//                         onPressed: () async {
//                           final lockerRef = FirebaseFirestore.instance
//                               .collection(lockerLocation)
//                               .doc(slotId);
//
//                           await lockerRef.update({'pendingCommand': true});
//
//                           ScaffoldMessenger.of(context).showSnackBar(
//                             const SnackBar(
//                               content: Text("🚪 Locker opening... Please retrieve your item."),
//                             ),
//                           );
//
//                           int retryCount = 0;
//                           const maxRetries = 4;
//                           const checkInterval = Duration(seconds: 15);
//
//                           bool itemTaken = false;
//
//                           while (retryCount < maxRetries) {
//                             await Future.delayed(checkInterval);
//
//                             final snapshot = await lockerRef.get();
//                             final data = snapshot.data() as Map<String, dynamic>;
//                             final itemDetected = data['itemDetected'] == true;
//
//                             if (!itemDetected) {
//                               itemTaken = true;
//
//                               // Đóng locker và xóa package
//                               await lockerRef.update({
//                                 'locked': true,
//                                 'pendingCommand': false,
//                               });
//
//                               await fireStoreService.receivePackage(
//                                 doc.id,
//                                 lockerLocation,
//                                 slotId,
//                               );
//
//                               ScaffoldMessenger.of(context).showSnackBar(
//                                 const SnackBar(
//                                   content: Text("✅ Package received. Locker closed."),
//                                   backgroundColor: Colors.green,
//                                 ),
//                               );
//                               break;
//                             }
//
//                             retryCount++;
//                           }
//
//                           // Nếu thử đủ 4 lần mà vẫn chưa nhận
//                           if (!itemTaken) {
//                             await lockerRef.update({
//                               'locked': true,
//                               'pendingCommand': false,
//                             });
//
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               const SnackBar(
//                                 content: Text("⚠️ Timeout. Package was not retrieved. Locker closed."),
//                                 backgroundColor: Colors.orange,
//                               ),
//                             );
//                           }
//                         },
//
//
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
  final String customerPhone; // Pass this when navigating to HomePage

  const HomePage({super.key, required this.customerPhone});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FireStoreService fireStoreService = FireStoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Packages")),
      body: StreamBuilder<QuerySnapshot>(
        stream: fireStoreService.getPackagesByCustomer(widget.customerPhone),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasData) {
            // Filter only the current user's packages
            List<DocumentSnapshot> packageList = snapshot.data!.docs;
            // List<DocumentSnapshot> packageList = snapshot.data!.docs.where((doc) {
            //   final data = doc.data() as Map<String, dynamic>;
            //   return data['customerPhone'] == widget.customerPhone;
            // }).toList();

            if (packageList.isEmpty) {
              return const Center(child: Text("You have no packages yet."));
            }

            return ListView.builder(
              itemCount: packageList.length,
              itemBuilder: (context, index) {
                final document = packageList[index];
                final data = document.data() as Map<String, dynamic>;

                final location = data['lockerLocation'] ?? 'Unknown';
                final size = data['size'] ?? 'Unknown';
                final slotId = data['slotId'];
                final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

                // return Card(
                //                 //   margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                //                 //   child: ListTile(
                //                 //     title: Text('Locker: $location'),
                //                 //     subtitle: Column(
                //                 //       crossAxisAlignment: CrossAxisAlignment.start,
                //                 //       children: [
                //                 //         Text('Size: $size'),
                //                 //         Text('Slot ID: $slotId'),
                //                 //         if (createdAt != null)
                //                 //           Text('Created: ${createdAt.toLocal()}'),
                //                 //       ],
                //                 //     ),
                //                 //     trailing: IconButton(
                //                 //       icon: const Icon(Icons.download_done_rounded, color: Colors.green),
                //                 //       tooltip: "Receive",
                //                 //       onPressed: () async {
                //                 //         if (slotId != null) {
                //                 //           await fireStoreService.receivePackage(
                //                 //             document.id,
                //                 //             location,
                //                 //             slotId,
                //                 //           );
                //                 //
                //                 //           ScaffoldMessenger.of(context).showSnackBar(
                //                 //             const SnackBar(content: Text("Your locker has opened. Please retrieve your item within 3 minutes")),
                //                 //           );
                //                 //         }
                //                 //       },
                //                 //     ),
                //                 //   ),
                //                 // );
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    // 1️⃣ Title shows the description with an emoji
                    title: Text('📝 Description: ${data['description'] ?? '—'}'),
                    // 2️⃣ Subtitle lists all the other fields
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📍 Location: $location'),
                        Text('🔐 Locker ID: $slotId'),
                        Text('📦 Size: $size'),
                        if (createdAt != null)
                          Text('🕒 Created: ${createdAt.toLocal()}'),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.download_done_rounded, color: Colors.green),
                      tooltip: "Receive",
                      onPressed: () async {
                        if (slotId != null) {
                          await fireStoreService.receivePackage(
                            document.id,
                            location,
                            slotId,
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    "Your locker has opened. Please retrieve your item within 3 minutes"
                                )
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text("Error loading packages."));
          }
        },
      ),
    );
  }
}


