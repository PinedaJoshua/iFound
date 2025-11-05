import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart'; // Import storage

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // MODIFIED (1.2): Added FirebaseStorage instance
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // --- LIKE/UNLIKE A POST ---
  Future<void> toggleLike(String postId, List<dynamic> currentLikes) async {
    final String currentUserId = _auth.currentUser!.uid;
    
    await _firestore.runTransaction((transaction) async {
      final postRef = _firestore.collection('posts').doc(postId);
      
      if (currentLikes.contains(currentUserId)) {
        transaction.update(postRef, {
          'likes': FieldValue.arrayRemove([currentUserId])
        });
      } else {
        transaction.update(postRef, {
          'likes': FieldValue.arrayUnion([currentUserId])
        });
      }
    });
  }

  // --- ADD A COMMENT ---
  Future<void> addComment(String postId, String commentText) async {
    final String currentUserId = _auth.currentUser!.uid;
    final userDoc = await _firestore.collection('users').doc(currentUserId).get();
    final userData = userDoc.data() ?? {};
    final userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
    
    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'commentText': commentText,
      'userName': userName.isEmpty ? 'Anonymous' : userName,
      'userId': currentUserId,
      'timestamp': Timestamp.now(),
    });
  }

  // --- GET COMMENTS ---
  Stream<QuerySnapshot> getComments(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // --- MODIFIED (1.2): ADDED DELETE POST FUNCTION ---
  Future<void> deletePost(String postId, String imageUrl) async {
    try {
      // 1. Delete the post document from Firestore
      await _firestore.collection('posts').doc(postId).delete();

      // 2. Delete the associated image from Firebase Storage (if it exists)
      if (imageUrl.isNotEmpty) {
        // Create a reference from the full URL
        Reference photoRef = _storage.refFromURL(imageUrl);
        await photoRef.delete();
      }
      
      // We could also delete comments, but Firestore rules can handle that.
    } catch (e) {
      // Handle errors, e.g., permission denied
      print('Error deleting post: $e');
      rethrow;
    }
  }
}