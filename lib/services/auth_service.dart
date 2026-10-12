import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static const String serverClientId =
      '81483281422-4u1qovavpqud0m0mj84dj5167bqdhfeh.apps.googleusercontent.com';

  static bool _isGoogleSignInInitialized = false;

  /// Ensures GoogleSignIn is initialized with the Firebase web client ID.
  static Future<void> _ensureGoogleSignInInitialized() async {
    if (_isGoogleSignInInitialized) return;
    try {
      await GoogleSignIn.instance.initialize(
        serverClientId: serverClientId,
      );
    } catch (_) {
      // Ignore if already initialized or not supported
    } finally {
      _isGoogleSignInInitialized = true;
    }
  }

  /// Signs in the user with Google and links/authenticates with Firebase Auth.
  /// Returns [UserCredential] if successful, or `null` if the user cancelled.
  static Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      try {
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await FirebaseAuth.instance.signInWithPopup(googleProvider);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'popup-closed-by-user' ||
            e.code == 'cancelled-popup-request') {
          return null;
        }
        rethrow;
      }
    }

    // Native platforms (Android, iOS)
    try {
      await _ensureGoogleSignInInitialized();

      final GoogleSignInAccount account =
          await GoogleSignIn.instance.authenticate();

      final String? idToken = account.authentication.idToken;

      String? accessToken;
      try {
        final auth = await account.authorizationClient
            .authorizationForScopes(['email', 'profile']);
        accessToken = auth?.accessToken;
      } catch (_) {
        // Scopes optional if idToken is available
      }

      if (idToken == null && accessToken == null) {
        throw FirebaseAuthException(
          code: 'no-id-token',
          message:
              'Google Sign In completed but no authentication token was returned.',
        );
      }

      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      return await FirebaseAuth.instance.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        return null;
      }
      rethrow;
    }
  }

  /// Signs out of both Firebase and Google.
  static Future<void> signOut() async {
    try {
      if (!kIsWeb) {
        await GoogleSignIn.instance.signOut();
      }
    } catch (_) {}
    await FirebaseAuth.instance.signOut();
  }
}
