import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint("HOMESCREEN RENDERED ✅");
    return Scaffold(
      appBar: AppBar(title: const Text('Home Screen')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'HOME SCREEN RENDERED ✅',
              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            SizedBox(height: 20),
            Text('Welcome to HomeFix Customer App'),
          ],
        ),
      ),
    );
  }
}
