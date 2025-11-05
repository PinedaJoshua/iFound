import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/create_post_screen.dart';
import 'package:flutter_application_1/screens/home_screen.dart';
import 'package:flutter_application_1/screens/leaderboard_screen.dart';
import 'package:flutter_application_1/screens/map_screen.dart';
import 'package:flutter_application_1/screens/profile_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';

class MainNavigator extends StatefulWidget {
  const MainNavigator({super.key});

  @override
  State<MainNavigator> createState() => _MainNavigatorState();
}

class _MainNavigatorState extends State<MainNavigator> {
  int _selectedIndex = 0; // 0 = Home

  final List<Widget> _pages = [
    const HomeScreen(),
    const MapScreen(),
    const LeaderboardScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _onCreatePostTapped() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreatePostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      // MODIFIED (2.2): Removed the FloatingActionButton from here
      
      // Bottom Navigation Bar
      bottomNavigationBar: BottomAppBar(
        // MODIFIED (2.2): Removed shape and notchMargin
        color: Colors.white,
        child: SizedBox(
          height: 60,
          child: Row(
            // MODIFIED (2.2): Changed to spaceEvenly for 5 items
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildNavItem(icon: Icons.home, text: 'Home', index: 0),
              _buildNavItem(icon: Icons.map, text: 'Map', index: 1),
              
              // MODIFIED (2.1, 2.2, 2.3): Added circular blue button
              MaterialButton(
                onPressed: _onCreatePostTapped,
                color: AppTheme.primaryColor,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
                child: const Icon(Icons.add, color: Colors.white, size: 30),
              ),
              
              _buildNavItem(
                  icon: Icons.leaderboard, text: 'Leaderboard', index: 2),
              _buildNavItem(icon: Icons.person, text: 'Profile', index: 3),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget to build each nav item
  Widget _buildNavItem(
      {required IconData icon, required String text, required int index}) {
    final bool isSelected = (_selectedIndex == index);
    
    // MODIFIED (2.4): Active color is YELLOW
    final Color color =
        isSelected ? AppTheme.secondaryColor : AppTheme.lightTextColor;
    
    final double iconSize = isSelected ? 30 : 28;

    return MaterialButton(
      minWidth: 40,
      onPressed: () => _onItemTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: iconSize),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}