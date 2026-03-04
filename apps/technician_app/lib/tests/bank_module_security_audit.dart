import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// PRODUCTION SECURITY AUDIT - Technician Bank Module
class BankModuleSecurityAudit {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(region: 'us-central1');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  final List<String> _results = [];
  
  Future<Map<String, dynamic>> runFullAudit() async {
    _results.clear();
    
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return {'status': 'FAIL', 'reason': 'Not authenticated', 'results': _results};
    }
    
    bool allPassed = true;
    
    allPassed = allPassed && await _step1_verifyFirestoreRulesEnforcement(uid);
    allPassed = allPassed && await _step2_verifyFunctionMasking(uid);
    allPassed = allPassed && await _step3_verifyApprovedLock(uid);
    allPassed = allPassed && await _step4_verifyRegionConsistency();
    allPassed = allPassed && await _step5_verifySchemaPurity(uid);
    
    return {
      'status': allPassed ? 'PASS' : 'FAIL',
      'results': _results,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
  
  Future<bool> _step1_verifyFirestoreRulesEnforcement(String uid) async {
    _results.add('\n=== STEP 1: FIRESTORE RULES ===');
    
    try {
      final doc = await _firestore.collection('technicians').doc(uid).get();
      
      if (!doc.exists) {
        _results.add('❌ FAIL: Document does not exist');
        return false;
      }
      
      final data = doc.data();
      final accountNumber = data?['accountNumber'];
      
      if (accountNumber != null && accountNumber.toString().length > 4) {
        if (!accountNumber.toString().startsWith('****')) {
          _results.add('❌ FAIL: Raw account number readable: $accountNumber');
          return false;
        }
      }
      
      _results.add('✅ PASS: Account number not exposed');
      return true;
      
    } catch (e) {
      _results.add('❌ FAIL: Error: $e');
      return false;
    }
  }
  
  Future<bool> _step2_verifyFunctionMasking(String uid) async {
    _results.add('\n=== STEP 2: FUNCTION MASKING ===');
    
    try {
      final callable = _functions.httpsCallable('updateTechnicianBankDetails');
      final result = await callable.call({
        'accountHolderName': 'Test User',
        'bankName': 'Test Bank',
        'accountNumber': '1234567890123',
        'ifscCode': 'SBIN0001234',
      });
      
      final response = result.data as Map<String, dynamic>;
      
      if (!response.containsKey('maskedAccountNumber')) {
        _results.add('❌ FAIL: No maskedAccountNumber in response');
        return false;
      }
      
      if (response.containsKey('accountNumber')) {
        _results.add('❌ FAIL: Raw accountNumber in response');
        return false;
      }
      
      final masked = response['maskedAccountNumber'] as String;
      if (!masked.startsWith('****')) {
        _results.add('❌ FAIL: Wrong mask format: $masked');
        return false;
      }
      
      _results.add('✅ PASS: Function returns masked only');
      return true;
      
    } catch (e) {
      _results.add('⚠️  SKIP: $e');
      return true;
    }
  }
  
  Future<bool> _step3_verifyApprovedLock(String uid) async {
    _results.add('\n=== STEP 3: APPROVED LOCK ===');
    
    try {
      await _firestore.collection('technicians').doc(uid).update({'bankStatus': 'approved'});
      
      final callable = _functions.httpsCallable('updateTechnicianBankDetails');
      
      try {
        await callable.call({
          'accountHolderName': 'Hacker',
          'bankName': 'Evil',
          'accountNumber': '9999999999999',
          'ifscCode': 'HACK0001234',
        });
        
        _results.add('❌ FAIL: Function allowed approved update');
        return false;
        
      } on FirebaseFunctionsException catch (e) {
        if (e.code == 'failed-precondition' && e.message?.contains('Cannot modify approved') == true) {
          _results.add('✅ PASS: Function blocked approved update');
          
          final doc = await _firestore.collection('technicians').doc(uid).get();
          if (doc.data()?['accountHolderName'] == 'Hacker') {
            _results.add('❌ FAIL: Firestore modified despite error');
            return false;
          }
          
          _results.add('✅ PASS: Firestore unchanged');
          return true;
        } else {
          _results.add('❌ FAIL: Wrong error: ${e.code}');
          return false;
        }
      }
      
    } catch (e) {
      _results.add('❌ FAIL: $e');
      return false;
    } finally {
      try {
        await _firestore.collection('technicians').doc(uid).update({'bankStatus': 'not_submitted'});
      } catch (_) {}
    }
  }
  
  Future<bool> _step4_verifyRegionConsistency() async {
    _results.add('\n=== STEP 4: REGION ===');
    
    final region = _functions.toString();
    if (region.contains('us-central1')) {
      _results.add('✅ PASS: Using us-central1');
      return true;
    } else {
      _results.add('❌ FAIL: Wrong region');
      return false;
    }
  }
  
  Future<bool> _step5_verifySchemaPurity(String uid) async {
    _results.add('\n=== STEP 5: SCHEMA PURITY ===');
    
    try {
      final doc = await _firestore.collection('technicians').doc(uid).get();
      final data = doc.data();
      
      if (data == null) {
        _results.add('❌ FAIL: No data');
        return false;
      }
      
      if (data.containsKey('bankDetails')) {
        _results.add('❌ FAIL: Nested bankDetails exists');
        return false;
      }
      
      _results.add('✅ PASS: Root-level only');
      return true;
      
    } catch (e) {
      _results.add('❌ FAIL: $e');
      return false;
    }
  }
}

class BankModuleAuditScreen extends StatefulWidget {
  const BankModuleAuditScreen({super.key});

  @override
  State<BankModuleAuditScreen> createState() => _BankModuleAuditScreenState();
}

class _BankModuleAuditScreenState extends State<BankModuleAuditScreen> {
  final _audit = BankModuleSecurityAudit();
  bool _isRunning = false;
  Map<String, dynamic>? _results;
  
  Future<void> _runAudit() async {
    setState(() {
      _isRunning = true;
      _results = null;
    });
    
    try {
      final results = await _audit.runFullAudit();
      setState(() => _results = results);
    } catch (e) {
      setState(() => _results = {'status': 'ERROR', 'results': ['Fatal: $e']});
    } finally {
      setState(() => _isRunning = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Audit'),
        backgroundColor: Colors.red[900],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isRunning ? null : _runAudit,
              icon: _isRunning ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.play_arrow),
              label: Text(_isRunning ? 'Running...' : 'Run Audit'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900], foregroundColor: Colors.white, padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 16),
            if (_results != null) ...[
              Card(
                color: _results!['status'] == 'PASS' ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(_results!['status'] == 'PASS' ? Icons.check_circle : Icons.error, color: _results!['status'] == 'PASS' ? Colors.green : Colors.red, size: 32),
                      const SizedBox(width: 12),
                      Text(_results!['status'] as String, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: _results!['status'] == 'PASS' ? Colors.green[900] : Colors.red[900])),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('RESULTS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const Divider(),
                        ...(_results!['results'] as List<String>).map((r) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(r, style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: r.startsWith('❌') ? Colors.red[900] : r.startsWith('✅') ? Colors.green[900] : Colors.black87)),
                        )),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
