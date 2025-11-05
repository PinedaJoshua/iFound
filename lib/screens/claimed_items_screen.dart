import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

class ClaimedItemsScreen extends StatefulWidget {
  const ClaimedItemsScreen({super.key});

  @override
  State<ClaimedItemsScreen> createState() => _ClaimedItemsScreenState();
}

class _ClaimedItemsScreenState extends State<ClaimedItemsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _claimedStream;

  @override
  void initState() {
    super.initState();
    // Initialize the stream only if the user is logged in
    if (_auth.currentUser != null) {
      _claimedStream = FirebaseFirestore.instance
          .collection('posts')
          .where('claimedBy', isEqualTo: _auth.currentUser!.uid) // Filter by who claimed
          .orderBy('timestamp', descending: true)
          .snapshots();
    } else {
      // Create an empty stream if user is null
      _claimedStream = Stream.empty(); 
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Claimed Items')),
        body: const Center(child: Text('You are not logged in.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Claimed Items'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _claimedStream,
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
                'You have not claimed any items yet.',
                style: TextStyle(color: AppTheme.lightTextColor, fontSize: 16),
              ),
            );
          }

          final posts = snapshot.data!.docs
              .map((doc) => PostModel.fromFirestore(doc))
              .toList();

          // We'll use a simple ListTile instead of the full PostCard for this view
          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: BorderSide(color: Colors.grey.shade200),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: const Icon(Icons.check, color: Colors.green),
                  ),
                  title: Text(
                    post.itemName,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Found by: ${post.userName}'),
                  trailing: Text(
                    post.timeReported.split(' at ')[0], // Show just the date
                    style: const TextStyle(color: AppTheme.lightTextColor, fontSize: 12),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}