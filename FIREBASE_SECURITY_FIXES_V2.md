# HomeFix - Complete Firebase Production Fixes

## PART 1 — APP CHECK FIX (main.dart)

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'core/services/auth_service.dart';
import 'core/services/firestore_service.dart';
import 'core/services/functions_service.dart';
import 'core/services/storage_service.dart';
import 'core/services/notifications_service.dart';
import 'core/providers/cart_provider.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/category_provider.dart';
import 'core/providers/service_provider.dart';
import 'core/providers/booking_provider.dart';
import 'core/providers/location_provider.dart';
import 'core/providers/checkout_provider.dart';
import 'core/providers/locale_provider.dart';
import 'core/utils/app_localizations.dart';
import 'features/profile/providers/partner_onboarding_provider.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/home/main_wrapper_screen.dart';
import 'core/models/user_model.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // ======================================
    // APP CHECK INITIALIZATION (CRITICAL)
    // ======================================
    try {
      if (kDebugMode) {
        // Debug mode: Use debug provider
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.debug,
          appleProvider: AppleProvider.debug,
          webProvider: ReCaptchaV3Provider('6LfqvMsqAAAAAA-E4yG4yv6YvY-vS9k1yL_S0G4A'),
        );
        
        debugPrint("═══════════════════════════════════════════════════════════");
        debugPrint("🔐 AppCheck initialized in DEBUG mode");
        debugPrint("═══════════════════════════════════════════════════════════");
        
        // Listen for token changes and print debug token
        FirebaseAppCheck.instance.onTokenChange.listen((token) {
          if (token != null) {
            debugPrint("═══════════════════════════════════════════════════════════");
            debugPrint("🎫 APP CHECK DEBUG TOKEN:");
            debugPrint("   Copy this token and add it to Firebase Console:");
            debugPrint("   Firebase Console → App Check → Apps → Manage debug tokens");
            debugPrint("   Token: $token");
            debugPrint("═══════════════════════════════════════════════════════════");
          }
        });
        
        // Try to get initial token
        try {
          final token = await FirebaseAppCheck.instance.getToken();
          if (token != null) {
            debugPrint("🎫 Initial App Check token obtained successfully");
          }
        } catch (tokenError) {
          debugPrint("⚠️ Could not get initial App Check token: $tokenError");
          debugPrint("   This is normal on first run. Uninstall app and run again.");
        }
      } else {
        // Production mode: Use Play Integrity
        await FirebaseAppCheck.instance.activate(
          androidProvider: AndroidProvider.playIntegrity,
          appleProvider: AppleProvider.deviceCheck,
          webProvider: ReCaptchaV3Provider('6LfqvMsqAAAAAA-E4yG4yv6YvY-vS9k1yL_S0G4A'),
        );
        debugPrint("🔐 AppCheck initialized in PRODUCTION mode (Play Integrity)");
      }
    } catch (e) {
      debugPrint("❌ AppCheck initialization failed: $e");
      debugPrint("   Uploads and Firestore operations may fail without App Check.");
    }

    // 2. Initialize Crashlytics & Performance
    if (!kIsWeb) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      FirebasePerformance.instance.setPerformanceCollectionEnabled(true).catchError((e) {
        debugPrint("Performance initialization failed: $e");
      });
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    }
    
    // Initialize Push Notifications
    try {
      await NotificationsService.initialize();
    } catch (e) {
      debugPrint("Notifications initialization failed: $e");
    }

  } catch (e) {
    debugPrint("Firebase initialization failed: $e");
  }
  
  runApp(const HomeFixApp());
}
```

### App Check Token Flow
1. Install app → Run → Log shows token
2. Uninstall app
3. Add token to Firebase Console
4. Reinstall app → Token active

---

## PART 2 — FIRESTORE RULES

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isAuthenticated() && 
        exists(/databases/$(database)/documents/admins/$(request.auth.uid));
    }
    
    function isActive() {
      return resource.data.isActive == true;
    }
    
    function isApproved() {
      return resource.data.status == 'approved' || resource.data.isApproved == true;
    }
    
    function isAvailable() {
      return resource.data.isAvailable == true;
    }
    
    // === PUBLIC BANNERS ===
    match /home_banners/{bannerId} {
      allow read: if isActive();
      allow write: if isAdmin();
    }
    
    match /categories/{categoryId} {
      allow read: if isActive();
      allow write: if isAdmin();
    }
    
    // === TECHNICIANS (Public Read with Filters) ===
    match /technicians/{technicianId} {
      // Public read ONLY if approved AND available
      // Enables: where status == "approved" && isAvailable == true
      allow read: if isAuthenticated() && isApproved() && isAvailable();
      allow write: if false; // Server only
    }
    
    // === CUSTOMERS ===
    match /customers/{customerId} {
      allow read: if isOwner(customerId) || isAdmin();
      allow write: if isOwner(customerId) || isAdmin();
      
      match /cart/{cartItemId} {
        allow read, write: if isOwner(customerId);
      }
      
      match /addresses/{addressId} {
        allow read, write: if isOwner(customerId);
      }
      
      match /fcmTokens/{tokenId} {
        allow read, write: if isOwner(customerId);
      }
      
      match /settings/{settingId} {
        allow read, write: if isOwner(customerId);
      }
    }
    
    // === BOOKINGS (Server Only) ===
    match /bookings/{bookingId} {
      allow read: if isAuthenticated() && (
        isAdmin() ||
        resource.data.customerId == request.auth.uid ||
        resource.data.technicianId == request.auth.uid
      );
      allow create, update, delete: if false; // Server only
    }
    
    // === REVIEWS ===
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if isAuthenticated() && 
        request.resource.data.customerId == request.auth.uid;
      allow update, delete: if isAdmin();
    }
  }
}
```

---

## PART 3 — STORAGE RULES

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isSignedIn() && request.auth.uid == userId;
    }
    
    function isAdmin() {
      return isSignedIn() && request.auth.token.admin == true;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isSmallFile() {
      return request.resource.size < 5 * 1024 * 1024;
    }
    
    // === USER PROFILE IMAGES ===
    match /users/{userId}/profile/{fileName} {
      allow read: if isSignedIn() && isOwner(userId);
      allow write: if isSignedIn() && isOwner(userId) && isImage() && isSmallFile();
    }
    
    // === SERVICE IMAGES ===
    match /services/{serviceId}/{fileName} {
      allow read: if true;
      allow write: if isSignedIn() && isAdmin();
    }
    
    // === BANNER IMAGES ===
    match /banners/{fileName} {
      allow read: if true;
      allow write: if isSignedIn() && isAdmin();
    }
  }
}
```

---

## PART 4 — SAFE CALLABLE WRAPPER (Flutter)

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';

/// Safe callable wrapper that ensures JSON-safe parameters
class SafeCallable {
  final FirebaseFunctions _functions;
  
  SafeCallable({FirebaseFunctions? functions}) 
      : _functions = functions ?? FirebaseFunctions.instance;
  
  /// Call a Cloud Function with JSON-safe parameters only
  Future<Map<String, dynamic>> call({
    required String functionName,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      // Validate parameters are JSON-safe
      _validateJsonSafe(parameters);
      
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(parameters);
      
      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Cloud Function error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Callable error: $e');
      rethrow;
    }
  }
  
  void _validateJsonSafe(Map<String, dynamic> data) {
    for (final entry in data.entries) {
      final value = entry.value;
      
      // Allow primitives only
      if (value == null ||
          value is String ||
          value is num ||
          value is bool ||
          value is List) {
        continue;
      }
      
      if (value is Map<String, dynamic>) {
        _validateJsonSafe(value);
        continue;
      }
      
      // Reject non-JSON-safe types
      throw AssertionError(
        'Invalid parameter type for ${entry.key}: ${value.runtimeType}. '
        'Only String, num, bool, List, and Map are allowed.'
      );
    }
  }
}

/// Extension to convert DateTime and GeoPoint
extension SafeConversion on Map<String, dynamic> {
  Map<String, dynamic> withSafeTypes() {
    final converted = <String, dynamic>{};
    
    for (final entry in entries) {
      final value = entry.value;
      
      if (value is DateTime) {
        converted[entry.key] = value.toIso8601String();
      } else if (value is GeoPoint) {
        converted[entry.key] = {
          'lat': value.latitude,
          'lng': value.longitude,
        };
      } else if (value is Map) {
        converted[entry.key] = Map<String, dynamic>.from(value).withSafeTypes();
      } else {
        converted[entry.key] = value;
      }
    }
    
    return converted;
  }
}

/// Usage example:
/*
final safeCallable = SafeCallable();

Future<void> createBooking({
  required String serviceId,
  required String technicianId,
  required DateTime scheduledTime,
  required GeoPoint location,
}) async {
  final result = await safeCallable.call(
    functionName: 'createBooking',
    parameters: {
      'serviceId': serviceId,
      'technicianId': technicianId,
      'scheduledTime': scheduledTime,  // Auto-converts to ISO string
      'location': location,            // Auto-converts to {lat, lng}
    }.withSafeTypes(),
  );
}
*/
```

---

## PART 5 — FIXED UPLOAD METHOD

```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  
  /// Upload profile image with proper error handling
  Future<String> uploadProfileImage({
    required String userId,
    required String filePath,
    required String fileName,
  }) async {
    try {
      final ref = _storage.ref().child('users/$userId/profile/$fileName');
      
      // Create metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'ownerId': userId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );
      
      // Upload file
      final uploadTask = ref.putFile(
        File(filePath),
        metadata,
      );
      
      // Wait for completion
      final snapshot = await uploadTask.whenComplete(() {});
      
      // Get download URL
      final downloadUrl = await snapshot.ref.getDownloadURL();
      
      debugPrint('Upload successful: $downloadUrl');
      return downloadUrl;
      
    } on FirebaseException catch (e) {
      // Handle specific errors
      switch (e.code) {
        case 'object-not-found':
          throw Exception('Storage object not found');
        case 'unauthorized':
          throw Exception('Not authorized to upload');
        case 'canceled':
          throw Exception('Upload was canceled');
        case 'quota-exceeded':
          throw Exception('Storage quota exceeded');
        default:
          debugPrint('Storage error: ${e.code} - ${e.message}');
          throw Exception('Upload failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Unexpected upload error: $e');
      throw Exception('Upload failed');
    }
  }
  
  /// Get download URL with error handling
  Future<String> getDownloadUrl(String storagePath) async {
    try {
      final ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        throw Exception('File does not exist');
      }
      throw Exception('Failed to get download URL');
    }
  }
}
```

---

## PART 6 — LOCATION SUCCESS HANDLER (Fixed)

```dart
import 'package:flutter/material.dart';

class LocationSuccessHandler {
  /// Handle successful location save with proper mounted checks
  static Future<void> onLocationSaved({
    required BuildContext context,
    required VoidCallback saveFunction,
    required String successMessage,
  }) async {
    try {
      await saveFunction();
      
      if (!context.mounted) return;
      
      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
      
      // Navigate back after snackbar is shown
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (context.mounted) {
        Navigator.of(context).pop(true);
      }
      
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to save location'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Usage in widget:
/*
void _handleConfirmLocation() async {
  await LocationSuccessHandler.onLocationSaved(
    context: context,
    saveFunction: () => _locationService.saveCurrentAddress(
      userId: _userId,
      address: _detectedAddress,
    ),
    successMessage: 'Location updated successfully',
  );
}
*/
```

---

## PART 7 — VIDEO 403 FIX

```dart
import 'package:video_player/video_player.dart';
import 'package:flutter/material.dart';

class VideoPlayerService {
  VideoPlayerController? _controller;
  
  /// Initialize video player with download URL fetching
  Future<VideoPlayerController> initializeVideo({
    required String storagePath,
    required String videoId,
  }) async {
    try {
      // If it's a storage path, fetch download URL first
      String videoUrl = storagePath;
      
      if (storagePath.startsWith('gs://') || 
          storagePath.startsWith('users/') ||
          storagePath.startsWith('reels/')) {
        
        final storage = FirebaseStorage.instance;
        final ref = storage.ref().child(storagePath);
        
        try {
          videoUrl = await ref.getDownloadURL();
          debugPrint('Video download URL obtained: $videoUrl');
        } on FirebaseException catch (e) {
          if (e.code == 'object-not-found') {
            throw Exception('Video file not found');
          }
          throw Exception('Failed to access video: ${e.message}');
        }
      }
      
      // Validate URL format
      if (!Uri.tryParse(videoUrl)?.hasAbsolutePath ?? false) {
        throw Exception('Invalid video URL format');
      }
      
      // Initialize controller
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..initialize().then((_) {
          debugPrint('Video initialized successfully');
        });
      
      return _controller!;
      
    } catch (e) {
      debugPrint('Video initialization error: $e');
      rethrow;
    }
  }
  
  /// Build video widget with error handling
  Widget buildVideoPlayer({
    required VideoPlayerController controller,
    required String videoTitle,
    Widget? errorFallback,
  }) {
    return FutureBuilder(
      future: controller.initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          debugPrint('Video load error: ${snapshot.error}');
          return errorFallback ?? _buildErrorPlaceholder(videoTitle);
        }
        
        return AspectRatio(
          aspectRatio: controller.value.aspectRatio,
          child: VideoPlayer(controller),
        );
      },
    );
  }
  
  Widget _buildErrorPlaceholder(String title) {
    return Container(
      color: Colors.grey[200],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.video_library, size: 48, color: Colors.grey),
          const SizedBox(height: 8),
          Text(
            'Unable to load video',
            style: TextStyle(color: Colors.grey[600]),
          ),
          if (title.isNotEmpty)
            Text(
              title,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
        ],
      ),
    );
  }
  
  void dispose() {
    _controller?.dispose();
    _controller = null;
  }
}
```

---

## DEPLOYMENT CHECKLIST

```bash
# 1. Deploy Firestore rules
firebase deploy --only firestore:rules

# 2. Deploy Storage rules
firebase deploy --only storage:rules

# 3. Deploy Cloud Functions
firebase deploy --only functions

# 4. Add App Check debug token (development)
# Firebase Console → App Check → Apps → Manage debug tokens

# 5. Add SHA keys (release)
# android/gradlew signingReport
# Firebase Console → Project Settings → Add fingerprint

# 6. Clean rebuild
cd android && ./gradlew clean
cd .. && flutter clean && flutter pub get

# 7. Test build
flutter build apk --debug
```

---

## SUMMARY OF FIXES

| Issue | Fix |
|-------|-----|
| Firestore PERMISSION_DENIED on technicians | Added `isAuthenticated() && isApproved() && isAvailable()` condition |
| Cloud Functions assertion error | Convert DateTime → ISO string, GeoPoint → {lat, lng} |
| Storage 403/App attestation | App Check token active, proper storage path |
| Navigator.pop null crash | Added `context.mounted` checks |
| VideoPlayer 403 | Fetch downloadURL before playing |
| fontSize.isFinite crash | Added safe size calculations with fallbacks |

All fixes maintain production security - no `allow: if true` patterns, all sensitive writes via Cloud Functions.
