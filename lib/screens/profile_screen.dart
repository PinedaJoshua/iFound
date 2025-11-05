import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_application_1/screens/my_posts_screen.dart';
import 'package:flutter_application_1/screens/notification_screen.dart';
import 'package:flutter_application_1/screens/achievements_screen.dart';
import 'package:flutter_application_1/screens/account_screen.dart';
import 'package:flutter_application_1/theme/app_theme.dart';
import 'package:flutter_application_1/theme/auth_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  User? _currentUser;
  Map<String, dynamic>? _userData;
  bool _isLoading = true;
  bool _isUploading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() { 
      _isLoading = true; 
      _errorMessage = '';
    });
    
    try {
      _currentUser = _auth.currentUser;
      if (_currentUser != null) {
        final docSnap = await _firestore.collection('users').doc(_currentUser!.uid).get();
        if (docSnap.exists) {
          setState(() {
            _userData = docSnap.data();
          });
        } else {
          setState(() {
            _errorMessage = 'User data not found.';
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Not logged in.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading data: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signOut() async {
    final authService = AuthService();
    await authService.signOut();
  }

  Future<void> _pickAndUploadImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() { _isUploading = true; });

    try {
      File imageFile = File(pickedFile.path);
      String filePath = 'profile_pictures/${_currentUser!.uid}/${pickedFile.name}';
      UploadTask uploadTask = _storage.ref().child(filePath).putFile(imageFile);

      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();

      await _firestore.collection('users').doc(_currentUser!.uid).update({
        'profileImageUrl': downloadUrl,
      });

      _loadUserData();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      setState(() { _isUploading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_errorMessage.isNotEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(_errorMessage, textAlign: TextAlign.center),
          ),
        ),
      );
    }
    
    String fullName = _userData?['firstName'] != null
        ? '${_userData!['firstName']} ${_userData!['lastName']}'
        : 'iFound User';
    String email = _userData?['email'] ?? 'No Email';
    int points = _userData?['points'] ?? 0;
    String profileImageUrl = _userData?['profileImageUrl'] ?? '';

    // FIX 3.1: Use the user's name from Firebase, not a hardcoded one
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.primaryColor),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: profileImageUrl.isNotEmpty
                      ? NetworkImage(profileImageUrl)
                      : null,
                  child: profileImageUrl.isEmpty
                      ? const Icon(Icons.person, size: 60, color: AppTheme.lightTextColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Material(
                    color: AppTheme.primaryColor,
                    shape: const CircleBorder(),
                    child: InkWell(
                      onTap: _pickAndUploadImage,
                      customBorder: const CircleBorder(),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _isUploading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.edit, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              fullName, // Use the dynamic name
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: AppTheme.darkTextColor, // Match Figma
              ),
            ),
            const SizedBox(height: 4),
            Text(
              email, // Use the dynamic email
              style: const TextStyle(fontSize: 16, color: AppTheme.lightTextColor),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.secondaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppTheme.secondaryColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star, color: AppTheme.secondaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '$points Points', // Use dynamic points
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildProfileMenuItem(
              icon: Icons.person_outline,
              title: 'Account',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AccountScreen()),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.list_alt,
              title: 'My Posts',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const MyPostsScreen()),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.emoji_events_outlined,
              title: 'Achievements',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AchievementsScreen()),
                );
              },
            ),
            _buildProfileMenuItem(
              icon: Icons.notifications_none,
              title: 'Notifications',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            
            // MODIFIED: Removed the SizedBox to align Logout button
            
            _buildProfileMenuItem(
              icon: Icons.logout,
              title: 'Logout',
              onTap: _signOut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    // MODIFIED: Matched Figma styling
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      elevation: 0,
      color: Colors.grey.shade50, // Light background color
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppTheme.primaryColor),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.lightTextColor),
        onTap: onTap,
      ),
    );
  }
}