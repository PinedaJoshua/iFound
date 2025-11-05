import 'package:flutter/services.dart' show rootBundle;
import 'package:geojson/geojson.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'dart:ui' as ui; // Canvas/UI
import 'dart:typed_data'; // Uint8List
import 'package:flutter/material.dart'; // Colors, Offset
import 'package:google_fonts/google_fonts.dart'; // Custom font

// Simple class to hold building data
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

    if (pointCount == 0) return points.first;

    for (int i = 0; i < pointCount; i++) {
      latitude += points[i].latitude;
      longitude += points[i].longitude;
    }

    return LatLng(latitude / pointCount, longitude / pointCount);
  }

  // --- Auto-scaling text marker for building labels ---
  Future<BitmapDescriptor> _createCustomMarkerBitmap(String text) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // Maximum width for marker
    const double maxWidth = 200.0;
    double fontSize = 28.0;

    TextPainter textPainter;

    // Reduce font size until it fits maxWidth
    do {
      final textSpan = TextSpan(
        text: text,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          color: AppTheme.primaryColor,
          shadows: const [
            Shadow(color: Colors.white, blurRadius: 1.0, offset: Offset(1.5, 1.5)),
            Shadow(color: Colors.white, blurRadius: 1.0, offset: Offset(-1.5, -1.5)),
          ],
        ),
      );

      textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      if (textPainter.width <= maxWidth) break;
      fontSize -= 1.0;
    } while (fontSize > 10);

    // Add padding
    const double padding = 12.0;
    final double width = textPainter.width + padding * 2;
    final double height = textPainter.height + padding * 2;

    // Draw semi-transparent background
    final Paint bgPaint = Paint()..color = Colors.white.withOpacity(0.7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, width, height), const Radius.circular(8)),
      bgPaint,
    );

    // Draw text
    final offset = Offset(padding, padding);
    textPainter.paint(canvas, offset);

    final img = await pictureRecorder.endRecording().toImage(width.toInt(), height.toInt());
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
        fillColor: AppTheme.primaryColor.withAlpha(51),
        consumeTapEvents: false,
        zIndex: 1,
      ));
    }
    return polygons;
  }

  Future<Set<Marker>> getBuildingNameLabels() async {
    await _loadBuildingData();
    Set<Marker> markers = {};

    for (var building in _buildings) {
      final BitmapDescriptor icon = await _createCustomMarkerBitmap(building.name);

      // Slightly offset label above building center
      final LatLng labelPosition = LatLng(
        building.center.latitude + 0.00006, // ~6 meters up
        building.center.longitude,
      );

      markers.add(Marker(
        markerId: MarkerId('label_${building.name}'),
        position: labelPosition,
        icon: icon,
        anchor: const Offset(0.5, 0.5),
        zIndex: 1, // lower than pins
      ));
    }
    return markers;
  }
}
