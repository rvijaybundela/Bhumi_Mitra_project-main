import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/local_mangalvedhe_service.dart';

class MangalvedheMapScreen extends StatefulWidget {
  const MangalvedheMapScreen({super.key});

  @override
  State<MangalvedheMapScreen> createState() => _MangalvedheMapScreenState();
}

class _MangalvedheMapScreenState extends State<MangalvedheMapScreen> {
  List<Polygon> flutterMapPolygons = [];
  Set<gmaps.Polygon> googleMapPolygons = {};
  bool isLoading = true;
  String? error;
  bool useGoogleMaps = false;
  gmaps.GoogleMapController? _googleMapController;

  @override
  void initState() {
    super.initState();
    _loadMangalvedheData();
  }

  Future<void> _loadMangalvedheData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final geoJsonData = await LocalMangalvedheService.loadMangalvedheGeoJson();
      
      List<Polygon> fPolygons = [];
      Set<gmaps.Polygon> gPolygons = {};

      for (int i = 0; i < geoJsonData['features'].length; i++) {
        var feature = geoJsonData['features'][i];
        var geometry = feature['geometry'];
        var properties = feature['properties'];
        
        if (geometry['type'] == 'MultiPolygon') {
          // Handle MultiPolygon - take the first polygon
          var coords = geometry['coordinates'][0][0];
          
          // Convert coordinates for flutter_map (lat, lng)
          List<LatLng> flutterPoints = coords
              .map<LatLng>((coord) => LatLng(coord[1], coord[0]))
              .toList();

          // Convert coordinates for google_maps (lat, lng)
          List<gmaps.LatLng> googlePoints = coords
              .map<gmaps.LatLng>((coord) => gmaps.LatLng(coord[1], coord[0]))
              .toList();

          // Get survey number (PIN) for display
          String surveyNumber = properties['PIN']?.toString() ?? 'N/A';

          // Create polygon for flutter_map
          fPolygons.add(
            Polygon(
              points: flutterPoints,
              color: Colors.blue.withOpacity(0.3),
              borderStrokeWidth: 2,
              borderColor: Colors.blue,
              label: surveyNumber,
              labelStyle: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          );

          // Create polygon for google_maps
          gPolygons.add(
            gmaps.Polygon(
              polygonId: gmaps.PolygonId('polygon_$i'),
              points: googlePoints,
              fillColor: Colors.blue.withOpacity(0.3),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          );
        }
      }

      setState(() {
        flutterMapPolygons = fPolygons;
        googleMapPolygons = gPolygons;
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mangalvedhe Survey Map'),
        actions: [
          IconButton(
            icon: Icon(useGoogleMaps ? Icons.map : Icons.satellite),
            onPressed: () {
              setState(() {
                useGoogleMaps = !useGoogleMaps;
              });
            },
            tooltip: useGoogleMaps ? 'Switch to OpenStreetMap' : 'Switch to Google Maps',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadMangalvedheData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : useGoogleMaps
                  ? _buildGoogleMap()
                  : _buildFlutterMap(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showSurveyNumberDialog();
        },
        child: const Icon(Icons.search),
      ),
    );
  }

  Widget _buildFlutterMap() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(17.52, 75.37), // Centered on Mangalvedhe
        zoom: 13.0,
        minZoom: 5.0,  // Allow zooming out further
        maxZoom: 18.0, // Allow zooming in closer
        interactiveFlags: InteractiveFlag.all, // Enable all interactions including zoom
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: const ['a', 'b', 'c'],
        ),
        PolygonLayer(polygons: flutterMapPolygons),
      ],
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: gmaps.LatLng(17.52, 75.37), // Centered on Mangalvedhe
        zoom: 13.0,
      ),
      polygons: googleMapPolygons,
      onMapCreated: (gmaps.GoogleMapController controller) {
        _googleMapController = controller;
      },
      zoomControlsEnabled: true, // Enable zoom controls
      zoomGesturesEnabled: true, // Enable pinch zoom
      scrollGesturesEnabled: true, // Enable pan
      rotateGesturesEnabled: true, // Enable rotation
      tiltGesturesEnabled: true, // Enable tilt
      myLocationButtonEnabled: false, // Disable location button
      mapToolbarEnabled: false, // Disable map toolbar
    );
  }

  void _showSurveyNumberDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Survey Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                hintText: 'Enter PIN/Survey Number',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                Navigator.pop(context);
                await _searchSurveyNumber(value);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _searchSurveyNumber(String pin) async {
    try {
      final feature = await LocalMangalvedheService.getFeatureBySurveyNumber(pin);
      if (feature != null) {
        // Calculate center of the polygon
        var geometry = feature['geometry'];
        if (geometry['type'] == 'MultiPolygon') {
          var coords = geometry['coordinates'][0][0];
          double totalLat = 0;
          double totalLng = 0;
          for (var coord in coords) {
            totalLat += coord[1];
            totalLng += coord[0];
          }
          double centerLat = totalLat / coords.length;
          double centerLng = totalLng / coords.length;

          if (useGoogleMaps && _googleMapController != null) {
            _googleMapController!.animateCamera(
              gmaps.CameraUpdate.newLatLngZoom(
                gmaps.LatLng(centerLat, centerLng),
                16.0,
              ),
            );
          } else {
            // For flutter_map, we would need to update the MapOptions
            // This is a simplified approach
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Found survey number $pin')),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Survey number $pin not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error searching: $e')),
      );
    }
  }
}
