import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';
import 'package:url_launcher/url_launcher.dart';

class OpenstreetmapScreen extends StatefulWidget {
  const OpenstreetmapScreen({super.key});

  @override
  State<OpenstreetmapScreen> createState() => _OpenstreetmapScreenState();
}

class _OpenstreetmapScreenState extends State<OpenstreetmapScreen> {
  final MapController _mapController = MapController();
  final Location _location = Location();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool isLoading = true;
  LatLng? _currentLocation;
  List<Marker> _customMarkers = [];

  @override
  void initState() {
    super.initState();
    _initializationLocation();
    _initializationLocation().then((_) => _loadLockerMarkers());
  }

  Future<void> _initializationLocation() async {
    if(!await _checktheRequestPermissions()) return;

    _location.onLocationChanged.listen((LocationData locationData) {
      if(locationData.latitude != null && locationData.longitude != null) {
        setState(() {
          _currentLocation = LatLng(locationData.latitude!, locationData.longitude!);
          isLoading = false;
        });
      }
    });
  }

  void errorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> _checktheRequestPermissions() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if(!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if(!serviceEnabled) return false;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if(permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return false;
    }
    return true;
  }

  Future<void> _userCurrentLocation() async {
    if(_currentLocation != null) {
      _mapController.move(_currentLocation!, 15);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Current location not available")
        )
      );
    }
  }

  void _addCustomMarker(LatLng point, {String? label}) {
    final marker = Marker(
      width: 60,
      height: 60,
      point: point,
      child: GestureDetector(
        onTap: () => _openGoogleMaps(label ?? ''),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [BoxShadow(blurRadius: 3, color: Colors.black26)],
                ),
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const Icon(
              Icons.location_on,
              color: Colors.red,
              size: 30,
            ),
          ],
        ),
      ),
    );

    setState(() {
      _customMarkers.add(marker);
    });
  }

  Future<void> _openGoogleMaps(String name) async {
    if (name.isEmpty) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('Lockers')
          .doc(name)
          .get();

      if (doc.exists) {
        final googleMapLink = doc.get('GooglemapLink') as String;
        String formattedUrl = googleMapLink;
        if (!formattedUrl.startsWith('http://') && !formattedUrl.startsWith('https://')) {
          formattedUrl = 'https://$formattedUrl';
        }

        final url = Uri.parse(formattedUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $url';
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No Google Maps link found for this location')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _loadLockerMarkers() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Lockers')
        .get();

    for (final doc in snapshot.docs) {
      final locStr = doc.get('Location') as String;
      final coords = locStr.split(',');

      if (coords.length == 2) {
        final lat = double.tryParse(coords[0].trim());
        final lng = double.tryParse(coords[1].trim());
        final label = (doc.data().containsKey('name') && (doc.get('name') as String).isNotEmpty)
            ? doc.get('name') as String
            : doc.id;

        if (lat != null && lng != null) {
          _addCustomMarker(
            LatLng(lat, lng),
            label: label,
          );
        }
      }
    }

    setState(() {});
  }

  Future<void> _searchLocation(String searchText) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Lockers')
          .where('name', isGreaterThanOrEqualTo: searchText)
          .where('name', isLessThanOrEqualTo: searchText + '\uf8ff')
          .get();

      if (snapshot.docs.isNotEmpty) {
        final doc = snapshot.docs.first;
        final locStr = doc.get('Location') as String;
        final coords = locStr.split(',');

        if (coords.length == 2) {
          final lat = double.tryParse(coords[0].trim());
          final lng = double.tryParse(coords[1].trim());

          if (lat != null && lng != null) {
            final location = LatLng(lat, lng);
            _mapController.move(location, 15);
          } else {
            errorMessage('Invalid coordinates found for this location');
          }
        } else {
          errorMessage('Invalid location format in database');
        }
      } else {
        errorMessage('No matching locations found');
      }
    } catch (e) {
      errorMessage('Error searching location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Locker Locations Map"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          if (isLoading)
            const Center(child: CircularProgressIndicator())
          else
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _currentLocation ?? const LatLng(21.0278, 105.8342),
                initialZoom: 13,
                minZoom: 5,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                CurrentLocationLayer(
                  style: LocationMarkerStyle(
                    markerSize: Size(20, 20),
                    markerDirection: MarkerDirection.heading,
                  ),
                ),
                if (_customMarkers.isNotEmpty)
                  MarkerLayer(markers: _customMarkers),
              ],
            ),
          Positioned(
            top: 0,
            right: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search location...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                onSubmitted: _searchLocation,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        elevation: 0,
        onPressed: _userCurrentLocation,
        backgroundColor: Colors.blue,
        child: const Icon(
          Icons.my_location,
          size: 30,
          color: Colors.white,
        ),
      ),
    );
  }
}

