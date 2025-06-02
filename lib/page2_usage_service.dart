import 'package:chatapp/page1_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class UsageService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Cache for plan limits to avoid repeated database calls
  PlanLimits? _cachedPlanLimits;
  Usage? _cachedUsage;
  DateTime? _lastCacheUpdate;

  Future<PlanLimits> getPlanLimits() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Return cached limits if available and recent (within 1 hour)
    if (_cachedPlanLimits != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).inHours < 1) {
      return _cachedPlanLimits!;
    }

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      
      final plan = userDoc.data()?['subscription_plan'] as String? ?? 'Free';
      
      _cachedPlanLimits = PlanLimits.fromSubscriptionPlan(plan);
      _lastCacheUpdate = DateTime.now();
      
      return _cachedPlanLimits!;
    } catch (e) {
      print("Error getting plan limits: $e");
      // Return free plan as fallback
      return PlanLimits.fromSubscriptionPlan('Free');
    }
  }

  Future<Usage> getCurrentUsage() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not authenticated");

    // Return cached usage if available and recent (within 5 minutes)
    if (_cachedUsage != null && 
        _lastCacheUpdate != null && 
        DateTime.now().difference(_lastCacheUpdate!).inMinutes < 5) {
      return _cachedUsage!;
    }

    try {
      final doc = await _firestore
          .collection('usage')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        _cachedUsage = Usage.fromFirestore(doc.data()!);
        return _cachedUsage!;
      }
      
      _cachedUsage = Usage.zero();
      return _cachedUsage!;
    } catch (e) {
      print("Error getting current usage: $e");
      return Usage.zero();
    }
  }

  Future<bool> canUseFeature(String type) async {
    try {
      final usage = await getCurrentUsage();
      final limits = await getPlanLimits();
      
      return !usage.hasExceededLimit(limits, type);
    } catch (e) {
      print("Error checking feature availability: $e");
      return false;
    }
  }

  Future<void> incrementUsage(String type) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("Cannot increment usage: User not authenticated");
      return;
    }

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final usageRef = _firestore.collection('usage').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(usageRef);

        Map<String, dynamic> data;
        
        if (!doc.exists) {
          // Create new usage document
          data = {
            'chatMessages': 0,
            'imageEntries': 0,
            'voiceEntries': 0,
            'aiQueries': 0,
            'resetDate': Timestamp.fromDate(monthStart),
          };
        } else {
          data = doc.data()!;
          final resetDate = (data['resetDate'] as Timestamp?)?.toDate();
          
          // Reset usage if it's a new month
          if (resetDate == null || resetDate.isBefore(monthStart)) {
            data = {
              'chatMessages': 0,
              'imageEntries': 0,
              'voiceEntries': 0,
              'aiQueries': 0,
              'resetDate': Timestamp.fromDate(monthStart),
            };
          }
        }

        // Increment the specific usage type
        data[type] = (data[type] as int? ?? 0) + 1;
        data['lastUpdated'] = Timestamp.now();

        transaction.set(usageRef, data);
      });

      // Clear cache to force refresh on next access
      _cachedUsage = null;
      
    } catch (e) {
      print("Error incrementing usage for $type: $e");
      // Don't throw here to avoid blocking user actions
    }
  }

  Future<Map<String, double>> getUsagePercentages() async {
    try {
      final usage = await getCurrentUsage();
      final limits = await getPlanLimits();

      return {
        'chatMessages': usage.getUsagePercentage(limits, 'chatMessages'),
        'imageEntries': usage.getUsagePercentage(limits, 'imageEntries'),
        'voiceEntries': usage.getUsagePercentage(limits, 'voiceEntries'),
        'aiQueries': usage.getUsagePercentage(limits, 'aiQueries'),
      };
    } catch (e) {
      print("Error getting usage percentages: $e");
      return {
        'chatMessages': 0,
        'imageEntries': 0,
        'voiceEntries': 0,
        'aiQueries': 0,
      };
    }
  }

  Future<bool> isNearLimit(String type, {double threshold = 0.8}) async {
    try {
      final usage = await getCurrentUsage();
      final limits = await getPlanLimits();
      
      final percentage = usage.getUsagePercentage(limits, type) / 100;
      return percentage >= threshold;
    } catch (e) {
      print("Error checking if near limit: $e");
      return false;
    }
  }

  Future<int> getRemainingQuota(String type) async {
    try {
      final usage = await getCurrentUsage();
      final limits = await getPlanLimits();

      switch (type) {
        case 'chatMessages':
          return limits.chatMessages - usage.chatMessages;
        case 'imageEntries':
          return limits.imageEntries - usage.imageEntries;
        case 'voiceEntries':
          return limits.voiceEntries - usage.voiceEntries;
        case 'aiQueries':
          return limits.aiQueries - usage.aiQueries;
        default:
          return 0;
      }
    } catch (e) {
      print("Error getting remaining quota: $e");
      return 0;
    }
  }

  Future<DateTime?> getResetDate() async {
    try {
      final usage = await getCurrentUsage();
      return usage.resetDate;
    } catch (e) {
      print("Error getting reset date: $e");
      return null;
    }
  }

  Future<void> resetUsageForTesting() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      await _firestore.collection('usage').doc(user.uid).delete();
      _cachedUsage = null;
      _cachedPlanLimits = null;
      _lastCacheUpdate = null;
    } catch (e) {
      print("Error resetting usage: $e");
    }
  }

  // Clear cache manually when needed
  void clearCache() {
    _cachedUsage = null;
    _cachedPlanLimits = null;
    _lastCacheUpdate = null;
  }

  // Batch usage increment for multiple operations
  Future<void> incrementMultipleUsage(Map<String, int> increments) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("Cannot increment usage: User not authenticated");
      return;
    }

    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month, 1);
      final usageRef = _firestore.collection('usage').doc(user.uid);

      await _firestore.runTransaction((transaction) async {
        final doc = await transaction.get(usageRef);

        Map<String, dynamic> data;
        
        if (!doc.exists) {
          data = {
            'chatMessages': 0,
            'imageEntries': 0,
            'voiceEntries': 0,
            'aiQueries': 0,
            'resetDate': Timestamp.fromDate(monthStart),
          };
        } else {
          data = doc.data()!;
          final resetDate = (data['resetDate'] as Timestamp?)?.toDate();
          
          if (resetDate == null || resetDate.isBefore(monthStart)) {
            data = {
              'chatMessages': 0,
              'imageEntries': 0,
              'voiceEntries': 0,
              'aiQueries': 0,
              'resetDate': Timestamp.fromDate(monthStart),
            };
          }
        }

        // Apply all increments
        for (final entry in increments.entries) {
          data[entry.key] = (data[entry.key] as int? ?? 0) + entry.value;
        }
        
        data['lastUpdated'] = Timestamp.now();
        transaction.set(usageRef, data);
      });

      _cachedUsage = null;
      
    } catch (e) {
      print("Error incrementing multiple usage: $e");
    }
  }
}