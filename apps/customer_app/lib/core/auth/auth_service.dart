import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import '../firestore/user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '663243229047-b79fr0b7ipheh02d6cqforn9u67buoet.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  String? _verificationId;
  int? _resendToken;

  String? get verificationId => _verificationId;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle({String? referredBy}) async {
    try {
      debugPrint("AuthService: [Google] Initializing Sign In...");
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        debugPrint("AuthService: [Google] User canceled sign-in dialog.");
        return null;
      }

      debugPrint("AuthService: [Google] Fetching authentication tokens for ${googleUser.email}...");
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw Exception("Google Sign In failed: No tokens received.");
      }

      debugPrint("AuthService: [Google] Creating Firebase credential...");
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint("AuthService: [Google] Signing into Firebase...");
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        debugPrint("AuthService: [Google] Firebase Sign-In Successful. Saving profile...");
        await _userService.saveUserProfile(userCredential.user!, referredBy: referredBy);
        debugPrint("AuthService: [Google] Profile save complete.");
      }
      
      return userCredential;
    } catch (e) {
      debugPrint("AuthService: [Google] CRITICAL ERROR: $e");
      rethrow;
    }
  }

  // Phone Auth: Verify Number
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(FirebaseAuthException e) onVerificationFailed,
    required Function(PhoneAuthCredential credential) onVerificationCompleted,
    int? forceResendingToken,
  }) async {
    debugPrint("AuthService: [Phone] Starting verification for $phoneNumber...");
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken ?? _resendToken,
      verificationCompleted: (credential) {
        debugPrint("AuthService: [Phone] Auto-verification completed.");
        onVerificationCompleted(credential);
      },
      verificationFailed: (e) {
        debugPrint("AuthService: [Phone] Verification failed: ${e.code} - ${e.message}");
        onVerificationFailed(e);
      },
      codeSent: (verificationId, resendToken) {
        debugPrint("AuthService: [Phone] Code sent. ID: $verificationId");
        _verificationId = verificationId;
        _resendToken = resendToken;
        onCodeSent(verificationId, resendToken);
      },
      codeAutoRetrievalTimeout: (verificationId) {
        debugPrint("AuthService: [Phone] Auto-retrieval timeout.");
        _verificationId = verificationId;
      },
    );
  }

  // Phone Auth: Sign In with OTP
  Future<UserCredential?> signInWithOTP(String verificationId, String smsCode, {String? referredBy}) async {
    try {
      final AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final UserCredential userCredential = await _auth.signInWithCredential(credential);
      
      if (userCredential.user != null) {
        await _userService.saveUserProfile(userCredential.user!, referredBy: referredBy);
      }
      
      return userCredential;
    } catch (e) {
      debugPrint("Error in OTP Sign In: $e");
      rethrow;
    }
  }

  // Sign with credential (for auto-verification)
  Future<UserCredential> signInWithCredential(AuthCredential credential) async {
    return await _auth.signInWithCredential(credential);
  }

  // Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
