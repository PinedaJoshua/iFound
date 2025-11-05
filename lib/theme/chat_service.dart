import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ChatService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // MODIFIED: This function now *correctly* assigns Owner and Finder roles
  Future<String> getOrCreateChatRoom(String receiverId, String associatedPostId, String itemName, String itemStatus) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    List<String> userIds = [currentUserId, receiverId];
    userIds.sort();
    String chatRoomId = "${userIds.join("_")}_$associatedPostId";

    final postDoc = await _firestore.collection('posts').doc(associatedPostId).get();
    final postData = postDoc.data() ?? {};
    
    String postOwnerId;
    String postFinderId;
    String postCreatorId = postData['userId']; // The user who made the post
    String messagerId = currentUserId;        // The user sending the first message

    // This is the new, correct logic:
    if (itemStatus == 'Lost') {
      // The person who posted the "Lost" item is the Owner
      postOwnerId = postCreatorId;
      // The person messaging them is the Finder
      postFinderId = messagerId;
    } else {
      // The person who posted the "Found" item is the Finder
      postFinderId = postCreatorId; // <--- THIS WAS THE BUGGY LOGIC
      // The person messaging them (claiming it) is the Owner
      postOwnerId = messagerId;      // <--- THIS WAS THE BUGGY LOGIC
    }

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'userIds': userIds,
      'chatRoomId': chatRoomId,
      'associatedPostId': associatedPostId,
      'itemName': itemName,
      'itemStatus': itemStatus,
      'postOwnerId': postOwnerId,  // Now correctly assigned
      'postFinderId': postFinderId, // Now correctly assigned
      'confirmationState': 'none',
      'lastMessageTimestamp': FieldValue.serverTimestamp(),
      'hiddenFor': [],
    }, SetOptions(merge: true));

    return chatRoomId;
  }

  Future<void> submitConfirmation(String chatRoomId, String userRole) async {
    final docRef = _firestore.collection('chat_rooms').doc(chatRoomId);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);
      if (!docSnapshot.exists) {
        throw Exception("Chat room not found!");
      }

      final data = docSnapshot.data() as Map<String, dynamic>;
      final String currentState = data['confirmationState'];

      if (userRole == 'Finder' && currentState == 'none') {
        transaction.update(docRef, {'confirmationState': 'finder_confirmed'});
      }
      else if (userRole == 'Owner' && currentState == 'finder_confirmed') {
        transaction.update(docRef, {'confirmationState': 'recovered'});
        
        await _awardPointsAndClosePost(
          transaction: transaction,
          postId: data['associatedPostId'],
          ownerId: data['postOwnerId'],
          finderId: data['postFinderId'],
        );
      }
      else if (userRole == 'Owner' && currentState == 'none') {
        throw Exception("The Finder must confirm they have returned the item first.");
      }
    });
  }

  // MODIFIED: Point values are updated to 100 (Finder) and 25 (Owner)
  Future<void> _awardPointsAndClosePost({
    required Transaction transaction,
    required String postId,
    required String ownerId,
    required String finderId,
  }) async {
    final postRef = _firestore.collection('posts').doc(postId);
    final ownerRef = _firestore.collection('users').doc(ownerId);
    final finderRef = _firestore.collection('users').doc(finderId);

    transaction.update(postRef, {
      'status': 'recovered',
      'claimedBy': ownerId,
    });
    
    // +25 points for the Owner
    transaction.update(ownerRef, {
      'points': FieldValue.increment(25)
    });
    
    // +100 points for the Finder
    transaction.update(finderRef, {
      'points': FieldValue.increment(100)
    });
  }

  Future<void> sendMessage(String chatRoomId, String receiverId, String message) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    final String currentUserEmail = _firebaseAuth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Map<String, dynamic> newMessage = {
      'senderId': currentUserId,
      'senderEmail': currentUserEmail,
      'message': message,
      'timestamp': timestamp,
    };

    await _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .add(newMessage);

    String receiverUnreadCountField = 'unreadCount_$receiverId';

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'lastMessage': message,
      'lastMessageTimestamp': timestamp,
      'lastMessageSenderId': currentUserId,
      receiverUnreadCountField: FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
  
  Future<void> markChatAsRead(String chatRoomId) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    String currentUserUnreadCountField = 'unreadCount_$currentUserId';

    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      currentUserUnreadCountField: 0,
    }, SetOptions(merge: true));
  }
  
  Future<void> hideChatForUser(String chatRoomId) async {
    final String currentUserId = _firebaseAuth.currentUser!.uid;
    await _firestore.collection('chat_rooms').doc(chatRoomId).set({
      'hiddenFor': FieldValue.arrayUnion([currentUserId])
    }, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getMessages(String chatRoomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(chatRoomId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getChatRooms() {
    final String currentUserId = _firebaseAuth.currentUser!.uid;

    return _firestore
        .collection('chat_rooms')
        .where('userIds', arrayContains: currentUserId)
        .orderBy('lastMessageTimestamp', descending: true)
        .snapshots();
  }
  
  Stream<DocumentSnapshot> getChatRoomStream(String chatRoomId) {
    return _firestore.collection('chat_rooms').doc(chatRoomId).snapshots();
  }
  
  Stream<DocumentSnapshot> getPostStream(String postId) {
    return _firestore.collection('posts').doc(postId).snapshots();
  }

  Future<Map<String, dynamic>> getUserData(String userId) async {
    final userDoc = await _firestore.collection('users').doc(userId).get();
    final data = userDoc.data();
    if (data != null) {
      String firstName = data['firstName'] ?? '';
      String lastName = data['lastName'] ?? '';
      String name = (firstName.isNotEmpty || lastName.isNotEmpty) 
          ? '$firstName $lastName' 
          : 'iFound User';
          
      return {
        'name': name,
        'profileImageUrl': data['profileImageUrl'] ?? ''
      };
    }
    return {'name': 'iFound User', 'profileImageUrl': ''};
  }
}