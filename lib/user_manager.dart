import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_model.dart';

class UserManager {
  static const String _currentUserKey = 'currentUser';
  static AppUser? _currentUser;

  /// Initialize the UserManager by loading the current user from local storage.
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserJson = prefs.getString(_currentUserKey);

    if (currentUserJson != null) {
      final userData = jsonDecode(currentUserJson);
      _currentUser = AppUser.fromMap(userData);
    }
  }

  // User Registration
  /// Register a new user with Firebase Authentication and Firestore.
  static Future<bool> registerUser({
    required String name,
    required String matricID,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? additionalInfo, // Added parameter
  }) async {
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user data
      final userData = {
        'uid': userCredential.user!.uid,
        'name': name,
        'matricID': matricID,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        if (additionalInfo != null) ...additionalInfo, // Merge additionalInfo
      };

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

      // Update local user model
      _currentUser = AppUser(
        id: userCredential.user!.uid,
        name: name,
        matricID: matricID,
        email: email,
        role: role,
        additionalInfo: additionalInfo,
      );

      await _saveCurrentUser();
      return true;
    } catch (e) {
      debugPrint('Error registering user: $e');
      rethrow; // Let the calling method handle the error
    }
  }

  // User Authentication

  /// Login a user using Firebase Authentication
  static Future<bool> loginUser(
      String matricID, String password, String selectedRole) async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('matricID', isEqualTo: matricID)
          .where('role', isEqualTo: selectedRole)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('User not found');
        return false;
      }

      var userData = querySnapshot.docs.first;

      _currentUser = AppUser.fromMap(userData.data() as Map<String, dynamic>);
      await _saveCurrentUser();
      return true;
    } catch (e) {
      print('Error logging in user: $e');
      return false;
    }
  }

  // User Management

  /// Logout the current user.
  static Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserKey);
    await FirebaseAuth.instance.signOut();
  }

  /// Update the current user's profile in Firestore and locally.
  static Future<void> updateUserProfile(String matricId, {
    required String name,
    String? course,
    String? semester,
    Map<String, dynamic>? additionalInfo,
  }) async {
    if (_currentUser == null) {
      print('No user is logged in.');
      return;
    }

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(_currentUser!.id);

      // Prepare updated data
      final updatedData = {
        'name': name,
        if (course != null) 'course': course,
        if (semester != null) 'semester': semester,
        if (additionalInfo != null) ...additionalInfo,
      };

      await userDoc.update(updatedData);

      _currentUser = _currentUser!.copyWith(
        name: name,
        course: course,
        semester: semester,
        additionalInfo: additionalInfo,
      );

      await _saveCurrentUser();
    } catch (e) {
      print('Error updating profile: $e');
    }
  }

  // User Retrieval

  /// Get the currently logged-in user.
  static AppUser? getCurrentUser() {
    return _currentUser;
  }

  /// Fetch all users
  static Future<List<AppUser>> getUsers() async {
    try {
      final querySnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      return querySnapshot.docs
          .map((doc) => AppUser.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  // Local Storage Operations

  /// Save the current user's data locally using SharedPreferences.
  static Future<void> _saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString(_currentUserKey, jsonEncode(_currentUser!.toMap()));
    }
  }
}
