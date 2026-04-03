import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  String result = "Not tested";
  bool isLoading = false;

  Future<void> testFunction() async {
    setState(() {
      isLoading = true;
      result = "Testing...";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          result = "❌ User not logged in";
          isLoading = false;
        });
        return;
      }

      final token = await user.getIdToken(true);

      print("🔥 UID: ${user.uid}");
      print("🔥 EMAIL: ${user.email}");
      print("🔥 TOKEN LENGTH: ${token?.length ?? 0}");
      print("🔥 TOKEN PREVIEW: ${token?.substring(0, 50)}...");

      final functions = FirebaseFunctions.instanceFor(region: 'asia-south1');

      final response = await functions.httpsCallable('testAuth').call({
        "test": true,
        "timestamp": DateTime.now().toIso8601String(),
      });

      setState(() {
        result = "✅ SUCCESS\n\nUID: ${response.data['uid']}\n\nFull Response: ${response.data}";
        isLoading = false;
      });
    } catch (e) {
      print("❌ ERROR: $e");
      setState(() {
        result = "❌ ERROR:\n\n$e";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Firebase Auth Test"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Current User:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text("UID: ${user?.uid ?? 'Not logged in'}"),
                    Text("Email: ${user?.email ?? 'N/A'}"),
                    Text("Phone: ${user?.phoneNumber ?? 'N/A'}"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : testFunction,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.blue,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "TEST CLOUD FUNCTION",
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    result,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
