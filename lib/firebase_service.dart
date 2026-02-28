import 'dart:io';
import 'package:chatapp/subscription_model.dart';
import 'package:chatapp/transaction_model.dart';
import 'package:chatapp/user_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  
  // Auth methods
  static User? get currentUser => _auth.currentUser;
  
  static Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }
  
  static Future<UserCredential?> signUpWithEmail(String email, String password, {String? name}) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Create user document
      if (credential.user != null) {
        await createUserDocument(credential.user!, name: name);
      }
      
      return credential;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }
  
  static Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // User methods
  static Future<void> createUserDocument(User user, {String? name}) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    final existingUserDoc = await userDoc.get();
    
    final userData = {
      'email': user.email,
      'name': name ?? user.displayName,
      'phoneNumber': user.phoneNumber,
      'profileImageUrl': user.photoURL,
      'memberSince': FieldValue.serverTimestamp(),
      'emailVerified': user.emailVerified,
      'notificationSettings': {
        'dailyReminders': true,
        'reminderTime': '12:01',
        'budgetAlerts': true,
        'transactionNotifications': true,
      },
      'customCategories': ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment'],
      'lastLogin': FieldValue.serverTimestamp(),
    };
    
    await userDoc.set(userData, SetOptions(merge: true));
    
    // Create default subscription only for newly created user documents.
    if (!existingUserDoc.exists) {
      await createDefaultSubscription(user.uid);
    }
  }
  
  static Future<void> createDefaultSubscription(String userId) async {
    final subDoc = _firestore.collection('subscriptions').doc(userId);
    
    final subscriptionData = {
      'userId': userId,
      'plan': SubscriptionPlan.free.index,
      'startDate': FieldValue.serverTimestamp(),
      'isActive': true,
      'usage': {
        'chatMessages': 0,
        'imageEntries': 0,
        'voiceEntries': 0,
        'aiQueries': 0,
      },
      'limits': {
        'chatMessages': 60,
        'imageEntries': 10,
        'voiceEntries': 10,
        'aiQueries': 10,
        'customCategories': 3,
      },
    };
    
    await subDoc.set(subscriptionData);
  }
  
  static Future<UserModel?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Get user data error: $e');
      return null;
    }
  }
  
  // Transaction methods
  static Future<String?> addTransaction(TransactionModel transaction) async {
    try {
      final docRef = await _firestore.collection('transactions').add(
        transaction.toMap(),
      );
      
      // Update usage but do not fail transaction creation if usage update fails.
      try {
        await updateUsage(transaction.userId, transaction.entryMethod);
      } catch (e) {
        print('Update usage warning: $e');
      }
      
      return docRef.id;
    } catch (e) {
      print('Add transaction error: $e');
      return null;
    }
  }
  
  // Update transaction
  static Future<bool> updateTransaction(String transactionId, Map<String, dynamic> updates) async {
    try {
      // Add updatedAt timestamp
      updates['updatedAt'] = Timestamp.fromDate(DateTime.now());
      
      await _firestore.collection('transactions').doc(transactionId).update(updates);
      return true;
    } catch (e) {
      print('Update transaction error: $e');
      return false;
    }
  }
  
  // Delete transaction
  static Future<bool> deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
      return true;
    } catch (e) {
      print('Delete transaction error: $e');
      return false;
    }
  }
  
  static Stream<List<TransactionModel>> getTransactions(String userId) {
    return _firestore
        .collection('transactions')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }
  
  static Future<List<TransactionModel>> getTransactionsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot = await _firestore
          .collection('transactions')
          .where('userId', isEqualTo: userId)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('date', descending: true)
          .get();
      
      return snapshot.docs.map((doc) {
        return TransactionModel.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      print('Get transactions by date range error: $e');
      return [];
    }
  }
  
  // Subscription methods
  static Future<SubscriptionModel?> getSubscription(String userId) async {
    try {
      final doc = await _firestore.collection('subscriptions').doc(userId).get();
      if (doc.exists) {
        return SubscriptionModel.fromMap(doc.data()!, doc.id);
      }
      return null;
    } catch (e) {
      print('Get subscription error: $e');
      return null;
    }
  }
  
  static Future<void> updateUsage(String userId, EntryMethod method) async {
    final subDoc = _firestore.collection('subscriptions').doc(userId);
    
    String usageField = '';
    switch (method) {
      case EntryMethod.voice:
        usageField = 'usage.voiceEntries';
        break;
      case EntryMethod.image:
        usageField = 'usage.imageEntries';
        break;
      case EntryMethod.ai:
        usageField = 'usage.aiQueries';
        break;
      default:
        return; // Manual entries don't count against usage
    }
    
    final snapshot = await subDoc.get();
    if (!snapshot.exists) {
      await createDefaultSubscription(userId);
    }

    await subDoc.update({
      usageField: FieldValue.increment(1),
    });
  }
  
  // Storage methods
  static Future<String?> uploadImage(String userId, String imagePath) async {
    try {
      final ref = _storage.ref().child('users/$userId/receipts/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = await ref.putFile(File(imagePath));
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      print('Upload image error: $e');
      return null;
    }
  }
}
