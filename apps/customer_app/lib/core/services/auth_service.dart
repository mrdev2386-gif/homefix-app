import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import '../firebase/functions_instance.dart';
import 'dart:math';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? '663243229047-b79fr0b7ipheh02d6cqforn9u67buoet.apps.googleusercontent.com' : null,
  );

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Google Sign In
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      await _updateUserData(userCredential.user!);
      return userCredential;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ [Auth] Firebase Auth error: ${e.message}');
      rethrow;
    } catch (e) {
      // Handle Google Play Services errors gracefully
      debugPrint('⚠️ [Auth] Google Sign-In failed: $e');
      if (e.toString().contains('DEVELOPER_ERROR') || 
          e.toString().contains('common') ||
          e.toString().contains('sign_in_failed')) {
        debugPrint('🔧 [Auth] Check Google Play Services configuration');
      }
      rethrow;
    }
  }

  // Phone Auth
  // Format phone number to E.164 for India
  String formatPhoneIN(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    
    // Already has country code
    if (digits.startsWith('91') && digits.length == 12) {
      return '+$digits';
    }
    
    // Has +91 prefix
    if (digits.startsWith('+91') || digits.startsWith('091')) {
      final cleaned = digits.replaceAll(RegExp(r'^\+?91?'), '');
      if (cleaned.length == 10) {
        return '+91$cleaned';
      }
    }
    
    // Just 10 digits
    if (digits.length == 10) {
      return '+91$digits';
    }
    
    // Already has + - just return as is
    if (input.startsWith('+')) {
      return input;
    }
    
    // Fallback - try to make it work
    return '+91$digits';
  }

  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    // Format phone number to E.164
    final formattedPhone = formatPhoneIN(phoneNumber);
    debugPrint('[Auth] 📱 Sending OTP to: $formattedPhone');
    
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        verificationCompleted: (credential) {
          debugPrint('[Auth] ✅ Auto-verification completed');
          verificationCompleted(credential);
        },
        verificationFailed: (e) {
          debugPrint('[Auth] ❌ Verification failed: ${e.code} - ${e.message}');
          if (e.code == 'app-not-verified' || e.code == 'app-not-authorized') {
            debugPrint('[Auth] 🔧 App Check / Play Integrity issue detected');
            debugPrint('[Auth] 🔧 Check Firebase Console → App Check settings');
          }
          verificationFailed(e);
        },
        codeSent: (verificationId, resendToken) {
          debugPrint('[Auth] ✅ OTP sent successfully. Verification ID: ${verificationId.substring(0, 10)}...');
          codeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (verificationId) {
          debugPrint('[Auth] ⏱️ Auto-retrieval timeout for: ${verificationId.substring(0, 10)}...');
          codeAutoRetrievalTimeout(verificationId);
        },
        timeout: const Duration(seconds: 60),
      );
    } catch (e) {
      debugPrint('[Auth] ❌ Exception during phone verification: $e');
      rethrow;
    }
  }

  Future<UserCredential> signInWithOtp(String verificationId, String smsCode) async {
    try {
      AuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final userCredential = await _auth.signInWithCredential(credential);
      await _updateUserData(userCredential.user!);
      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Update/Create User in Firestore (Using customers collection)
  Future<void> _updateUserData(User user) async {
    if (user.uid.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in _updateUserData');
      return;
    }

    final userDoc = _db.collection('customers').doc(user.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      debugPrint('[WRITE GUARD] Direct write blocked in _updateUserData');
      try {
        final user = _auth.currentUser;
        if (user == null) return;
        await user.getIdToken(true);
        
        
        final callable = FunctionsService.instance.httpsCallable('updateUserProfile');
        await callable.call({
          'email': user.email,
          'phone': user.phoneNumber,
          'name': user.displayName,
          'photoUrl': user.photoURL,
          'role': 'customer',
          'referralCode': _generateReferralCode(user.displayName ?? 'USER'),
        });
        debugPrint('✅ [Auth] Profile created via callable');
      } catch (e) {
        debugPrint('❌ [Auth] Profile creation failed: $e');
      }
    }
  }

  String _generateReferralCode(String name) {
    final random = Random();
    final String prefix = name.length >= 3 ? name.substring(0, 3).toUpperCase() : 'CUS';
    final int suffix = random.nextInt(9000) + 1000;
    return '$prefix$suffix';
  }

  Future<UserModel?> getUserData(String uid) async {
    final doc = await _db.collection('customers').doc(uid).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> updateProfile({String? name, String? photoUrl}) async {
    final user = _auth.currentUser;
    if (user == null || user.uid.isEmpty) {
      debugPrint('[PATH GUARD] blocked empty id in updateProfile');
      return;
    }
    
    if (name != null) await user.updateDisplayName(name);
    if (photoUrl != null) await user.updatePhotoURL(photoUrl);
    
    debugPrint('[WRITE GUARD] Direct write blocked in updateProfile');
    try {
      await user.getIdToken(true);
      
      
      final callable = FunctionsService.instance.httpsCallable('updateUserProfile');
      await callable.call({
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
      });
      debugPrint('✅ [Auth] Profile updated via callable');
    } catch (e) {
      debugPrint('❌ [Auth] Profile update failed: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Check if user has completed profile (has district selected)
  Future<bool> hasUserCompletedProfile(String uid) async {
    try {
      final doc = await _db.collection('customers').doc(uid).get();
      if (!doc.exists) return false;
      final data = doc.data();
      return data?['profileCompleted'] == true || 
             (data?['district']?.toString().isNotEmpty ?? false);
    } catch (e) {
      debugPrint('[AuthService] Error checking profile completion: $e');
      return false;
    }
  }
}
