import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. A model to hold our achievement data
class Achievement {
  final String title;
  final String description;
  final int pointsRequired;
  final String iconName; // e.g., "Getting Started.png"

  Achievement({
    required this.title,
    required this.description,
    required this.pointsRequired,
    required this.iconName,
  });
}

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  int _currentUserPoints = 0;
  bool _isLoading = true;

  // 2. Define all achievements based on your list
  final List<Achievement> _allAchievements = [
    Achievement(
      title: 'Getting Started',
      description: 'Earn this after collecting your first 50 points — your iFound journey begins!',
      pointsRequired: 50,
      iconName: 'Getting Started.png',
    ),
    Achievement(
      title: 'Rising Finder',
      description: 'Reach 150 points by helping others and posting found items.',
      pointsRequired: 150,
      iconName: 'Rising Finder.png',
    ),
    Achievement(
      title: 'Trusted Helper',
      description: 'Achieve 300 points through consistent and verified returns.',
      pointsRequired: 300,
      iconName: 'Trusted Helper.png',
    ),
    Achievement(
      title: 'Sharp Seeker',
      description: 'Earn 500 points by quickly identifying and confirming lost items.',
      pointsRequired: 500,
      iconName: 'Sharp Seeker.png',
    ),
    Achievement(
      title: 'Active Responder',
      description: 'Hit 700 points by engaging with multiple users through messages and confirmations.',
      pointsRequired: 700,
      iconName: 'Active Responder.png',
    ),
    Achievement(
      title: 'Helping Hand',
      description: 'Reach 1,000 points — proof of your dedication to helping your campus community.',
      pointsRequired: 1000,
      iconName: 'Helping Hand.png',
    ),
    Achievement(
      title: 'Campus Guardian',
      description: 'Collect 1,500 points by frequently using the map and assisting with item recoveries.',
      pointsRequired: 1500,
      iconName: 'Campus Guardian.png',
    ),
    Achievement(
      title: 'Good Samaritan',
      description: 'Earn 2,000 points — recognized for honesty and consistent contributions.',
      pointsRequired: 2000,
      iconName: 'Good Samaritan.png',
    ),
    Achievement(
      title: 'Community Hero',
      description: 'Achieve 3,000 points — a symbol of your impact in making iFound successful.',
      pointsRequired: 3000,
      iconName: 'Community Hero.png',
    ),
    Achievement(
      title: 'Legendary Finder',
      description: 'Reach 5,000 points — the ultimate recognition for being the top finder on iFound!',
      pointsRequired: 5000,
      iconName: 'Legendary Finder.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadUserPoints();
  }

  // 3. Fetch the user's current points from Firestore
  Future<void> _loadUserPoints() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _isLoading = false; });
      return;
    }
    
    try {
      final docSnap = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (docSnap.exists && docSnap.data() != null) {
        setState(() {
          _currentUserPoints = docSnap.data()!['points'] ?? 0;
          _isLoading = false;
        });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _isLoading = false; });
      print("Error loading points: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _allAchievements.length,
              itemBuilder: (context, index) {
                final achievement = _allAchievements[index];
                // 4. Check if the user has unlocked this achievement
                final bool isUnlocked = _currentUserPoints >= achievement.pointsRequired;
                return _buildAchievementTile(achievement, isUnlocked);
              },
            ),
    );
  }

  // 5. Helper widget to build each list tile
  Widget _buildAchievementTile(Achievement achievement, bool isUnlocked) {
    // This widget will make the icon gray if it's locked
    Widget icon = Image.asset(
      'assets/images/${achievement.iconName}',
      width: 60,
      height: 60,
      // Handle image asset errors gracefully
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: 60,
          height: 60,
          color: Colors.grey.shade200,
          child: const Icon(Icons.error_outline, color: Colors.red),
        );
      },
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      // Use Opacity to fade locked achievements
      child: Opacity(
        opacity: isUnlocked ? 1.0 : 0.4,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              isUnlocked
                  ? icon // Full color icon
                  : ColorFiltered( // Grayed-out icon
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: icon,
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      achievement.title,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isUnlocked ? AppTheme.darkTextColor : AppTheme.lightTextColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isUnlocked
                          ? achievement.description
                          : 'Locked: Reach ${achievement.pointsRequired} points',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.lightTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}