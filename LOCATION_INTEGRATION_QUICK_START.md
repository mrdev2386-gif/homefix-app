# 🚀 Location Detection - Quick Integration Guide

## Add to Any Screen in 3 Steps

### Step 1: Import the Service

```dart
import 'package:customer_app/core/services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
```

### Step 2: Create Service Instance

```dart
class YourScreen extends StatefulWidget {
  @override
  State<YourScreen> createState() => _YourScreenState();
}

class _YourScreenState extends State<YourScreen> {
  final LocationService _locationService = LocationService();
  String _currentAddress = 'No location';
  
  // ... rest of your code
}
```

### Step 3: Call the Method

```dart
Future<void> _handleDetectLocation() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login first')),
    );
    return;
  }

  final address = await _locationService.detectLocationWithUI(
    context: context,
    userId: user.uid,
  );

  if (address != null) {
    setState(() {
      _currentAddress = address.formattedAddress;
    });
  }
}
```

### Step 4: Add Button

```dart
ElevatedButton.icon(
  onPressed: _handleDetectLocation,
  icon: const Icon(Icons.my_location),
  label: const Text('Detect Location'),
)
```

---

## 🎯 That's It!

The `detectLocationWithUI()` method handles:
- ✅ Permission checks
- ✅ Loading dialog
- ✅ GPS fetch
- ✅ Reverse geocoding
- ✅ Firestore save
- ✅ Success dialog
- ✅ Error handling

---

## 📱 Example: Add to Dashboard

```dart
// In your dashboard_screen.dart

import 'package:customer_app/core/services/location_service.dart';

class DashboardScreen extends StatefulWidget {
  // ... existing code
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocationService _locationService = LocationService();
  
  // Add this method
  Future<void> _detectLocation() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final address = await _locationService.detectLocationWithUI(
      context: context,
      userId: user.uid,
    );

    if (address != null) {
      // Update your UI or state
      print('Location detected: ${address.formattedAddress}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ... your existing UI
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _detectLocation,
        icon: const Icon(Icons.my_location),
        label: const Text('Detect Location'),
      ),
    );
  }
}
```

---

## 🎨 Custom Button Styles

### Outlined Button
```dart
OutlinedButton.icon(
  onPressed: _handleDetectLocation,
  icon: const Icon(Icons.location_on),
  label: const Text('Use Current Location'),
  style: OutlinedButton.styleFrom(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  ),
)
```

### Text Button
```dart
TextButton.icon(
  onPressed: _handleDetectLocation,
  icon: const Icon(Icons.my_location, size: 18),
  label: const Text('Detect My Location'),
)
```

### Card with Icon
```dart
InkWell(
  onTap: _handleDetectLocation,
  child: Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Detect Location', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Find services near you', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    ),
  ),
)
```

---

## 🔄 Integration with Existing Location Provider

If you're using the existing `LocationProvider`:

```dart
import 'package:provider/provider.dart';
import 'package:customer_app/core/providers/location_provider.dart';
import 'package:customer_app/core/services/location_service.dart';

// In your widget
Future<void> _detectLocation() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final locationService = LocationService();
  final address = await locationService.detectLocationWithUI(
    context: context,
    userId: user.uid,
  );

  if (address != null && mounted) {
    // Update the provider if needed
    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    await locationProvider.loadSelectedAddress();
  }
}
```

---

## 📍 Display Current Location

```dart
class LocationDisplay extends StatelessWidget {
  final String address;
  final VoidCallback onTap;

  const LocationDisplay({
    required this.address,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                address,
                style: const TextStyle(fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.edit, size: 16),
          ],
        ),
      ),
    );
  }
}

// Usage
LocationDisplay(
  address: _currentAddress,
  onTap: _detectLocation,
)
```

---

## 🎯 Common Use Cases

### 1. Service Booking Screen
```dart
// Show location before booking
ElevatedButton(
  onPressed: () async {
    final address = await _locationService.detectLocationWithUI(
      context: context,
      userId: user.uid,
    );
    
    if (address != null) {
      // Proceed with booking
      _bookService(address);
    }
  },
  child: const Text('Book Service'),
)
```

### 2. Profile Setup
```dart
// During onboarding
ListTile(
  leading: const Icon(Icons.location_on),
  title: const Text('Add Your Location'),
  subtitle: Text(_currentAddress),
  trailing: const Icon(Icons.arrow_forward),
  onTap: _detectLocation,
)
```

### 3. Search Nearby Services
```dart
// Before searching
FloatingActionButton(
  onPressed: () async {
    final address = await _locationService.detectLocationWithUI(
      context: context,
      userId: user.uid,
    );
    
    if (address != null) {
      _searchNearbyServices(address.latitude, address.longitude);
    }
  },
  child: const Icon(Icons.search),
)
```

---

## ⚡ Performance Tips

1. **Cache the result** - Don't fetch on every screen load
2. **Show last known location** - Load from Firestore first
3. **Debounce requests** - Prevent multiple simultaneous calls

```dart
bool _isDetecting = false;

Future<void> _detectLocation() async {
  if (_isDetecting) return; // Prevent duplicate calls
  
  _isDetecting = true;
  try {
    final address = await _locationService.detectLocationWithUI(
      context: context,
      userId: user.uid,
    );
    // Handle result...
  } finally {
    _isDetecting = false;
  }
}
```

---

## 🎉 You're Done!

The location detection system is now integrated and ready to use. All dialogs, error handling, and Firebase persistence are handled automatically.
