// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   // Sign in with email/password
//   Future<User?> signIn(String email, String password) async {
//     try {
//       UserCredential result = await _auth.signInWithEmailAndPassword(
//         email: email, 
//         password: password
//       );
//       return result.user;
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }

//   // Register with email/password
//   Future<User?> register(String email, String password) async {
//     try {
//       UserCredential result = await _auth.createUserWithEmailAndPassword(
//         email: email, 
//         password: password
//       );
      
//       // Create user document
//       // await _firestore.collection('users').doc(result.user!.uid).set({
//       //   'email': email,
//       //   'createdAt': Timestamp.now(),
//       //   'isSubscribed': false,
//       // });

//       await _firestore.collection('users').doc(result.user!.uid).set({
//   'email': email,
//   'createdAt': Timestamp.now(),
//   'subscription_plan': 'Free', // Add default plan
//   'userId': result.user!.uid, // Add user ID
// });
      
//       return result.user;
//     } catch (e) {
//       print(e);
//       return null;
//     }
//   }

//   // Sign out
//   Future<void> signOut() async {
//     await _auth.signOut();
//   }

//   // Auth state stream
//   Stream<User?> get user => _auth.authStateChanges();
// }



import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign in with email/password
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      return result.user;
    } catch (e) {
      print('Sign in error: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Register with email/password
  Future<User?> register(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      if (result.user != null) {
        // Create user document with proper structure
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'createdAt': Timestamp.now(),
          'subscription_plan': 'Free', // Default plan
          'userId': result.user!.uid,
          'lastActive': Timestamp.now(),
        });

        // Initialize user usage document
        await _firestore.collection('usage').doc(result.user!.uid).set({
          'chatMessages': 0,
          'imageEntries': 0,
          'voiceEntries': 0,
          'aiQueries': 0,
          'resetDate': Timestamp.fromDate(DateTime(
            DateTime.now().year,
            DateTime.now().month,
            1,
          )),
          'userId': result.user!.uid,
        });

        // Create initial categories for the user
        final defaultCategories = [
          'Food',
          'Transport',
          'Shopping',
          'Bills',
          'Entertainment',
          'Health',
          'Education',
          'Income',
          'Others'
        ];

        final batch = _firestore.batch();
        for (String category in defaultCategories) {
          final docRef = _firestore.collection('categories').doc();
          batch.set(docRef, {
            'name': category,
            'userId': result.user!.uid,
            'createdAt': Timestamp.now(),
            'isDefault': true,
          });
        }
        await batch.commit();
      }
      
      return result.user;
    } catch (e) {
      print('Registration error: $e');
      throw e; // Re-throw to handle in UI
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      // Update last active timestamp before signing out
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'lastActive': Timestamp.now(),
        });
      }
      await _auth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      // Still sign out even if update fails
      await _auth.signOut();
    }
  }

  // Auth state stream
  Stream<User?> get user => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  // Update user's last active timestamp
  Future<void> updateLastActive() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        await _firestore.collection('users').doc(user.uid).update({
          'lastActive': Timestamp.now(),
        });
      } catch (e) {
        print('Error updating last active: $e');
      }
    }
  }

  // Reset user's monthly usage (called when month changes)
  Future<void> resetMonthlyUsage() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        final now = DateTime.now();
        final monthStart = DateTime(now.year, now.month, 1);
        
        await _firestore.collection('usage').doc(user.uid).update({
          'chatMessages': 0,
          'imageEntries': 0,
          'voiceEntries': 0,
          'aiQueries': 0,
          'resetDate': Timestamp.fromDate(monthStart),
        });
      } catch (e) {
        print('Error resetting monthly usage: $e');
      }
    }
  }
}