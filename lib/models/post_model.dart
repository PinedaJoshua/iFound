import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String userName;
  final String itemStatus;
  final String itemCategory;
  final String itemName;
  final String description;
  // MODIFIED: 'location' is now 'locationName'
  final String locationName;
  // MODIFIED: Added coordinates for the map pin
  final GeoPoint locationCoords;
  final String imageUrl;
  final Timestamp timestamp;
  final String timeReported;
  final List<dynamic> likes;
  final int commentCount;
  final String status;

  PostModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.itemStatus,
    required this.itemCategory,
    required this.itemName,
    required this.description,
    required this.locationName, // MODIFIED
    required this.locationCoords, // MODIFIED
    required this.imageUrl,
    required this.timestamp,
    required this.timeReported,
    required this.likes,
    this.commentCount = 0,
    this.status = 'active',
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<dynamic> likesList = [];
    if (data['likes'] is List) {
      likesList = data['likes'];
    }

    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'USTP Student',
      itemStatus: data['itemStatus'] ?? 'Others',
      itemCategory: data['itemCategory'] ?? 'Others',
      itemName: data['itemName'] ?? 'Unknown Item',
      description: data['description'] ?? 'No description provided.',
      // MODIFIED: Read new location fields
      locationName: data['locationName'] ?? 'Unknown location',
      locationCoords: data['locationCoords'] ?? const GeoPoint(8.4839, 124.6493), // Default to campus center
      imageUrl: data['imageUrl'] ?? 'https://via.placeholder.com/600x400',
      timestamp: data['timestamp'] ?? Timestamp.now(),
      timeReported: data['timeReported'] ?? 'Unknown time',
      likes: likesList,
      commentCount: data['comments'] ?? 0,
      status: data['status'] ?? 'active',
    );
  }
}