import 'package:cloud_firestore/cloud_firestore.dart';

class BangladeshTaxProfile {
  final String name;
  final String nid;
  final String tin;
  final String circle;
  final String taxZone;
  final String assessmentYear;

  final double annualIncome;
  final int age;
  final String gender;

  final DateTime dateOfBirth;
  final String address;
  final String phone;
  final String email;
  final String? employerName;
  final bool isFemale;
  final bool isSeniorCitizen;
  final bool isDisabled;
  final double totalIncome;
  final double taxableIncome;
  final double taxExemptIncome;
  final double taxLiability;
  final double taxPaid;
  final Map<String, double> incomeSources;
  final Map<String, double> investments;
  final Map<String, double> lifestyleExpenses;
  final Map<String, double> assets;

  BangladeshTaxProfile({
    required this.name,
    required this.nid,
    required this.tin,
    required this.circle,
    required this.taxZone,
    required this.assessmentYear,
    required this.annualIncome,
    required this.age,
    required this.gender,
    required this.dateOfBirth,
    required this.address,
    required this.phone,
    required this.email,
    this.employerName,
    required this.isFemale,
    required this.isSeniorCitizen,
    required this.isDisabled,
    required this.totalIncome,
    required this.taxableIncome,
    required this.taxExemptIncome,
    required this.taxLiability,
    required this.taxPaid,
    required this.incomeSources,
    required this.investments,
    required this.lifestyleExpenses,
    required this.assets,
  });

  factory BangladeshTaxProfile.fromJson(Map<String, dynamic> json) {
    // Helper function to safely convert to double
    double safeToDouble(dynamic value, [double defaultValue = 0.0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper function to safely convert to int
    int safeToInt(dynamic value, [int defaultValue = 0]) {
      if (value == null) return defaultValue;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? defaultValue;
      return defaultValue;
    }

    // Helper function to safely convert Map<String, dynamic> to Map<String, double>
    Map<String, double> safeToDoubleMap(dynamic value) {
      if (value == null) return <String, double>{};
      if (value is Map) {
        return value.map((key, val) => MapEntry(
          key.toString(), 
          safeToDouble(val)
        ));
      }
      return <String, double>{};
    }

    return BangladeshTaxProfile(
      name: json['name']?.toString() ?? '',
      nid: json['nid']?.toString() ?? '',
      tin: json['tin']?.toString() ?? '',
      circle: json['circle']?.toString() ?? '',
      taxZone: json['taxZone']?.toString() ?? '',
      assessmentYear: json['assessmentYear']?.toString() ?? '',
      
      // Fixed: Safe conversion with null handling
      annualIncome: safeToDouble(json['annualIncome']),
      age: safeToInt(json['age'], 25), // Default age 25
      gender: json['gender']?.toString() ?? 'Male',
      
      dateOfBirth: json['dateOfBirth'] is Timestamp
          ? (json['dateOfBirth'] as Timestamp).toDate()
          : json['dateOfBirth'] is String
              ? DateTime.tryParse(json['dateOfBirth']) ?? DateTime.now().subtract(const Duration(days: 365 * 25))
              : json['dateOfBirth'] as DateTime? ?? DateTime.now().subtract(const Duration(days: 365 * 25)),
      
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      employerName: json['employerName']?.toString(),
      
      isFemale: json['isFemale'] as bool? ?? false,
      isSeniorCitizen: json['isSeniorCitizen'] as bool? ?? false,
      isDisabled: json['isDisabled'] as bool? ?? false,
      
      // Fixed: Safe numeric conversions
      totalIncome: safeToDouble(json['totalIncome']),
      taxableIncome: safeToDouble(json['taxableIncome']),
      taxExemptIncome: safeToDouble(json['taxExemptIncome']),
      taxLiability: safeToDouble(json['taxLiability']),
      taxPaid: safeToDouble(json['taxPaid']),
      
      // Fixed: Safe map conversions with defaults
      incomeSources: safeToDoubleMap(json['incomeSources']).isNotEmpty
          ? safeToDoubleMap(json['incomeSources'])
          : {
              "Salary": 0.0,
              "Business": 0.0,
              "Rental": 0.0,
              "Investment": 0.0,
            },
      
      investments: safeToDoubleMap(json['investments']).isNotEmpty
          ? safeToDoubleMap(json['investments'])
          : {
              "Life Insurance": 0.0,
              "DPS/Pension": 0.0,
              "Government Securities": 0.0,
              "Stock Market": 0.0,
              "Mutual Funds": 0.0,
            },
      
      lifestyleExpenses: safeToDoubleMap(json['lifestyleExpenses']).isNotEmpty
          ? safeToDoubleMap(json['lifestyleExpenses'])
          : {
              "Housing": 0.0,
              "Food & Daily": 0.0,
              "Transport": 0.0,
              "Healthcare": 0.0,
              "Education": 0.0,
              "Entertainment": 0.0,
            },
      
      assets: safeToDoubleMap(json['assets']).isNotEmpty
          ? safeToDoubleMap(json['assets'])
          : {
              "Cash & Bank": 0.0,
              "Property": 0.0,
              "Vehicles": 0.0,
              "Investments": 0.0,
              "Others": 0.0,
            },
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'nid': nid,
      'tin': tin,
      'circle': circle,
      'taxZone': taxZone,
      'assessmentYear': assessmentYear,
      'annualIncome': annualIncome,
      'age': age,
      'gender': gender,
      'dateOfBirth': Timestamp.fromDate(dateOfBirth),
      'address': address,
      'phone': phone,
      'email': email,
      'employerName': employerName,
      'isFemale': isFemale,
      'isSeniorCitizen': isSeniorCitizen,
      'isDisabled': isDisabled,
      'totalIncome': totalIncome,
      'taxableIncome': taxableIncome,
      'taxExemptIncome': taxExemptIncome,
      'taxLiability': taxLiability,
      'taxPaid': taxPaid,
      'incomeSources': incomeSources,
      'investments': investments,
      'lifestyleExpenses': lifestyleExpenses,
      'assets': assets,
    };
  }

  BangladeshTaxProfile copyWith({
    String? name,
    String? nid,
    String? tin,
    String? circle,
    String? taxZone,
    String? assessmentYear,
    double? annualIncome,
    int? age,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
    String? phone,
    String? email,
    String? employerName,
    bool? isFemale,
    bool? isSeniorCitizen,
    bool? isDisabled,
    double? totalIncome,
    double? taxableIncome,
    double? taxExemptIncome,
    double? taxLiability,
    double? taxPaid,
    Map<String, double>? incomeSources,
    Map<String, double>? investments,
    Map<String, double>? lifestyleExpenses,
    Map<String, double>? assets,
  }) {
    return BangladeshTaxProfile(
      name: name ?? this.name,
      nid: nid ?? this.nid,
      tin: tin ?? this.tin,
      circle: circle ?? this.circle,
      taxZone: taxZone ?? this.taxZone,
      assessmentYear: assessmentYear ?? this.assessmentYear,
      annualIncome: annualIncome ?? this.annualIncome,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      employerName: employerName ?? this.employerName,
      isFemale: isFemale ?? this.isFemale,
      isSeniorCitizen: isSeniorCitizen ?? this.isSeniorCitizen,
      isDisabled: isDisabled ?? this.isDisabled,
      totalIncome: totalIncome ?? this.totalIncome,
      taxableIncome: taxableIncome ?? this.taxableIncome,
      taxExemptIncome: taxExemptIncome ?? this.taxExemptIncome,
      taxLiability: taxLiability ?? this.taxLiability,
      taxPaid: taxPaid ?? this.taxPaid,
      incomeSources: incomeSources ?? this.incomeSources,
      investments: investments ?? this.investments,
      lifestyleExpenses: lifestyleExpenses ?? this.lifestyleExpenses,
      assets: assets ?? this.assets,
    );
  }
}