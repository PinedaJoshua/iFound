import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/post_model.dart';
import 'package:flutter_application_1/screens/chat_list_screen.dart';
import 'package:flutter_application_1/screens/notification_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/widgets/post_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Lost', 'Found', 'Gadgets', 'Wallets', 'IDs', 'Others'];

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/images/iFound Logo.png',
            height: 35, 
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const ChatListScreen()),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppTheme.primaryColor),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const NotificationsScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(30.0),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const TextField(
                decoration: InputDecoration(
                  hintText: 'Search lost or found items',
                  hintStyle: TextStyle(color: AppTheme.lightTextColor),
                  prefixIcon: Icon(Icons.search, color: AppTheme.lightTextColor),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                  isDense: true,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(24.0),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: IconButton(
              icon: const Icon(Icons.filter_list, color: AppTheme.primaryColor),
              onPressed: () {
                 ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filter modal not yet implemented.')),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          itemBuilder: (context, index) {
            final filter = _filters[index];
            final bool isSelected = _selectedFilter == filter;
            
            return Padding(
              padding: EdgeInsets.only(
                left: index == 0 ? 16.0 : 8.0, 
                right: index == _filters.length - 1 ? 16.0 : 0,
              ),
              child: ChoiceChip(
                label: Text(filter),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                backgroundColor: Colors.grey.shade200,
                selectedColor: AppTheme.primaryColor,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : AppTheme.darkTextColor,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isSelected
                      ? BorderSide.none
                      : BorderSide(color: Colors.grey.shade300),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: PostFeed(
              selectedFilter: _selectedFilter,
            ),
          ),
        ],
      ),
    );
  }
}

// --- Post Feed ---
class PostFeed extends StatelessWidget {
  final String selectedFilter;
  const PostFeed({super.key, required this.selectedFilter});

  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('posts');

    // MODIFIED: Add filter to only show 'active' posts
    query = query.where('status', isEqualTo: 'active');

    if (selectedFilter != 'All') {
      if (selectedFilter == 'Lost' || selectedFilter == 'Found') {
        query = query.where('itemStatus', isEqualTo: selectedFilter);
      } else {
        query = query.where('itemCategory', isEqualTo: selectedFilter);
      }
    }
    
    query = query.orderBy('timestamp', descending: true);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}\n\n(Have you clicked the link in the console to create the Firestore Index?)'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No items found for this filter.',
                style: TextStyle(color: AppTheme.lightTextColor)),
          );
        }

        final posts =
            snapshot.data!.docs.map((doc) => PostModel.fromFirestore(doc)).toList();

        return ListView.builder(
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index];
            return PostCard(post: post);
          },
        );
      },
    );
  }
}