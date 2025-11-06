import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart'; // <-- THIS LINE IS CORRECT
import 'package:firebase_auth/firebase_auth.dart';


class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- SIGN IN WITH GOOGLE ---
  Future<UserCredential> signInWithGoogle() async {
    try {
      // 2a. Begin the Google Sign-In flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // The user canceled the sign-in
        throw Exception('Google Sign-In canceled');
      }

      // 2b. Obtain authentication details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 2c. Create a new Firebase credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 2d. Sign in to Firebase with the credential
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);

      // 2e. Check if this is a new user
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        // If it's a new user, create their document in Firestore
        String uid = userCredential.user!.uid;
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': googleUser.email,
          'firstName': googleUser.displayName?.split(' ').first ?? '',
          'lastName': googleUser.displayName?.split(' ').last ?? '',
          'profileImageUrl': googleUser.photoUrl,
          'points': 0,
          'birthDate': '', 
          'phone': '',
        });
      }

      return userCredential;

    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    } catch (e) {
      throw Exception(e.toString());
    }
  }

  // --- SIGN IN WITH EMAIL/PASSWORD ---
  Future<UserCredential> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // --- SIGN UP WITH EMAIL/PASSWORD ---
  Future<UserCredential> signUpWithEmailPassword(
    String email,
    String password,
    String firstName,
    String lastName,
    String birthDate,
    String phone,
  ) async {
    try {
      UserCredential userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'birthDate': birthDate,
        'phone': phone,
        'points': 0,
        'profileImageUrl': '',
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }

  // --- SIGN OUT ---
  Future<void> signOut() async {
    // Also sign out from Google
    await GoogleSignIn().signOut();
    await _firebaseAuth.signOut();
  }

  // --- Get current user ---
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }
  // ADD THIS NEW METHOD
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message);
    }
  }
}