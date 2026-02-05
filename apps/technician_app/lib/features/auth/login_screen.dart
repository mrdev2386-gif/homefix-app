import 'package:flutter/material.dart';

class TechnicianLoginScreen extends StatelessWidget {
  const TechnicianLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.indigo.shade50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.engineering, size: 80, color: Colors.indigo),
              const SizedBox(height: 32),
              const Text("Partner App", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/dashboard');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: const Text("Login as Technician"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
