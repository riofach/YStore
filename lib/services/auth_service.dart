import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bcrypt/bcrypt.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Login with email and password
  Future<User?> login(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print("Login error: ${e.message}");
      return null;
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
    print("User logged out"); // log to console
  }

  // Get current user's UID
  String? getCurrentUserUid() {
    return _auth.currentUser?.uid;
  }

  // Get user role from Firestore
  Future<String?> getUserRole(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      return userDoc['role'];
    } catch (e) {
      print("Error getting user role: $e");
      return null;
    }
  }

  //(only for superAdmin)
  Future<void> manageRole(String targetUserId, String newRole) async {
    try {
      await _firestore.collection('users').doc(targetUserId).update({
        'role': newRole,
      });
    } catch (e) {
      print("Error managing role: $e");
    }
  }

  // Function to hash password using bcrypt
  String hashPassword(String password) {
    // Generate salt and hash password
    String salt = BCrypt.gensalt(); // Generate salt
    String hashedPassword = BCrypt.hashpw(password, salt); // Hash password
    return hashedPassword;
  }

  // Function to verify password using bcrypt
  bool verifyPassword(String password, String hashedPassword) {
    return BCrypt.checkpw(password, hashedPassword); // Verify password
  }
}
