import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmaps;
import '../services/local_mangalvedhe_service.dart';

class MangalvedheGoogleMapScreen extends StatefulWidget {
  const MangalvedheGoogleMapScreen({super.key});

  @override
  State<MangalvedheGoogleMapScreen> createState() => _MangalvedheGoogleMapScreenState();
}

class _MangalvedheGoogleMapScreenState extends State<MangalvedheGoogleMapScreen> {
  Set<gmaps.Polygon> mangalvedhePolygons = {};
  Set<gmaps.Marker> markers = {};
  bool isLoading = true;
  String? error;
  gmaps.GoogleMapController? _mapController;
  
  // Maharashtra bounds with Mangalvedhe centered
  static const gmaps.LatLng maharashtraCenter = gmaps.LatLng(19.0760, 72.8777); // Mumbai area
  static const gmaps.LatLng mangalvedheCenter = gmaps.LatLng(17.52, 75.37); // Mangalvedhe
  double currentZoom = 7.0; // Start with Maharashtra view
  bool showingMangalvedheDetails = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Add Maharashtra state marker
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('maharashtra'),
          position: maharashtraCenter,
          infoWindow: const gmaps.InfoWindow(
            title: 'महाराष्ट्र / Maharashtra',
            snippet: 'Mangalvedhe is located in this state',
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueOrange),
        ),
      );

      // Add Mangalvedhe marker
      markers.add(
        gmaps.Marker(
          markerId: const gmaps.MarkerId('mangalvedhe'),
          position: mangalvedheCenter,
          infoWindow: const gmaps.InfoWindow(
            title: 'मंगळवेढे / Mangalvedhe',
            snippet: 'Tap to view survey polygons',
          ),
          icon: gmaps.BitmapDescriptor.defaultMarkerWithHue(gmaps.BitmapDescriptor.hueRed),
          onTap: () => _loadMangalvedhePolygons(),
        ),
      );

      setState(() {
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> _loadMangalvedhePolygons() async {
    try {
      setState(() {
        isLoading = true;
      });

      // Zoom to Mangalvedhe
      _mapController?.animateCamera(
        gmaps.CameraUpdate.newLatLngZoom(mangalvedheCenter, 14.0),
      );

      // Load GeoJSON data
      final geoJsonData = await LocalMangalvedheService.loadMangalvedheGeoJson();
      
      Set<gmaps.Polygon> polygons = {};
      List<gmaps.LatLng> allPoints = [];

      // Process all polygons for full map
      for (int i = 0; i < geoJsonData['features'].length; i++) {
        var feature = geoJsonData['features'][i];
        var geometry = feature['geometry'];
        var properties = feature['properties'];
        
        if (geometry['type'] == 'MultiPolygon') {
          var coords = geometry['coordinates'][0][0];
          
          List<gmaps.LatLng> polygonPoints = coords
              .map<gmaps.LatLng>((coord) => gmaps.LatLng(coord[1], coord[0]))
              .toList();

          allPoints.addAll(polygonPoints);
          
          String surveyNumber = properties['PIN']?.toString() ?? 'N/A';
          
          // Create polygon with survey number
          polygons.add(
            gmaps.Polygon(
              polygonId: gmaps.PolygonId('mangalvedhe_$i'),
              points: polygonPoints,
              fillColor: _getPolygonColor(i).withOpacity(0.4),
              strokeColor: _getPolygonColor(i),
              strokeWidth: 2,
              consumeTapEvents: true,
              onTap: () => _showSurveyDetails(surveyNumber, polygonPoints),
            ),
          );
        }
      }

      setState(() {
        mangalvedhePolygons = polygons;
        showingMangalvedheDetails = true;
        isLoading = false;
      });

      print('✅ Loaded ${polygons.length} Mangalvedhe polygons');

    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Color _getPolygonColor(int index) {
    // Alternate colors for better visibility
    List<Color> colors = [
      Colors.blue,
      Colors.green, 
      Colors.red,
      Colors.purple,
      Colors.orange,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  void _showSurveyDetails(String surveyNumber, List<gmaps.LatLng> points) {
    // Calculate center of polygon
    double lat = points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    double lng = points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Survey Number: $surveyNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location: ${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            Text('Polygon Points: ${points.length}'),
            const SizedBox(height: 8),
            const Text('मंगळवेढे गाव / Mangalvedhe Village'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _mapController?.animateCamera(
                gmaps.CameraUpdate.newLatLngZoom(gmaps.LatLng(lat, lng), 16.0),
              );
            },
            child: const Text('Zoom Here'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          showingMangalvedheDetails 
            ? 'Mangalvedhe Survey Map' 
            : 'Maharashtra - Mangalvedhe Location'
        ),
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        actions: [
          if (showingMangalvedheDetails)
            IconButton(
              icon: const Icon(Icons.zoom_out_map),
              onPressed: _resetToMaharashtraView,
              tooltip: 'View Maharashtra',
            ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToMangalvedhe,
            tooltip: 'Go to Mangalvedhe',
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B4513)),
                  ),
                  SizedBox(height: 16),
                  Text('Loading map data...'),
                ],
              ),
            )
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadInitialData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _buildGoogleMap(),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (showingMangalvedheDetails)
            FloatingActionButton(
              heroTag: "search",
              onPressed: _showSearchDialog,
              backgroundColor: const Color(0xFF8B4513),
              child: const Icon(Icons.search, color: Colors.white),
            ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "load",
            onPressed: showingMangalvedheDetails ? null : _loadMangalvedhePolygons,
            backgroundColor: showingMangalvedheDetails 
                ? Colors.grey 
                : const Color(0xFF8B4513),
            child: Icon(
              Icons.map,
              color: showingMangalvedheDetails ? Colors.white54 : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoogleMap() {
    return gmaps.GoogleMap(
      initialCameraPosition: gmaps.CameraPosition(
        target: showingMangalvedheDetails ? mangalvedheCenter : maharashtraCenter,
        zoom: showingMangalvedheDetails ? 14.0 : 7.0,
      ),
      polygons: mangalvedhePolygons,
      markers: markers,
      onMapCreated: (gmaps.GoogleMapController controller) {
        _mapController = controller;
      },
      zoomControlsEnabled: true,
      zoomGesturesEnabled: true,
      scrollGesturesEnabled: true,
      rotateGesturesEnabled: true,
      tiltGesturesEnabled: true,
      myLocationButtonEnabled: true,
      myLocationEnabled: false,
      mapType: gmaps.MapType.hybrid, // Show satellite + roads for better context
      onCameraMove: (gmaps.CameraPosition position) {
        currentZoom = position.zoom;
      },
    );
  }

  void _resetToMaharashtraView() {
    setState(() {
      mangalvedhePolygons.clear();
      showingMangalvedheDetails = false;
    });
    
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(maharashtraCenter, 7.0),
    );
  }

  void _goToMangalvedhe() {
    _mapController?.animateCamera(
      gmaps.CameraUpdate.newLatLngZoom(mangalvedheCenter, 14.0),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Search Survey Number'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter PIN/Survey Number',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) async {
            Navigator.pop(context);
            await _searchSurveyNumber(value);
          },
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

          _mapController?.animateCamera(
            gmaps.CameraUpdate.newLatLngZoom(
              gmaps.LatLng(centerLat, centerLng),
              16.0,
            ),
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Found and zoomed to survey number $pin')),
          );
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
