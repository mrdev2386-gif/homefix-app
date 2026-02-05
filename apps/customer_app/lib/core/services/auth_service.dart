import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
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
    } catch (e) {
      rethrow;
    }
  }

  // Phone Auth
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Function(PhoneAuthCredential) verificationCompleted,
    required Function(FirebaseAuthException) verificationFailed,
    required Function(String, int?) codeSent,
    required Function(String) codeAutoRetrievalTimeout,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      timeout: const Duration(seconds: 60),
    );
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
    final userDoc = _db.collection('customers').doc(user.uid);
    final doc = await userDoc.get();

    if (!doc.exists) {
      final newUser = UserModel(
        uid: user.uid,
        email: user.email,
        phone: user.phoneNumber,
        name: user.displayName,
        photoUrl: user.photoURL,
        createdAt: DateTime.now(),
        role: 'customer',
        referralCode: _generateReferralCode(user.displayName ?? 'USER'),
      );
      await userDoc.set(newUser.toMap());
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
    if (user != null) {
      if (name != null) await user.updateDisplayName(name);
      if (photoUrl != null) await user.updatePhotoURL(photoUrl);
      
      await _db.collection('customers').doc(user.uid).update({
        if (name != null) 'name': name,
        if (photoUrl != null) 'photoUrl': photoUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
