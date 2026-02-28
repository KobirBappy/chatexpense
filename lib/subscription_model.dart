import 'package:cloud_firestore/cloud_firestore.dart';

enum SubscriptionPlan { free, pro, powerUser }

class SubscriptionModel {
  final String id;
  final String userId;
  final SubscriptionPlan plan;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final Map<String, int> usage; // Track usage of different features
  final Map<String, int> limits; // Feature limits based on plan
  final DateTime? nextBillingDate;
  final double? price;
  final String? currency;

  SubscriptionModel({
    required this.id,
    required this.userId,
    required this.plan,
    required this.startDate,
    this.endDate,
    required this.isActive,
    required this.usage,
    required this.limits,
    this.nextBillingDate,
    this.price,
    this.currency,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      plan: SubscriptionPlan.values[map['plan'] ?? 0],
      startDate: (map['startDate'] as Timestamp).toDate(),
      endDate: map['endDate'] != null 
          ? (map['endDate'] as Timestamp).toDate() 
          : null,
      isActive: map['isActive'] ?? true,
      usage: Map<String, int>.from(map['usage'] ?? {}),
      limits: Map<String, int>.from(map['limits'] ?? {}),
      nextBillingDate: map['nextBillingDate'] != null 
          ? (map['nextBillingDate'] as Timestamp).toDate() 
          : null,
      price: map['price']?.toDouble(),
      currency: map['currency'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'plan': plan.index,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'isActive': isActive,
      'usage': usage,
      'limits': limits,
      'nextBillingDate': nextBillingDate != null 
          ? Timestamp.fromDate(nextBillingDate!) 
          : null,
      'price': price,
      'currency': currency,
    };
  }
  
  // Helper methods to check limits
  bool canUseFeature(String feature) {
    final currentUsage = usage[feature] ?? 0;
    final limit = limits[feature] ?? 0;
    return limit == -1 || currentUsage < limit; // -1 means unlimited
  }
  
  int getRemainingUsage(String feature) {
    final currentUsage = usage[feature] ?? 0;
    final limit = limits[feature] ?? 0;
    if (limit == -1) return -1; // Unlimited
    return limit - currentUsage;
  }
  
  double getUsagePercentage(String feature) {
    final currentUsage = usage[feature] ?? 0;
    final limit = limits[feature] ?? 0;
    if (limit == -1 || limit == 0) return 0;
    return (currentUsage / limit) * 100;
  }
}