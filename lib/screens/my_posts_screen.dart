import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/widgets/post_card.dart'; // Import the reusable PostCard

class MyPostsScreen extends StatefulWidget {
  const MyPostsScreen({super.key});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _postsStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream only if the user is logged in
    if (_auth.currentUser != null) {
      _postsStream = FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _auth.currentUser!.uid) // Filter by user ID
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // Create an empty stream if user is null
      _postsStream = Stream.empty(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Posts')),
        body: const Center(child: Text('You are not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _postsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have not created any posts yet.',
                style: TextStyle(color: AppTheme.lightTextColor, fontSize: 16),
              ),
            );
          }

          final posts = snapshot.data!.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              // Use the reusable PostCard widget
              return PostCard(post: post);
            },
          );
        },
      ),
    );
  }
}