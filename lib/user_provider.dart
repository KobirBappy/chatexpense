import 'package:chatapp/firebase_service.dart';
import 'package:chatapp/user_model.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserProvider extends ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  String _error = '';
  
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String get error => _error;
  bool get isAuthenticated => FirebaseService.currentUser != null;
  
  UserProvider() {
    // Listen to auth state changes
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        loadUserData(user.uid);
      } else {
        _user = null;
        notifyListeners();
      }
    });
  }
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void setError(String message) {
    _error = message;
    notifyListeners();
  }
  
  Future<bool> signIn(String email, String password) async {
    setLoading(true);
    setError('');
    
    try {
      final credential = await FirebaseService.signInWithEmail(email, password);
      if (credential?.user != null) {
        await loadUserData(credential!.user!.uid);
        setLoading(false);
        return true;
      }
      setError('Invalid email or password');
      setLoading(false);
      return false;
    } catch (e) {
      setError('Sign in failed: $e');
      setLoading(false);
      return false;
    }
  }
  
  Future<bool> signUp(String email, String password, {String? name}) async {
    setLoading(true);
    setError('');
    
    try {
      final credential = await FirebaseService.signUpWithEmail(email, password, name: name);
      if (credential?.user != null) {
        await loadUserData(credential!.user!.uid);
        setLoading(false);
        return true;
      }
      setError('Sign up failed');
      setLoading(false);
      return false;
    } catch (e) {
      setError('Sign up failed: $e');
      setLoading(false);
      return false;
    }
  }
  
  Future<void> signOut() async {
    await FirebaseService.signOut();
    _user = null;
    notifyListeners();
  }
  
  Future<void> loadUserData(String userId) async {
    try {
      _user = await FirebaseService.getUserData(userId);

      // Auto-heal accounts that exist in Auth but don't yet have a Firestore profile.
      if (_user == null) {
        final authUser = FirebaseAuth.instance.currentUser;
        if (authUser != null && authUser.uid == userId) {
          await FirebaseService.createUserDocument(
            authUser,
            name: authUser.displayName,
          );
          _user = await FirebaseService.getUserData(userId);
        }
      }

      notifyListeners();
    } catch (e) {
      setError('Failed to load user data: $e');
    }
  }
  
  Future<bool> updateProfile({
    String? name,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    if (_user == null) return false;
    
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      if (profileImageUrl != null) updates['profileImageUrl'] = profileImageUrl;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update(updates);
      
      // Reload user data
      await loadUserData(_user!.id);
      return true;
    } catch (e) {
      setError('Failed to update profile: $e');
      return false;
    }
  }
  
  Future<bool> updateNotificationSettings(Map<String, dynamic> settings) async {
    if (_user == null) return false;
    
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user!.id)
          .update({'notificationSettings': settings});
      
      // Reload user data
      await loadUserData(_user!.id);
      return true;
    } catch (e) {
      setError('Failed to update notification settings: $e');
      return false;
    }
  }
}
