import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:ezer_fresh/src/core/services/notification_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  Future<UserCredential?> signInWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signUpWithEmailAndPassword(
    String email,
    String password,
  ) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // `google_sign_in` v7's `authenticate()` call requires a rendered
      // Google Identity Services button on web (and a web OAuth client id
      // this app never configured) — it doesn't work as a plain button
      // tap. Firebase Auth's own popup flow bridges straight to the
      // Firebase JS SDK, reuses the Google provider already enabled for
      // this Firebase project, and needs no extra web-side setup.
      return _firebaseAuth.signInWithPopup(GoogleAuthProvider());
    }

    await GoogleSignIn.instance.initialize();
    final googleUser = await GoogleSignIn.instance.authenticate();

    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(PhoneAuthCredential) verificationCompleted,
    required void Function(FirebaseAuthException) verificationFailed,
    required void Function(String, int?) codeSent,
    required void Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithPhoneCredential(PhoneAuthCredential credential) async {
    return await _firebaseAuth.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    try {
      await NotificationService().unregisterCurrentUserToken();
    } catch (e) {
      debugPrint('Error unregistering notification token: $e');
    }
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.initialize();
        await GoogleSignIn.instance.signOut();
      } catch (e) {
        debugPrint('Error signing out Google: $e');
      }
    }
    return _firebaseAuth.signOut();
  }
}
