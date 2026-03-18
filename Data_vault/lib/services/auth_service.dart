import 'package:firebase_auth/firebase_auth.dart';

/**
 * AuthService
 * Encapsulates all Firebase Authentication logic.
 * Provides a clean interface for the UI to handle login, registration, and session state.
 */
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Stream to monitor real-time auth state changes (logged in vs logged out)
  Stream<User?> get user => _auth.authStateChanges();

  // Sign in with email and password
  // Throws specific FirebaseAuthException for the UI to handle (e.g., user-not-found)
  Future<UserCredential> signIn(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      rethrow; 
    }
  }

  // Register a new user account
  Future<UserCredential> signUp(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } on FirebaseAuthException {
      rethrow; 
    }
  }

  // Terminate current session
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Helper to get the current UID, used for linking files to owners
  String get uid => _auth.currentUser?.uid ?? '';
}
