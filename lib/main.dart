import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Map Location',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();

  LatLng _currentLocation = LatLng(13.7563, 100.5018);
  double _accuracy = 0;
  bool _locationLoaded = false;

  int _mapStyleIndex = 0;

  final List<Map<String, String>> _mapStyles = [
    {
      'name': 'OpenStreetMap',
      'url': 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    },
    {
      'name': 'Dark Mode',
      'url': 'https://tiles.stadiamaps.com/tiles/alidade_dark/{z}/{x}/{y}.png',
    },
    {
      'name': 'Satellite',
      'url':
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    },
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _accuracy = position.accuracy; // ← ค่า accuracy (เมตร)
      _locationLoaded = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(_currentLocation, 16);
    });
  }

  void _changeMapStyle() {
    setState(() {
      _mapStyleIndex = (_mapStyleIndex + 1) % _mapStyles.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Map Location'),
        actions: [
          IconButton(
            icon: const Icon(Icons.layers),
            tooltip: 'เปลี่ยนรูปแบบแผนที่',
            onPressed: _changeMapStyle,
          ),
        ],
      ),
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 6,
        ),
        children: [
          TileLayer(
            urlTemplate: _mapStyles[_mapStyleIndex]['url']!,
            userAgentPackageName: 'com.example.flutter_map_location',
          ),

          // วงกลมแสดง accuracy
          if (_locationLoaded)
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _currentLocation,
                  radius: _accuracy, // หน่วยเป็นเมตร
                  useRadiusInMeter: true,
                  color: Colors.blue.withOpacity(0.2),
                  borderColor: Colors.blue,
                  borderStrokeWidth: 2,
                ),
              ],
            ),

          // Marker ตำแหน่งผู้ใช้
          if (_locationLoaded)
            MarkerLayer(
              markers: [
                Marker(
                  width: 50,
                  height: 50,
                  point: _currentLocation,
                  child: const Icon(
                    Icons.person_pin_circle,
                    color: Colors.red,
                    size: 45,
                  ),
                ),
              ],
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'location',
            onPressed: _getCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'map',
            onPressed: _changeMapStyle,
            backgroundColor: Colors.indigo,
            child: const Icon(Icons.layers),
          ),
        ],
      ),
    );
  }
}
