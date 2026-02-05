import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firestore/technician_service.dart';
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

  TechnicianProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _fetchUserRole(user.uid);
        _fetchTechnicianData(user.uid);
      } else {
        _technician = null;
        _userRole = null;
        notifyListeners();
      }
    });
  }

  Future<void> _fetchUserRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _userRole = doc.data()?['role'] ?? 'customer';
      } else {
        // If no user document exists, treat as customer to trigger block screen
        _userRole = 'customer';
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching user role: $e");
      // On error, we still want to block access until we're sure
      _userRole = 'blocked'; 
      notifyListeners();
    }
  }

  Future<void> _fetchTechnicianData(String uid) async {
    _technician = await _techService.getTechnician(uid);
    notifyListeners();
  }

  Future<void> updateOnlineStatus(bool isOnline, {double? lat, double? lng}) async {
    if (_technician == null) return;
    await _techService.updateOnlineStatus(_technician!.uid, isOnline, lat: lat, lng: lng);
    _technician = await _techService.getTechnician(_technician!.uid);
    notifyListeners();
  }

  Future<void> onboard(List<String> skills, {double? lat, double? lng}) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _techService.saveTechnicianProfile(user, skills: skills, lat: lat, lng: lng);
    await _fetchTechnicianData(user.uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
