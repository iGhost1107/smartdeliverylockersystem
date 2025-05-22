import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:async';



class FireStoreService {

  final CollectionReference packages = FirebaseFirestore.instance.collection('packages');


  /// FOR SHIPPER
  /// Adds a new package if customer exists and locker slot is available.
  /// Returns `null` if success, or a string error message if failed.
  Future<String?> addPackage(Map<String, dynamic> packageInfo) async {
    final String phone = packageInfo['customerPhone'];
    final String size = packageInfo['size'];
    final String location = packageInfo['lockerLocation'];
    final String shipperphone = packageInfo['shipperPhone'];

    // Step 1: Check if customer exists
    final userExists = await doesUserExist(phone);
    if (!userExists) return 'User not found';

    // Step 2: Find available slot in locker
    final slotId = await getAvailableLockerId(location, size);
    if (slotId == null) return 'No available locker slot for selected size';

    // Step 3: Mark locker slot as used and sending command to open that slot
    await markLockerUsed(location, slotId);
    await sendingCommand(location, slotId);
    // Step 4: Wait for locker confirmation
    final lockerRef = FirebaseFirestore.instance
        .collection(location)
        .doc(slotId.toString()); // Ensure slotId is used as string

    final completer = Completer<String?>();
    late StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> subscription;

    subscription = lockerRef.snapshots().listen((snapshot) async {
      final data = snapshot.data();
      if (data == null) return;

      final bool locked = data['locked'] == true;
      final bool itemDetected = data['itemDetected'] == true;

      if (locked && itemDetected) {
        subscription.cancel();

        //Step 5: Add package only after confirmation
        await packages.add({
          'createdAt': Timestamp.now(),
          'customerPhone': phone,
          'lockerLocation': location,
          'shipperPhone': shipperphone,
          'slotId': slotId,
          'size': size,
        });

        // Send notification
        sendNotificationToCustomer(phone);

        completer.complete(null); // Success
      }
    });

    // Timeout after 60 seconds
    Future.delayed(const Duration(seconds: 20), () {
      if (!completer.isCompleted) {
        subscription.cancel();
        markLockerUnUsed(location, slotId);
        completer.complete('Locker did not confirm insertion in time, closing locker');
      }
    });

    return completer.future;
  }

  /// Real-time stream of all packages ordered by creation time
  // Stream<QuerySnapshot> getPackage() {
  //   return packages.orderBy('createdAt', descending: true).snapshots();
  // }

  Stream<QuerySnapshot> getPackagesByCustomer(String customerPhone) {
    return packages
        .where('customerPhone', isEqualTo: customerPhone)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getPackagesByShipper(String shipperPhone) {
    return packages
        .where('shipperPhone', isEqualTo: shipperPhone)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// Checks if a customer with given phone number exists
  Future<bool> doesUserExist(String phone) async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: "customer")
        .where('phone', isEqualTo: phone)
        .limit(1)
        .get();

    return query.docs.isNotEmpty;
  }

  // / Returns the index of the first available locker matching the size
  // Future<int?> getAvailableSlot(String location, String size) async {
  //
  //   final doc = await FirebaseFirestore.instance
  //       .collection('lockers')
  //       .doc(location)
  //       .get();
  //
  //   if (!doc.exists) return null;
  //
  //   final data = doc.data();
  //   if (data == null || !data.containsKey('lockers')) return null;
  //
  //   final List<dynamic> lockers = data['lockers'];
  //   for (int i = 0; i < lockers.length; i++) {
  //     final locker = lockers[i];
  //     if (locker['size'] == size && locker['status'] == false) {
  //       return i;
  //     }
  //   }
  //
  //   return null; // No available locker found
  // }


  Future<String?> getAvailableLockerId(String location, String size) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection(location)
        .where('size', isEqualTo: size)
        .where('status', isEqualTo: false)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;

    return querySnapshot.docs.first.id; // Return locker ID
  }



  // update the locker status
  // Future<void> markLockerUsed(String location, int slotId) async {
  //   final lockerRef = FirebaseFirestore.instance.collection('lockers').doc(location);
  //
  //   // Step 1: Read the current array
  //   final snapshot = await lockerRef.get();
  //   final data = snapshot.data();
  //
  //   if (data == null || data['lockers'] == null) return;
  //
  //   List<dynamic> lockers = List.from(data['lockers']);
  //
  //   // Step 2: Update specific index
  //   lockers[slotId]['status'] = true;
  //
  //   // Step 3: Push updated array back
  //   await lockerRef.update({
  //     'lockers': lockers,
  //   });
  // }

  Future<void> markLockerUsed(String location, String slotId) async {
    final lockerRef = FirebaseFirestore.instance
        .collection(location)
        .doc(slotId);

    await lockerRef.update({'status': true});
  }

  Future<void> markLockerUnUsed(String location, String slotId) async {
    final lockerRef = FirebaseFirestore.instance
        .collection(location)
        .doc(slotId);

    await lockerRef.update({'status': false});
  }

  Future<void> sendingCommand(String location, String slotId) async {
    final lockerRef = FirebaseFirestore.instance
        .collection(location)
        .doc(slotId);

    await lockerRef.update({'pendingCommand': true});
  }









  // Receive the package
  // Future<void> receivePackage(String docId, String location, int slotId) async {
  //   // 1. Delete the package
  //   await packages.doc(docId).delete();
  //
  //   // 2. Mark the locker slot as available again
  //   final lockerRef = FirebaseFirestore.instance.collection('lockers').doc(location);
  //   final snapshot = await lockerRef.get();
  //   final data = snapshot.data();
  //
  //   if (data == null || data['lockers'] == null) return;
  //
  //   List<dynamic> lockers = List.from(data['lockers']);
  //   lockers[slotId]['status'] = false;
  //
  //   await lockerRef.update({
  //     'lockers': lockers,
  //   });
  // }

  Future<void> receivePackage(String docId, String location, String slotId) async {
    // return state to false, and sending command to open
    await markLockerUnUsed(location, slotId);
    await sendingCommand(location, slotId);
    // 2. Delete the package
    await packages.doc(docId).delete();
  }


  Future<void> sendNotificationToCustomer(String phone) async {
  }


}

