import 'package:flutter/services.dart' show rootBundle;
import 'package:geojson/geojson.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'dart:ui' as ui; // Needed for Offset
import 'package:flutter/material.dart'; // Needed for Colors

// A simple class to hold our building data
class Building {
  final String name;
  final LatLng center;
  final List<LatLng> polygonPoints;

  Building({required this.name, required this.center, required this.polygonPoints});
}

class MapService {
  List<Building> _buildings = [];

  Future<void> _loadBuildingData() async {
    if (_buildings.isNotEmpty) return;

    try {
      final String geoJsonString = await rootBundle.loadString('assets/map/buildings.geojson');
      
      final geojson = GeoJson();
      await geojson.parse(geoJsonString);

      List<Building> loadedBuildings = [];

      for (final feature in geojson.features) {
        final properties = feature.properties;
        final geometry = feature.geometry;

        if (properties != null && geometry is GeoJsonPolygon) {
          final String name = properties['name'];
          
          List<LatLng> points = [];
          for (final geoPoint in geometry.geoSeries[0].geoPoints) {
            points.add(LatLng(geoPoint.latitude, geoPoint.longitude));
          }
          
          final LatLng center = _calculateCentroid(points);

          loadedBuildings.add(Building(
            name: name,
            center: center,
            polygonPoints: points,
          ));
        }
      }
      
      loadedBuildings.sort((a, b) => a.name.compareTo(b.name));
      _buildings = loadedBuildings;
    } catch (e) {
      print('---!!! ERROR LOADING GEOJSON !!!---');
      print('Failed to load or parse "assets/map/buildings.geojson".');
      print('Error: $e');
      throw Exception('Failed to load building data. Check asset path or file content.');
    }
  }

  LatLng _calculateCentroid(List<LatLng> points) {
    if (points.isEmpty) return const LatLng(0, 0);
    
    double latitude = 0;
    double longitude = 0;
    int pointCount = points.length;

    if (points.first.latitude == points.last.latitude && points.first.longitude == points.last.longitude) {
      pointCount = points.length - 1;
    }
    
    for (int i = 0; i < pointCount; i++) {
      latitude += points[i].latitude;
      longitude += points[i].longitude;
    }
    
    return LatLng(latitude / pointCount, longitude / pointCount);
  }

  // NEW HELPER FUNCTION: Creates a transparent dot icon
  Future<BitmapDescriptor> _createTransparentMarker() async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint()..color = Colors.transparent;
    
    // Draw a tiny transparent circle (1x1 px)
    canvas.drawCircle(const Offset(0, 0), 0.1, paint); 
    
    final img = await pictureRecorder.endRecording().toImage(1, 1);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }


  // --- Public Functions ---

  Future<List<Building>> getBuildings() async {
    await _loadBuildingData();
    return _buildings;
  }

  Future<Set<Polygon>> getBuildingPolygons() async {
    await _loadBuildingData();
    Set<Polygon> polygons = {};

    for (var building in _buildings) {
      polygons.add(Polygon(
        polygonId: PolygonId(building.name),
        points: building.polygonPoints,
        strokeWidth: 2,
        strokeColor: AppTheme.primaryColor,
        fillColor: AppTheme.primaryColor.withAlpha(51), // 0.2 * 255
        consumeTapEvents: true,
        onTap: () {
          // Optional: Show building name on tap
        },
      ));
    }
    return polygons;
  }
  
  // MODIFIED (1): New function to create custom markers for building names
  Future<Set<Marker>> getBuildingNameMarkers() async {
    await _loadBuildingData();
    Set<Marker> markers = {};
    
    final transparentIcon = await _createTransparentMarker();
    
    for (var building in _buildings) {
      markers.add(Marker(
        markerId: MarkerId('label_${building.name}'),
        position: building.center,
        // The InfoWindow title acts as the permanent GeoJSON name label
        infoWindow: InfoWindow(
          title: building.name, // The accurate name from GeoJSON
        ),
        // CRITICAL FIX: Use transparent icon, ensuring no pin is visible
        icon: transparentIcon,
        anchor: const Offset(0.5, 0.5), // Center the marker icon
        zIndex: 1, // Ensure they are below post pins
      ));
    }
    return markers;
  }
}