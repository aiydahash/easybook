import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_model.dart';

class UserManager {
  static const String _currentUserKey = 'currentUser';
  static AppUser? _currentUser;
  
  // Add a getter for current user role
  static String get currentUserRole => _currentUser?.role ?? '';
  
  // Add role-based access control methods
  static bool canAccessBookingFeatures() {
    return _currentUser?.role == 'Student' || _currentUser?.role == 'UMPSA Staff';
  }
  
  static bool canAccessAdminFeatures() {
    return _currentUser?.role == 'Library Staff';
  }

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
  static Future<bool> registerUser({
    required String name,
    required String matricID,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? additionalInfo,
  }) async {
    try {
      // Validate role
      if (!['Library Staff', 'UMPSA Staff', 'Student'].contains(role)) {
        throw Exception('Invalid role specified');
      }

      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userData = {
        'uid': userCredential.user!.uid,
        'name': name,
        'matricID': matricID,
        'email': email,
        'role': role,
        'createdAt': FieldValue.serverTimestamp(),
        if (additionalInfo != null) ...additionalInfo,
      };

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(userData);

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
      rethrow;
    }
  }

  // Enhanced User Authentication
  static Future<bool> loginUser(
      String matricID, String password, String selectedRole) async {
    try {
      // Validate role
      if (!['Library Staff', 'UMPSA Staff', 'Student'].contains(selectedRole)) {
        print('Invalid role selected');
        return false;
      }

      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('matricID', isEqualTo: matricID)
          .where('role', isEqualTo: selectedRole)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print('User not found or invalid role');
        return false;
      }

      var userData = querySnapshot.docs.first.data() as Map<String, dynamic>;
      
      // Additional role validation
      if (userData['role'] != selectedRole) {
        print('Role mismatch');
        return false;
      }

      _currentUser = AppUser.fromMap(userData);
      await _saveCurrentUser();
      
      // Print debug information
      print('Login successful. User role: ${_currentUser?.role}');
      return true;
    } catch (e) {
      print('Error logging in user: $e');
      return false;
    }
  }

  // Enhanced Logout
  static Future<void> logout() async {
    try {
      _currentUser = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currentUserKey);
      await FirebaseAuth.instance.signOut();
      print('Logout successful');
    } catch (e) {
      print('Error during logout: $e');
      rethrow;
    }
  }

  // Rest of the methods remain the same...
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

  static AppUser? getCurrentUser() {
    return _currentUser;
  }

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

  static Future<void> _saveCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    if (_currentUser != null) {
      await prefs.setString(_currentUserKey, jsonEncode(_currentUser!.toMap()));
    }
  }
}