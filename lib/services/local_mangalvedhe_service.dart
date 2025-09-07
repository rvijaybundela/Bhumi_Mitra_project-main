import 'dart:convert';
import 'package:flutter/services.dart';

class LocalMangalvedheService {
  
  // Load GeoJSON data with viewport filtering for performance
  static Future<Map<String, dynamic>> loadMangalvedheGeoJson({
    double? minLat, 
    double? maxLat, 
    double? minLng, 
    double? maxLng,
    double? zoomLevel
  }) async {
    try {
      print('📁 Loading Mangalvedhe data from local file...');
      final String jsonString = await rootBundle.loadString('assets/Mangalvedhe.geojson');
      final Map<String, dynamic> geoJsonData = json.decode(jsonString);
      
      List<dynamic> allFeatures = geoJsonData['features'] ?? [];
      List<dynamic> visibleFeatures = [];
      
      // If viewport bounds are provided, filter polygons within visible area
      if (minLat != null && maxLat != null && minLng != null && maxLng != null && zoomLevel != null && zoomLevel > 14) {
        print('🔍 Filtering polygons for viewport: ${minLat.toStringAsFixed(3)}, ${minLng.toStringAsFixed(3)} to ${maxLat.toStringAsFixed(3)}, ${maxLng.toStringAsFixed(3)}');
        
        for (var feature in allFeatures) {
          var geometry = feature['geometry'];
          if (geometry['type'] == 'MultiPolygon') {
            var coords = geometry['coordinates'][0][0];
            
            // Check if polygon intersects with viewport
            bool isVisible = false;
            for (var coord in coords) {
              double lng = coord[0];
              double lat = coord[1];
              
              if (lat >= minLat && lat <= maxLat && lng >= minLng && lng <= maxLng) {
                isVisible = true;
                break;
              }
            }
            
            if (isVisible) {
              visibleFeatures.add(feature);
            }
          }
        }
        
        geoJsonData['features'] = visibleFeatures;
        print('⚡ Viewport loading: ${visibleFeatures.length}/${allFeatures.length} polygons in view');
      } else {
        // Show limited polygons when zoomed out for performance
        if (zoomLevel != null && zoomLevel < 12) {
          // Very zoomed out: show every 50th polygon
          for (int i = 0; i < allFeatures.length; i += 50) {
            visibleFeatures.add(allFeatures[i]);
          }
          geoJsonData['features'] = visibleFeatures;
          print('⚡ Overview mode: ${visibleFeatures.length}/${allFeatures.length} polygons');
        } else if (zoomLevel != null && zoomLevel < 14) {
          // Medium zoom: show every 10th polygon
          for (int i = 0; i < allFeatures.length; i += 10) {
            visibleFeatures.add(allFeatures[i]);
          }
          geoJsonData['features'] = visibleFeatures;
          print('⚡ Medium zoom: ${visibleFeatures.length}/${allFeatures.length} polygons');
        } else {
          print('✅ Full detail: loaded ${allFeatures.length} features');
        }
      }
      
      return geoJsonData;
    } catch (e) {
      print('❌ Error loading local GeoJSON: $e');
      throw Exception('Failed to load local GeoJSON file: $e');
    }
  }
  
  // Get all survey numbers (PINs) from local data
  static Future<List<String>> getSurveyNumbers() async {
    try {
      final geoJsonData = await loadMangalvedheGeoJson();
      List<String> surveyNumbers = [];
      
      if (geoJsonData['features'] != null) {
        for (var feature in geoJsonData['features']) {
          var properties = feature['properties'];
          if (properties != null && properties['PIN'] != null) {
            String pin = properties['PIN'].toString();
            if (pin.isNotEmpty && pin != 'null') {
              surveyNumbers.add(pin);
            }
          }
        }
      }
      
      surveyNumbers.sort();
      return surveyNumbers;
    } catch (e) {
      throw Exception('Error extracting survey numbers: $e');
    }
  }
  
  // Search for features by survey number
  static Future<List<Map<String, dynamic>>> searchBySurveyNumber(String searchTerm) async {
    try {
      final geoJsonData = await loadMangalvedheGeoJson();
      List<Map<String, dynamic>> matchingFeatures = [];
      
      if (geoJsonData['features'] != null) {
        for (var feature in geoJsonData['features']) {
          var properties = feature['properties'];
          if (properties != null && properties['PIN'] != null) {
            String pin = properties['PIN'].toString().toLowerCase();
            if (pin.contains(searchTerm.toLowerCase())) {
              matchingFeatures.add(feature);
            }
          }
        }
      }
      
      return matchingFeatures;
    } catch (e) {
      throw Exception('Error searching features: $e');
    }
  }
  
  // Get feature by exact survey number
  static Future<Map<String, dynamic>?> getFeatureBySurveyNumber(String surveyNumber) async {
    try {
      final geoJsonData = await loadMangalvedheGeoJson();
      
      if (geoJsonData['features'] != null) {
        for (var feature in geoJsonData['features']) {
          var properties = feature['properties'];
          if (properties != null && properties['PIN'] != null) {
            String pin = properties['PIN'].toString();
            if (pin == surveyNumber) {
              return feature;
            }
          }
        }
      }
      
      return null;
    } catch (e) {
      throw Exception('Error finding feature: $e');
    }
  }
  
  // Get center coordinates for a specific survey number
  static Future<Map<String, double>?> getSurveyNumberCenter(String surveyNumber) async {
    try {
      final feature = await getFeatureBySurveyNumber(surveyNumber);
      if (feature != null && feature['geometry'] != null) {
        var geometry = feature['geometry'];
        if (geometry['type'] == 'MultiPolygon' && geometry['coordinates'] != null) {
          var coords = geometry['coordinates'][0][0];
          if (coords.isNotEmpty) {
            // Calculate center of polygon
            double totalLat = 0;
            double totalLng = 0;
            int count = coords.length;
            
            for (var coord in coords) {
              totalLng += coord[0];
              totalLat += coord[1];
            }
            
            return {
              'latitude': totalLat / count,
              'longitude': totalLng / count,
            };
          }
        }
      }
      return null;
    } catch (e) {
      throw Exception('Error calculating center: $e');
    }
  }
}
