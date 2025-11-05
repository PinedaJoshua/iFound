import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/onboarding_screen.dart';
import 'package:flutter_application_1/theme/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkOnboardingStatus();
  }

  Future<void> _checkOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // Check if 'showOnboarding' is true. If it's null (never set), default to true.
    final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

    // Wait for 3 seconds to show the splash screen
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      // Navigate to the correct screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) =>
              showOnboarding ? const OnboardingScreen() : const AuthGate(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // This matches your 'Sign In.jpg' splash screen
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Assuming 'iFound Logo.png' is in 'assets/images/'
            Image.asset(
              'assets/images/iFound Logo.png',
              width: 5000 // Adjust size as needed
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}