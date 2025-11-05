import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

// Helper class (no changes)
class LeaderboardUser {
  final String uid;
  final String name;
  final int points;
  final int rank;
  final String profileImageUrl;

  LeaderboardUser({
    required this.uid,
    required this.name,
    required this.points,
    required this.rank,
    this.profileImageUrl = '',
  });

  factory LeaderboardUser.fromFirestore(DocumentSnapshot doc, int rank) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    String firstName = data['firstName'] ?? '';
    String lastName = data['lastName'] ?? '';
    String name = firstName.isNotEmpty || lastName.isNotEmpty 
        ? '$firstName $lastName' 
        : 'Anonymous User';

    return LeaderboardUser(
      uid: doc.id,
      name: name,
      points: data['points'] ?? 0,
      rank: rank,
      profileImageUrl: data['profileImageUrl'] ?? '',
    );
  }
}

// FIX 4.1: Converted to a StatefulWidget
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  // FIX 4.1: Added state for filter
  String _selectedFilter = 'Today';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTimeFilterChips(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .orderBy('points', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No students on the leaderboard yet.'));
                }

                final users = snapshot.data!.docs.asMap().entries.map((entry) {
                  return LeaderboardUser.fromFirestore(entry.value, entry.key + 1);
                }).toList();

                final topUsers = users.take(3).toList();
                final restOfUsers = users.skip(3).toList();
                
                return ListView(
                  children: [
                    _buildPodium(context, topUsers),
                    const SizedBox(height: 20),
                    ...restOfUsers.map((user) {
                      return _buildLeaderboardTile(context, user);
                    }).toList(),
                    const SizedBox(height: 80),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Leaderboard'),
      actions: [
        IconButton(
          icon: const Icon(Icons.share, color: AppTheme.primaryColor),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Share functionality not implemented.')),
            );
          },
        ),
      ],
    );
  }

  // Time Filter Chips (Today/Week/Month)
  Widget _buildTimeFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildFilterChip('Today', _selectedFilter == 'Today'),
          _buildFilterChip('Week', _selectedFilter == 'Week'),
          _buildFilterChip('Month', _selectedFilter == 'Month'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: GestureDetector(
        // FIX 4.1: Added onTap logic
        onTap: () {
          setState(() {
            _selectedFilter = label;
            // TODO: Implement actual filtering logic based on the new label
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor : AppTheme.lightTextColor,
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              color: isSelected ? Colors.white : AppTheme.primaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ... (Podium and List Tile methods remain unchanged) ...
  // (Paste _buildPodium and _buildLeaderboardTile here from the previous step)
  Widget _buildPodium(BuildContext context, List<LeaderboardUser> topUsers) {
    Widget buildSpot(int rank, LeaderboardUser? user) {
      final double size = rank == 1 ? 130 : 100;
      final Color color = rank == 1 ? AppTheme.secondaryColor : (rank == 2 ? Colors.grey.shade400 : Colors.deepOrange.shade400);

      return Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (rank == 1) 
            const Icon(Icons.star, color: AppTheme.secondaryColor, size: 40),
          if (rank == 1) 
            const SizedBox(height: 4),
          Container(
            height: size,
            width: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: rank == 1 ? 5 : 3),
            ),
            child: CircleAvatar(
              radius: size / 2,
              backgroundColor: color.withOpacity(0.5),
              child: Stack(
                children: [
                  Center(
                    child: Icon(Icons.person, size: size * 0.5, color: Colors.white),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$rank',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            user?.name.split(' ').first ?? '---',
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            user != null ? '${user.points} pts.' : '0 pts.',
            style: const TextStyle(color: AppTheme.lightTextColor),
          ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          buildSpot(2, topUsers.length > 1 ? topUsers[1] : null),
          buildSpot(1, topUsers.isNotEmpty ? topUsers[0] : null),
          buildSpot(3, topUsers.length > 2 ? topUsers[2] : null),
        ],
      ),
    );
  }

  Widget _buildLeaderboardTile(BuildContext context, LeaderboardUser user) {
    final bool rankUp = user.rank % 2 == 0; 
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '${user.rank}',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: AppTheme.darkTextColor,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Icon(
            rankUp ? Icons.arrow_upward : Icons.arrow_downward,
            size: 16,
            color: rankUp ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          const CircleAvatar(
            radius: 18,
            child: Icon(Icons.person, size: 20, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              user.name,
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${user.points} pts.',
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}