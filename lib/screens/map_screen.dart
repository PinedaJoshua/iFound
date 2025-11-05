import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math; // <-- MODIFIED (2.1): Added for random pin offsets
import 'dart:ui' as ui;
import 'dart:typed_data';

// MODIFIED (Issue 1): Light/White Map Style JSON to hide POIs and features
const String _mapStyle = '''
[
  {
    "featureType": "poi",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "transit",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.icon",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "featureType": "road.arterial",
    "elementType": "labels.text",
    "stylers": [
      { "visibility": "off" }
    ]
  },
  {
    "elementType": "geometry.fill",
    "stylers": [
      { "color": "#F9F9F9" }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      { "color": "#FFFFFF" }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#444444" }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [
      { "color": "#FFFFFF" }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      { "color": "#BDBDBD" }
    ]
  }
]
''';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final MapService _mapService = MapService();
  
  static const CameraPosition _ustpCampus = CameraPosition(
    target: LatLng(8.4860, 124.6575),
    zoom: 18.5,
  );

  static final LatLngBounds _ustpBounds = LatLngBounds(
    southwest: const LatLng(8.4850, 124.6545),
    northeast: const LatLng(8.4880, 124.6600),
  );

  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Marker> _buildingLabels = {};
  String _currentFilter = 'All';

  // MODIFIED (2.2): Storing the small pin icons to avoid rebuilding
  BitmapDescriptor _lostPinIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _foundPinIcon = BitmapDescriptor.defaultMarker;

  @override
  void initState() {
    super.initState();
    _loadCustomPinIcons(); // Load custom icons first
    _loadMapData();
  }

  // MODIFIED (2.2): Load the custom small pins on init
  Future<void> _loadCustomPinIcons() async {
    _lostPinIcon = await _createPinBitmap(Colors.red);
    _foundPinIcon = await _createPinBitmap(Colors.green);
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    controller.setMapStyle(_mapStyle); // Apply light style
  }

  Future<void> _loadMapData() async {
    try {
      final polygons = await _mapService.getBuildingPolygons();
      final labels = await _mapService.getBuildingNameLabels(); 

      if (mounted) {
        setState(() {
          _polygons = polygons;
          _buildingLabels = labels;
        });
      }
    } catch (e) {
      print("Error loading polygons or labels: $e");
    }
    
    _loadPostsAndMarkers();
  }

  // MODIFIED (2.1, 2.2): This function now "jitters" pins
  Future<void> _loadPostsAndMarkers() async {
    Query query = FirebaseFirestore.instance
        .collection('posts')
        .where('status', isEqualTo: 'active');

    if (_currentFilter != 'All') {
      query = query.where('itemStatus', isEqualTo: _currentFilter);
    }
    
    try {
      query = query.orderBy('timestamp', descending: true);
      final snapshot = await query.get();

      Set<Marker> postMarkers = {};
      
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        
        // MODIFIED (2.1): Add a small random offset to see overlapping pins
        final LatLng originalCoords = LatLng(
          post.locationCoords.latitude,
          post.locationCoords.longitude,
        );
        final LatLng coordinates = _getSlightlyRandomizedCoord(originalCoords);
        
        final bool isLost = post.itemStatus == 'Lost';
        
        // MODIFIED (2.2): Use the smaller custom pin icons
        final BitmapDescriptor icon = isLost ? _lostPinIcon : _foundPinIcon;

        postMarkers.add(
          Marker(
            markerId: MarkerId(post.id),
            position: coordinates,
            infoWindow: InfoWindow(
              title: post.itemName,
              snippet: "Click to see details", // Snippet for the post pin
              onTap: () => _showPostDetails(context, post), 
            ),
            icon: icon,
            zIndex: 50, // Pins on top of labels
          ),
        );
      }

      if (mounted) {
        setState(() {
          _markers = {}; 
          _markers.addAll(_buildingLabels); // Add permanent GeoJSON labels
          _markers.addAll(postMarkers);     // Add filtered Lost/Found pins
        });
      }
    } catch (e) {
      print("Error loading markers: $e");
      if (e.toString().contains('requires an index')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Firestore index required. Check debug console for a link.')),
        );
      }
    }
  }
  
  // MODIFIED (2.2): Helper to create smaller, circular pins
  Future<BitmapDescriptor> _createPinBitmap(Color color) async {
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    final Paint paint = Paint()..color = color;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
      
    const double radius = 12.0; // Small pin size

    canvas.drawCircle(
      const Offset(radius, radius),
      radius,
      paint,
    );
    canvas.drawCircle(
      const Offset(radius, radius),
      radius,
      borderPaint,
    );

    final img = await pictureRecorder.endRecording().toImage(
          (radius * 2).toInt(),
          (radius * 2).toInt(),
        );
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(data!.buffer.asUint8List());
  }

  // MODIFIED (2.1): Helper to "jitter" pins so they don't stack perfectly
  LatLng _getSlightlyRandomizedCoord(LatLng original) {
    final double offset = 0.00003; // Very small offset
    final double lat = original.latitude + (math.Random().nextDouble() * offset * 2) - offset;
    final double lng = original.longitude + (math.Random().nextDouble() * offset * 2) - offset;
    return LatLng(lat, lng);
  }
  
  void _changeFilter(String filter) {
    if (_currentFilter != filter) {
      setState(() {
        _currentFilter = filter;
      });
      _loadPostsAndMarkers();
    }
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${post.itemStatus} Item: ${post.itemName}'),
        content: Text('Location: ${post.locationName}\nDescription: ${post.description}'),
        actions: [
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
      appBar: _buildAppBar(),
      // MODIFIED (Layout Fix): Use Column instead of SingleChildScrollView
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildFilterButton('All', 'All'),
                _buildFilterButton('Lost', 'Lost'),
                _buildFilterButton('Found', 'Found'),
              ],
            ),
          ),
          // MODIFIED (Layout Fix): Use Expanded for the map
          Expanded(
            flex: 3, // Give the map 3/5 of the remaining space
            child: Stack(
              children: [
                GoogleMap(
                  mapType: MapType.normal,
                  initialCameraPosition: _ustpCampus,
                  onMapCreated: _onMapCreated, // Applies light style
                  
                  markers: _markers,
                  polygons: _polygons,
                  
                  // MODIFIED (Issue 2): Controls are re-enabled and locked to bounds
                  minMaxZoomPreference: const MinMaxZoomPreference(16, 19), 
                  cameraTargetBounds: CameraTargetBounds(_ustpBounds), 
                  scrollGesturesEnabled: true, // Re-enable panning
                  zoomGesturesEnabled: true, // Re-enable zooming
                  tiltGesturesEnabled: false, 
                  rotateGesturesEnabled: false, 
                ),
                Positioned(
                  bottom: 10,
                  left: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [CircleAvatar(radius: 5, backgroundColor: Colors.red), SizedBox(width: 8), Text('Lost Items', style: TextStyle(fontSize: 14))]),
                        Row(children: [CircleAvatar(radius: 5, backgroundColor: Colors.green), SizedBox(width: 8), Text('Found Items', style: TextStyle(fontSize: 14))]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // MODIFIED (Layout Fix): Use Expanded for the scrollable list
          Expanded(
            flex: 2, // Give the list 2/5 of the remaining space
            child: _buildRecentActivitySection(context),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Campus Map'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(20.0),
        child: Text(
          'USTP Lost & Found Locations',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.lightTextColor,
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: AppTheme.primaryColor),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String filterType) {
    final bool isSelected = _currentFilter == filterType;
    return ElevatedButton(
      onPressed: () => _changeFilter(filterType),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? AppTheme.secondaryColor : Colors.grey.shade200,
        foregroundColor: isSelected ? AppTheme.primaryColor : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        elevation: 0,
      ),
      child: Text(label),
    );
  }
  
  Widget _buildRecentActivitySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 0.0),
          child: Text(
            'Recent Map Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.darkTextColor, 
              fontSize: 20
            ),
          ),
        ),
        // MODIFIED (Layout Fix): Make the list scrollable
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('posts')
                .where('status', isEqualTo: 'active')
                .orderBy('timestamp', descending: true)
                .limit(3) // This limit is good, but for a full scroll, you'd remove it
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}\n\n(Click the link in the console to create the new Firestore Index)'));
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('No recent activity to show.'),
                );
              }

              final recentPosts = snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

              return ListView.builder(
                // MODIFIED (Layout Fix): No longer needs shrinkWrap or NeverScrollableScrollPhysics
                itemCount: recentPosts.length,
                itemBuilder: (context, index) {
                  final post = recentPosts[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: post.itemStatus == 'Lost' ? Colors.red.shade600 : Colors.green.shade600,
                      child: Icon(post.itemStatus == 'Lost' ? Icons.location_off : Icons.check_circle, color: Colors.white, size: 20),
                    ),
                    title: Text(post.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${post.locationName} - ${post.timeReported}'), 
                    trailing: TextButton(
                      onPressed: () => _showPostDetails(context, post),
                      child: const Text('View', style: TextStyle(color: AppTheme.primaryColor)),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}