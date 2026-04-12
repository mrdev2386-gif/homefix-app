import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    print('[TEST] Initializing Firebase...');
    
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('[TEST] Firebase initialized');
    
    runApp(const TestApp());
  } catch (e, stackTrace) {
    print('[TEST CRASH] $e');
    print('[TEST CRASH] $stackTrace');
  }
}

class TestApp extends StatelessWidget {
  const TestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('TEST SCREEN - App is running'),
              const SizedBox(height: 20),
              Text('Time: ${DateTime.now()}'),
            ],
          ),
        ),
      ),
    );
  }
}
