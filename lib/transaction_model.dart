import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType { income, expense, loanGiven, loanReceived }
enum EntryMethod { manual, voice, image, ai }

class TransactionModel {
  final String id;
  final String userId;
  final TransactionType type;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final EntryMethod entryMethod;
  final String? imagePath;
  final String? voiceNotePath;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    required this.entryMethod,
    this.imagePath,
    this.voiceNotePath,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: TransactionType.values[map['type'] ?? 0],
      amount: (map['amount'] ?? 0).toDouble(),
      category: map['category'] ?? '',
      description: map['description'] ?? '',
      date: _toDate(map['date']) ?? DateTime.now(),
      entryMethod: EntryMethod.values[map['entryMethod'] ?? 0],
      imagePath: map['imagePath'],
      voiceNotePath: map['voiceNotePath'],
      metadata: map['metadata'],
      createdAt: _toDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _toDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.index,
      'amount': amount,
      'category': category,
      'description': description,
      'date': Timestamp.fromDate(date),
      'entryMethod': entryMethod.index,
      'imagePath': imagePath,
      'voiceNotePath': voiceNotePath,
      'metadata': metadata,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  static DateTime? _toDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
  
  TransactionModel copyWith({
    String? id,
    String? userId,
    TransactionType? type,
    double? amount,
    String? category,
    String? description,
    DateTime? date,
    EntryMethod? entryMethod,
    String? imagePath,
    String? voiceNotePath,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TransactionModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      description: description ?? this.description,
      date: date ?? this.date,
      entryMethod: entryMethod ?? this.entryMethod,
      imagePath: imagePath ?? this.imagePath,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
