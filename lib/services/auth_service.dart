import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  static AppUser? get currentUser {
    final firebaseUser = _auth.currentUser;
    if (firebaseUser != null) {
      return AppUser(
        id: firebaseUser.uid,
        email: firebaseUser.email ?? '',
        name: firebaseUser.displayName ?? '',
        createdAt: DateTime.now(),
      );
    }
    return null;
  }

  // Check if user is logged in
  static bool get isLoggedIn {
    return _auth.currentUser != null;
  }

  // Sign in with email and password
  static Future<AppUser?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        return AppUser(
          id: userCredential.user!.uid,
          email: userCredential.user!.email ?? '',
          name: userCredential.user!.displayName ?? '',
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đăng nhập: $e');
    }
  }

  // Sign up with email and password
  static Future<AppUser?> signUpWithEmailAndPassword(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(displayName);

        // Save user data to Firestore
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': email,
          'name': displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
          'favoriteRecipes': [],
          'recipesCreated': 0,
        });

        return AppUser(
          id: userCredential.user!.uid,
          email: email,
          name: displayName,
          createdAt: DateTime.now(),
        );
      }
      return null;
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Lỗi đăng xuất: $e');
    }
  }
}
