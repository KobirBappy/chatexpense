import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime memberSince;
  final bool emailVerified;
  final Map<String, dynamic> notificationSettings;
  final List<String> customCategories;
  final DateTime? lastLogin;
  final Map<String, dynamic>? preferences;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.phoneNumber,
    this.profileImageUrl,
    required this.memberSince,
    required this.emailVerified,
    required this.notificationSettings,
    required this.customCategories,
    this.lastLogin,
    this.preferences,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      memberSince: _toDate(map['memberSince']) ?? DateTime.now(),
      emailVerified: map['emailVerified'] ?? false,
      notificationSettings: map['notificationSettings'] ?? {},
      customCategories: List<String>.from(map['customCategories'] ?? []),
      lastLogin: _toDate(map['lastLogin']),
      preferences: map['preferences'],
    );
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'memberSince': Timestamp.fromDate(memberSince),
      'emailVerified': emailVerified,
      'notificationSettings': notificationSettings,
      'customCategories': customCategories,
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
      'preferences': preferences,
    };
  }
}
