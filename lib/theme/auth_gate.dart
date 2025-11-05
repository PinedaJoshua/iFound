import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/login_screen.dart';
import 'package:flutter_application_1/screens/main_navigator.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // User is not logged in
          if (!snapshot.hasData) {
            // We'll replace this with the Splash/Onboarding later
            return const LoginScreen();
          }

          // User is logged in
          return const MainNavigator();
        },
      ),
    );
  }
}