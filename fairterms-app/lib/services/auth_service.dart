/// Authentication service using Firebase Auth and Google Sign-In.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:google_sign_in/google_sign_in.dart';

/// Provides authentication operations for FairTerms.
class AuthService {
  AuthService._();

  static final AuthService _instance = AuthService._();

  /// Singleton instance of [AuthService].
  static AuthService get instance => _instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Stream of authentication state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Returns the currently signed-in user, or null if not signed in.
  User? get currentUser => _auth.currentUser;

  /// Returns true if a user is currently signed in.
  bool get isSignedIn => _auth.currentUser != null;

  /// Signs in with Google and returns the [UserCredential].
  ///
  /// On web: uses Firebase's signInWithPopup (idToken not available via google_sign_in on web).
  /// On mobile: uses GoogleSignIn package to obtain credentials.
  /// Throws [FirebaseAuthException] on failure.
  Future<UserCredential> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: use Firebase Auth popup flow directly
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      return _auth.signInWithPopup(googleProvider);
    }

    // Mobile: use google_sign_in package
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'sign_in_cancelled',
        message: 'Google sign-in was cancelled by the user.',
      );
    }

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return _auth.signInWithCredential(credential);
  }

  /// Returns the current user's Firebase ID token for API authentication.
  ///
  /// Forces token refresh if [forceRefresh] is true.
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }

  /// Signs out the current user from both Firebase and Google.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Firebase signout: $e');
    }
    
    try {
      if (!kIsWeb || _googleSignIn.clientId != null) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      debugPrint('Google signout error: $e');
    }
  }

  /// Returns the display name of the current user, or a fallback string.
  String get currentUserDisplayName =>
      _auth.currentUser?.displayName ?? 'User';

  /// Returns the email of the current user, or an empty string.
  String get currentUserEmail => _auth.currentUser?.email ?? '';

  /// Returns the photo URL of the current user, or null.
  String? get currentUserPhotoUrl => _auth.currentUser?.photoURL;

  /// Returns true if the current user has the Firebase custom claim `admin: true`.
  /// Forces a token refresh so the claim is always fresh.
  Future<bool> get isAdmin async {
    final user = _auth.currentUser;
    if (user == null) return false;
    final result = await user.getIdTokenResult(true);
    return result.claims?['admin'] == true;
  }
}
