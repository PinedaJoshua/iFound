import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/services/map_service.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

// MODIFIED: Light/White Map Style JSON to hide POIs and features
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
    "elementType": "labels",
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
  
  // Tighter center and zoom level for the campus view
  static const CameraPosition _ustpCampus = CameraPosition(
    target: LatLng(8.4860, 124.6575),
    zoom: 18.5,
  );

  // Tighter bounds to lock the map area
  static final LatLngBounds _ustpBounds = LatLngBounds(
    southwest: const LatLng(8.4850, 124.6545),
    northeast: const LatLng(8.4880, 124.6600),
  );

  Set<Marker> _markers = {};
  Set<Polygon> _polygons = {};
  Set<Marker> _buildingLabels = {}; // Holds permanent labels from GeoJSON
  String _currentFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadMapData();
  }

  // Helper to initialize the map style
  void _onMapCreated(GoogleMapController controller) {
    _controller.complete(controller);
    controller.setMapStyle(_mapStyle); // Apply light style
  }

  // This function loads polygons AND building labels
  Future<void> _loadMapData() async {
    try {
      final polygons = await _mapService.getBuildingPolygons();
      final labels = await _mapService.getBuildingNameMarkers(); 

      if (mounted) {
        setState(() {
          _polygons = polygons;
          _buildingLabels = labels; // Save the permanent labels
        });
      }
    } catch (e) {
      print("Error loading polygons or labels: $e");
    }
    
    _loadPostsAndMarkers();
  }

  // This function loads the pins (markers) based on the filter
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

      Set<Marker> postMarkers = {}; // Temporary set for filtered pins
      
      for (var doc in snapshot.docs) {
        final post = PostModel.fromFirestore(doc);
        
        final LatLng coordinates = LatLng(
          post.locationCoords.latitude,
          post.locationCoords.longitude,
        );
        
        final bool isLost = post.itemStatus == 'Lost';
        final BitmapDescriptor icon = isLost
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed) 
            : BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen); 

        postMarkers.add(
          Marker(
            markerId: MarkerId(post.id),
            position: coordinates,
            infoWindow: InfoWindow(
              title: post.itemName,
              snippet: post.locationName, 
              onTap: () => _showPostDetails(context, post), 
            ),
            icon: icon,
            zIndex: 50, // Pins on top of labels
          ),
        );
      }

      if (mounted) {
        setState(() {
          // MODIFIED (2): This is the crucial step: start with building labels, then add post markers
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
  
  void _changeFilter(String filter) {
    if (_currentFilter != filter) {
      setState(() {
        _currentFilter = filter;
      });
      _loadPostsAndMarkers(); // Reload markers with the new filter
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
      // MODIFIED (Layout Fix): Use SingleChildScrollView for the body
      body: SingleChildScrollView(
        child: Column(
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
            // MODIFIED (Layout Fix): Fixed height for the map container
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.50, // Map takes 50% of screen height
              child: Stack(
                children: [
                  GoogleMap(
                    mapType: MapType.normal,
                    initialCameraPosition: _ustpCampus, // Starts at the correct center
                    onMapCreated: _onMapCreated, // Applies light style
                    
                    markers: _markers, // Displays pins AND custom labels
                    polygons: _polygons, // Draws building outlines
                    
                    // MODIFIED (2): Controls are re-enabled and locked to bounds
                    minMaxZoomPreference: const MinMaxZoomPreference(16, 19), 
                    cameraTargetBounds: CameraTargetBounds(_ustpBounds), 
                    scrollGesturesEnabled: true, 
                    zoomGesturesEnabled: true,
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
            // Recent Activity is now inside the scrollable view below the fixed map
            _buildRecentActivitySection(context),
          ],
        ),
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
          padding: const EdgeInsets.only(left: 16.0, top: 10.0),
          child: Text(
            'Recent Map Activity',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.darkTextColor, 
              fontSize: 20
            ),
          ),
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('posts')
              .where('status', isEqualTo: 'active')
              .orderBy('timestamp', descending: true)
              .limit(3)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ));
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
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(), // Important: allows parent scroll view to handle scroll
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
      ],
    );
  }
}