import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FcmTokenDebugScreen extends StatefulWidget {
  const FcmTokenDebugScreen({super.key});

  @override
  State<FcmTokenDebugScreen> createState() => _FcmTokenDebugScreenState();
}

class _FcmTokenDebugScreenState extends State<FcmTokenDebugScreen> {
  String? _fcmToken;
  String? _userId;
  bool _isLoading = false;
  String _status = 'Not initialized';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    _addLog('Initializing FCM debug...');
    
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _addLog('❌ No user logged in');
      setState(() => _status = 'Not logged in');
      return;
    }
    
    setState(() {
      _userId = user.uid;
      _status = 'User: ${user.uid.substring(0, 8)}...';
    });
    _addLog('✅ User ID: ${user.uid}');
    
    await _getFcmToken();
  }

  Future<void> _getFcmToken() async {
    try {
      _addLog('Requesting FCM token...');
      final token = await FirebaseMessaging.instance.getToken();
      
      if (token != null) {
        setState(() {
          _fcmToken = token;
          _status = 'Token received';
        });
        _addLog('✅ FCM Token: ${token.substring(0, 20)}...');
      } else {
        _addLog('❌ FCM token is null');
        setState(() => _status = 'Token is null');
      }
    } catch (e) {
      _addLog('❌ Error getting token: $e');
      setState(() => _status = 'Error: $e');
    }
  }

  Future<void> _saveFcmToken() async {
    if (_fcmToken == null) {
      _addLog('❌ No token to save');
      return;
    }

    setState(() => _isLoading = true);
    _addLog('Saving FCM token to Firestore...');

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('saveFcmToken');
      final result = await callable.call({
        'token': _fcmToken,
        'platform': 'android',
        'userType': 'customer',
      });

      _addLog('✅ Token saved: ${result.data}');
      setState(() => _status = 'Token saved');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ FCM Token saved'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _addLog('❌ Error saving token: $e');
      setState(() => _status = 'Save failed: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testNotification() async {
    if (_userId == null) {
      _addLog('❌ No user ID');
      return;
    }

    setState(() => _isLoading = true);
    _addLog('Sending test notification...');

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('sendNotificationToUser');
      final result = await callable.call({
        'userId': _userId,
        'userType': 'customer',
        'title': 'Test Notification',
        'body': 'FCM Debug Test',
        'data': {'type': 'test'},
      });

      _addLog('✅ Notification sent: ${result.data}');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Test notification sent'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      _addLog('❌ Error: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _addLog(String message) {
    setState(() {
      _logs.insert(0, '[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    debugPrint(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('FCM Token Debug'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _initialize)],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: $_status', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (_userId != null) Text('User: ${_userId!.substring(0, 12)}...'),
                if (_fcmToken != null) Text('Token: ${_fcmToken!.substring(0, 30)}...'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _getFcmToken,
                    icon: const Icon(Icons.token),
                    label: const Text('Get FCM Token'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _fcmToken == null ? null : _saveFcmToken,
                    icon: const Icon(Icons.save),
                    label: const Text('Save Token'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading || _userId == null ? null : _testNotification,
                    icon: const Icon(Icons.notifications),
                    label: const Text('Test Notification'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('Logs', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: _logs.isEmpty
                  ? const Center(child: Text('No logs yet', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              color: log.contains('❌') ? Colors.red : log.contains('✅') ? Colors.green : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
          if (_isLoading) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
