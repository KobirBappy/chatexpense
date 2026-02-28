import 'package:chatapp/firebase_service.dart';
import 'package:chatapp/subscription_model.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class SubscriptionProvider extends ChangeNotifier {
  SubscriptionModel? _subscription;
  bool _isLoading = false;
  String _error = '';
  
  SubscriptionModel? get subscription => _subscription;
  bool get isLoading => _isLoading;
  String get error => _error;
  
  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
  
  void setError(String message) {
    _error = message;
    notifyListeners();
  }
  
  Future<void> loadSubscription(String userId) async {
    setLoading(true);
    setError('');
    
    try {
      _subscription = await FirebaseService.getSubscription(userId);
      setLoading(false);
    } catch (e) {
      setError('Failed to load subscription: $e');
      setLoading(false);
    }
  }
  
  bool canUseFeature(String feature) {
    return _subscription?.canUseFeature(feature) ?? false;
  }
  
  int getRemainingUsage(String feature) {
    return _subscription?.getRemainingUsage(feature) ?? 0;
  }
  
  double getUsagePercentage(String feature) {
    return _subscription?.getUsagePercentage(feature) ?? 0;
  }
  
  Future<bool> updateSubscriptionPlan(SubscriptionPlan newPlan) async {
    if (_subscription == null) return false;
    
    try {
      // Define plan limits
      final planLimits = {
        SubscriptionPlan.free: {
          'chatMessages': 60,
          'imageEntries': 10,
          'voiceEntries': 10,
          'aiQueries': 10,
          'customCategories': 3,
        },
        SubscriptionPlan.pro: {
          'chatMessages': 250,
          'imageEntries': 50,
          'voiceEntries': 50,
          'aiQueries': 30,
          'customCategories': 10,
        },
        SubscriptionPlan.powerUser: {
          'chatMessages': 1000,
          'imageEntries': 200,
          'voiceEntries': 200,
          'aiQueries': 75,
          'customCategories': 25,
        },
      };
      
      final updates = {
        'plan': newPlan.index,
        'limits': planLimits[newPlan],
        'updatedAt': FieldValue.serverTimestamp(),
      };
      
      await FirebaseFirestore.instance
          .collection('subscriptions')
          .doc(_subscription!.userId)
          .update(updates);
      
      // Reload subscription
      await loadSubscription(_subscription!.userId);
      
      return true;
    } catch (e) {
      setError('Failed to update subscription: $e');
      return false;
    }
  }
  
  String getPlanName(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 'Free';
      case SubscriptionPlan.pro:
        return 'Pro';
      case SubscriptionPlan.powerUser:
        return 'Power User';
    }
  }
  
  double getPlanPrice(SubscriptionPlan plan) {
    switch (plan) {
      case SubscriptionPlan.free:
        return 0;
      case SubscriptionPlan.pro:
        return 5.99;
      case SubscriptionPlan.powerUser:
        return 12.99;
    }
  }
}