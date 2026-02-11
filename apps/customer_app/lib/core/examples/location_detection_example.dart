import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/location_service.dart';

/// Example widget showing how to use the complete location detection system
class LocationDetectionExample extends StatefulWidget {
  const LocationDetectionExample({super.key});

  @override
  State<LocationDetectionExample> createState() => _LocationDetectionExampleState();
}

class _LocationDetectionExampleState extends State<LocationDetectionExample> {
  final LocationService _locationService = LocationService();
  String _displayAddress = 'No location detected yet';

  Future<void> _detectLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login first')),
      );
      return;
    }

    // This single method handles everything:
    // - Permission checks
    // - Loading dialog
    // - GPS fetch
    // - Reverse geocoding
    // - Firestore save
    // - Success dialog
    // - Error handling
    final address = await _locationService.detectLocationWithUI(
      context: context,
      userId: user.uid,
    );

    if (address != null) {
      setState(() {
        _displayAddress = address.formattedAddress;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Detection'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Current Location',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _displayAddress,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _detectLocation,
                icon: const Icon(Icons.my_location),
                label: const Text('Detect Location'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
