import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../services/technician_service.dart';
import '../models/technician.dart';

class TechnicianProvider extends ChangeNotifier {
  final TechnicianService _techService = TechnicianService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Technician? _technician;
  Technician? get technician => _technician;

  String? _userRole;
  String? get userRole => _userRole;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  StreamSubscription<DocumentSnapshot>? _roleSubscription;
  StreamSubscription<Technician?>? _techSubscription;

  TechnicianProvider() {
    _auth.authStateChanges().listen((user) {
      _roleSubscription?.cancel();
      _techSubscription?.cancel();
      
      if (user != null) {
        _listenToUserRole(user.uid);
        _listenToTechnicianData(user.uid);
      } else {
        _technician = null;
        _userRole = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  void _listenToUserRole(String uid) {
    _roleSubscription = _db.collection('users').doc(uid).snapshots().listen((doc) {
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'customer';
      } else {
        _userRole = 'customer';
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to user role: $e");
    });
  }

  void _listenToTechnicianData(String uid) {
    _isLoading = true;
    notifyListeners();
    
    _techSubscription = _techService.getTechnicianStream(uid).listen((tech) {
      _technician = tech;
      _isLoading = false;
      notifyListeners();
    }, onError: (e) {
      debugPrint("Error listening to tech data: $e");
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    if (_technician == null) return;
    
    if (isOnline && !_auth.currentUser!.emailVerified) {
        throw Exception("Please verify your email address first.");
    }

    await _techService.updateOnlineStatus(_technician!.uid, isOnline);
    // Stream takes care of local update
  }



  Future<void> submitApplication({
    required String fullName,
    required String email,
    required int experienceYears,
    required String primaryCategoryId,
    required String documentType,
    required String frontImage,
    required String backImage,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final callable = FirebaseFunctions.instance.httpsCallable('submitTechnicianApplication');
      final result = await callable.call({
        'fullName': fullName,
        'email': email,
        'experienceYears': experienceYears,
        'primaryCategoryId': primaryCategoryId,
        'documentType': documentType,
        'frontImage': frontImage,
        'backImage': backImage,
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Failed to submit application');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> onboard(List<String> skills) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _techService.saveTechnicianProfile(user, skills: skills);
  }

  Future<void> signOut() async {
    _roleSubscription?.cancel();
    _techSubscription?.cancel();
    await _auth.signOut();
  }

  @override
  void dispose() {
    _roleSubscription?.cancel();
    _techSubscription?.cancel();
    super.dispose();
  }
}
