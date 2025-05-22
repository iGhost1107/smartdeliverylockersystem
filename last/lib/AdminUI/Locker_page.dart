import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../Map/OpenMap.dart';

class LockerPage extends StatefulWidget {
  const LockerPage({super.key});

  @override
  State<LockerPage> createState() => _LockerPageState();
}

class _LockerPageState extends State<LockerPage> {
  List<String> _floors = [];
  String _searchQuery = "";
  final TextEditingController _markerInputController = TextEditingController();
  final TextEditingController _linkInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchFloorsFromLockers();
  }

  @override
  void dispose() {
    _markerInputController.dispose();
    _linkInputController.dispose();
    super.dispose();
  }

  Future<void> fetchFloorsFromLockers() async {
    final snapshot =
    await FirebaseFirestore.instance.collection('Lockers').get();

    final floors =
    snapshot.docs.map((doc) => doc['collection'] as String).toList();

    setState(() {
      _floors = floors;
    });
  }

  void errorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> addMarker() async {
    final coordInput = _markerInputController.text.trim();
    final mapLink = _linkInputController.text.trim();

    // 1) parse "LatLng(lat, lng), Label"
    final regex = RegExp(r'LatLng\(([-\d.]+),\s*([-\d.]+)\),\s*(.+)');
    final match = regex.firstMatch(coordInput);

    if (match == null) {
      return errorMessage("Coordinates must be: LatLng(lat, lng), Label");
    }

    final lat = double.tryParse(match.group(1)!);
    final lng = double.tryParse(match.group(2)!);
    final label = match.group(3)!.trim();

    if (lat == null || lng == null || label.isEmpty) {
      return errorMessage("Invalid lat/lng or empty label.");
    }
    if (mapLink.isEmpty) {
      return errorMessage("Please enter a Google Maps link.");
    }

    // 2) build your minimal Location string
    final locationString = '$lat,$lng';

    try {
      // 3) write to Firestore
      await FirebaseFirestore.instance
          .collection('Lockers')
          .doc(label)
          .set({
        'GooglemapLink': mapLink,
        'Location': locationString,
        'collection': label,
        'name': label,
      });

      // 4) clear inputs & confirm
      _markerInputController.clear();
      _linkInputController.clear();
      Navigator.pop(context); // Close the dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added $label @ ($locationString)')),
      );
    } catch (e) {
      errorMessage("Couldn't save marker: $e");
    }
  }

  void _showAddLocationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _markerInputController,
              decoration: const InputDecoration(
                labelText: 'LatLng(lat, lng), Label',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _linkInputController,
              decoration: const InputDecoration(
                labelText: 'Google Maps link',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _markerInputController.clear();
              _linkInputController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: addMarker,
            icon: const Icon(Icons.add_location),
            label: const Text('Add Location'),
          ),
        ],
      ),
    );
  }

  Future<void> _addLocker(String floor) async {
    String? selectedSize;
    final TextEditingController _idController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add a Locker'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _idController,
                decoration: const InputDecoration(labelText: 'Locker ID'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: null,
                items: ['S', 'M', 'L'].map((size) {
                  return DropdownMenuItem(
                    value: size,
                    child: Text('Size $size'),
                  );
                }).toList(),
                onChanged: (value) {
                  selectedSize = value;
                },
                decoration: const InputDecoration(labelText: 'Select size'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final id = _idController.text.trim();
                if (selectedSize == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select a size.')),
                  );
                  return;
                }
                if (id.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a locker ID.')),
                  );
                  return;
                }
                final doc = FirebaseFirestore.instance.collection(floor).doc(id);
                final exists = await doc.get();
                if (exists.exists) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Locker ID "$id" already exists.')),
                  );
                  return;
                }
                await doc.set({
                  'size': selectedSize,
                  'itemDetected': false,
                  'locked': true,
                  'lastPhysicalUpdate': FieldValue.serverTimestamp(),
                  'pendingCommand': false,
                  'status': false,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Locker "$id" added to $floor.')),
                );
              },
              child: const Text('Add'),
            )
          ],
        );
      },
    );
  }

  Future<void> _updateLocker(String floor, String id, Map<String, dynamic> currentData) async {
    String? selectedSize = currentData['size'];
    bool? locked = currentData['locked'];
    bool? status = currentData['status'];
    bool? pendingCommand = currentData['pendingCommand'];
    bool? itemDetected = currentData['itemDetected'];

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Update Locker $id'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: selectedSize,
                    items: ['S', 'M', 'L'].map((size) {
                      return DropdownMenuItem(
                        value: size,
                        child: Text('Size $size'),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedSize = value),
                    decoration: const InputDecoration(labelText: 'Size'),
                  ),
                  SwitchListTile(
                    title: const Text('Available'),
                    value: status ?? false,
                    onChanged: (val) => setState(() => status = val),
                  ),
                  SwitchListTile(
                    title: const Text('Open Command'),
                    value: pendingCommand ?? false,
                    onChanged: (val) => setState(() => pendingCommand = val),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    await FirebaseFirestore.instance.collection(floor).doc(id).update({
                      'size': selectedSize,
                      'locked': locked,
                      'status': status,
                      'pendingCommand': pendingCommand,
                      'itemDetected': itemDetected,
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Locker "$id" updated.')),
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteLocker(String floor, String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete locker "$id" from $floor?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection(floor).doc(id).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Locker "$id" deleted from $floor.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFloors = _searchQuery.isEmpty
        ? _floors
        : _floors
        .where((floor) =>
        floor.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Lockers Management"),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'addLocation',
            onPressed: _showAddLocationDialog,
            child: const Icon(Icons.add_location),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'viewMap',
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
        ],
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
                    ListTile(
                      leading: const Icon(Icons.add),
                      title: const Text("Add a locker"),
                      onTap: () => _addLocker(floor),
                    ),
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(floor)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                              child: CircularProgressIndicator());
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
                          physics:
                          const NeverScrollableScrollPhysics(),
                          itemCount: lockers.length,
                          itemBuilder: (context, i) {
                            final locker = lockers[i];
                            final id = locker.id;
                            final data = locker.data() as Map<String, dynamic>;
                            final size = data['size'] ?? 'N/A';
                            final isUsed = data['status'] == true;
                            final itemDetected = data['itemDetected'] == true;

                            return Opacity(
                              opacity: isUsed ? 0.4 : 1.0,
                              child: ListTile(
                                onTap: () => _updateLocker(floor, id, data),
                                leading: Icon(
                                  Icons.circle,
                                  color: itemDetected
                                      ? Colors.red
                                      : Colors.green,
                                  size: 16,
                                ),
                                title: Text('Locker $id [$size]'),
                                subtitle:
                                Text('${isUsed ? 'Not available' : 'Available'} • ${itemDetected ? '📦 Object inside' : '❌ Empty'}'),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.grey),
                                  onPressed: () => _deleteLocker(floor, id),
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
