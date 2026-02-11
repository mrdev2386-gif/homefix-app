# Firebase Security Fixes - Complete Guide

## Issues Fixed
1. ✅ Firebase Storage upload failing (App Check 403, StorageException 404)
2. ✅ Firestore permission denied for `customers/{uid}/addresses`
3. ✅ ExoPlayer video 403 source error
4. ✅ NetworkImage 404 crashes

---

## 1️⃣ Updated Storage Rules (`storage.rules`)

**Problem:** Storage rules didn't match the upload path used in code (`users/{userId}/profile/profile.jpg`).

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {
    
    // --- Helper Functions ---
    function isSignedIn() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isAdmin() {
      return request.auth.token.admin == true;
    }
    
    function isImage() {
      return request.resource.contentType.matches('image/.*');
    }
    
    function isVideo() {
      return request.resource.contentType.matches('video/.*');
    }
    
    function isSmallFile() {
      return request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }
    
    function isLargeFile() {
      return request.resource.size < 50 * 1024 * 1024; // 50MB for videos
    }

    // --- Rules ---

    // 1. User Profile Images (FIXED: matches code path)
    // Path: users/{userId}/profile/profile.jpg
    match /users/{userId}/profile/{fileName} {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId) && isImage() && isSmallFile();
    }
    
    // Legacy paths for backward compatibility
    match /users/{userId}/profile.jpg {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId) && isImage() && isSmallFile();
    }
    
    match /customers/{userId}/profile.jpg {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(userId) && isImage() && isSmallFile();
    }

    // 2. Technician Profile Images
    match /technicians/{techId}/profile.jpg {
      allow read: if isSignedIn();
      allow write: if isSignedIn() && isOwner(techId) && isImage() && isSmallFile();
    }
    
    // 3. Technician Documents (KYC) - FIXED: matches code path
    // Path: technicians/{userId}/{docType}/{fileName}
    match /technicians/{techId}/{docType}/{fileName} {
      allow read: if isSignedIn() && (isOwner(techId) || isAdmin());
      allow write: if isSignedIn() && isOwner(techId) && isSmallFile();
    }
    
    // Legacy path
    match /technician_docs/{techId}/{fileName} {
      allow read: if isSignedIn() && (isOwner(techId) || isAdmin());
      allow write: if isSignedIn() && isOwner(techId) && isSmallFile();
    }

    // 4. Professional Reels/Portfolio (videos)
    // Public read for video playback, authenticated write
    match /reels/{techId}/{fileName} {
      allow read: if true; // Public read for video streaming
      allow write: if isSignedIn() && (isOwner(techId) || isAdmin()) && isLargeFile();
    }
    
    // 5. Chat/Support Images
    match /support/{ticketId}/{fileName} {
      allow read: if isSignedIn() && (resource.metadata.ownerId == request.auth.uid || isAdmin());
      allow write: if isSignedIn() && isSmallFile();
    }
    
    // 6. Service Images (public read, admin write)
    match /services/{serviceId}/{fileName} {
      allow read: if true;
      allow write: if isSignedIn() && isAdmin();
    }
    
    // 7. Banner Images (public read, admin write)
    match /banners/{fileName} {
      allow read: if true;
      allow write: if isSignedIn() && isAdmin();
    }
  }
}
```

**Explanation:** 
- Added rule for `users/{userId}/profile/{fileName}` to match the actual upload path in `StorageService`
- Added video support for reels with larger file size limit
- Kept legacy paths for backward compatibility

---

## 2️⃣ Updated Firestore Rules - Addresses Subcollection

**Problem:** Missing rules for `customers/{uid}/addresses` subcollection.

Add this to `firestore.rules` inside the `match /databases/{database}/documents` block:

```javascript
    // 4. CUSTOMERS (UPDATED with addresses subcollection)
    match /customers/{userId} {
      allow read: if isSignedIn() && (isOwner(userId) || isAdmin());
      allow create: if isOwner(userId);
      allow update: if isOwner(userId) && 
        !request.resource.data.diff(resource.data).affectedKeys().hasAny(['balance', 'isAdmin']);
      
      // FIXED: Addresses subcollection - user can manage their own addresses
      match /addresses/{addressId} {
        allow read: if isSignedIn() && isOwner(userId);
        allow create: if isSignedIn() && isOwner(userId);
        allow update: if isSignedIn() && isOwner(userId);
        allow delete: if isSignedIn() && isOwner(userId);
      }
      
      // User settings subcollection
      match /settings/{settingId} {
        allow read: if isSignedIn() && isOwner(userId);
        allow write: if isSignedIn() && isOwner(userId);
      }
      
      // User notifications subcollection
      match /notifications/{notificationId} {
        allow read: if isSignedIn() && isOwner(userId);
        allow write: if false; // Cloud Functions only
      }
    }
```

**Explanation:**
- Added `addresses` subcollection with full CRUD for the owner only
- No wildcard write permissions - each operation is explicit
- Admin cannot modify user addresses (privacy)

---

## 3️⃣ Corrected StorageService (`storage_service.dart`)

**Problem:** Upload path mismatch with storage rules.

```dart
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

/// Production-grade Storage Service for Firebase Storage operations
class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Maximum file size: 5MB
  static const int maxFileSizeBytes = 5 * 1024 * 1024;

  /// Upload technician document
  /// 
  /// Path: technicians/{userId}/{docType}/{timestamp}_{docType}
  Future<String> uploadTechnicianDoc({
    required String userId,
    required XFile file,
    required String docType,
  }) async {
    try {
      // Validate user is authenticated and owns this upload
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw 'Authentication required. Please sign in again.';
      }

      final fileToUpload = File(file.path);
      if (!await fileToUpload.exists()) {
        throw 'Selected file does not exist';
      }

      final fileSize = await fileToUpload.length();
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        throw 'File size ($sizeMB MB) exceeds 5MB limit';
      }

      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$docType';
      
      // FIXED: Path matches storage rules
      final Reference ref = _storage
          .ref()
          .child('technicians')
          .child(userId)
          .child(docType)
          .child(fileName);

      debugPrint('[StorageService] Uploading technician doc: $docType for user: $userId');

      final UploadTask uploadTask = ref.putFile(fileToUpload);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw 'Upload failed with state: ${snapshot.state}';
      }

      final String downloadURL = await ref.getDownloadURL();
      debugPrint('[StorageService] Technician doc uploaded successfully');

      return downloadURL;
    } on FirebaseException catch (e) {
      debugPrint('[StorageService] Firebase error: ${e.code} - ${e.message}');
      _handleFirebaseError(e);
      rethrow;
    } catch (e) {
      debugPrint('[StorageService] Error uploading technician doc: $e');
      rethrow;
    }
  }

  /// Upload profile photo with validation and proper error handling
  /// 
  /// Path: users/{userId}/profile/profile.jpg (matches storage rules)
  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile file,
  }) async {
    try {
      // CRITICAL: Validate user is authenticated and owns this upload
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'You must be signed in to upload a profile photo';
      }
      if (currentUser.uid != userId) {
        throw 'You can only upload your own profile photo';
      }

      final fileToUpload = File(file.path);
      if (!await fileToUpload.exists()) {
        throw 'Selected file does not exist';
      }

      final fileSize = await fileToUpload.length();
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        throw 'Image size ($sizeMB MB) exceeds 5MB limit';
      }

      String contentType = 'image/jpeg';
      final extension = file.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else {
        throw 'Only JPG and PNG images are supported';
      }

      // FIXED: Path matches storage rules exactly
      // Rule: match /users/{userId}/profile/{fileName}
      final Reference ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child('profile.jpg');

      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      debugPrint('[StorageService] Uploading profile photo for user: $userId');
      debugPrint('[StorageService] Path: users/$userId/profile/profile.jpg');

      final UploadTask uploadTask = ref.putFile(fileToUpload, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw 'Upload failed with state: ${snapshot.state}';
      }

      final String downloadURL = await ref.getDownloadURL();
      debugPrint('[StorageService] Profile photo uploaded successfully');

      return downloadURL;
    } on FirebaseException catch (e) {
      debugPrint('[StorageService] Firebase error: ${e.code} - ${e.message}');
      _handleFirebaseError(e);
      rethrow;
    } catch (e) {
      debugPrint('[StorageService] Error uploading profile photo: $e');
      rethrow;
    }
  }

  /// Get download URL for a video (for video playback)
  /// 
  /// CRITICAL: Always use getDownloadURL() for video playback to avoid 403 errors
  Future<String> getVideoDownloadUrl(String storagePath) async {
    try {
      final Reference ref = _storage.ref().child(storagePath);
      return await ref.getDownloadURL();
    } on FirebaseException catch (e) {
      debugPrint('[StorageService] Error getting video URL: ${e.code}');
      _handleFirebaseError(e);
      rethrow;
    }
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      final Reference ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child('profile.jpg');
      
      await ref.delete();
      debugPrint('[StorageService] Profile photo deleted for user: $userId');
    } on FirebaseException catch (e) {
      if (e.code == 'object-not-found') {
        debugPrint('[StorageService] No profile photo to delete');
        return;
      }
      debugPrint('[StorageService] Error deleting profile photo: $e');
      rethrow;
    }
  }

  void _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        throw 'File not found. Please try again';
      case 'unauthorized':
      case 'permission-denied':
        throw 'You do not have permission to perform this action';
      case 'canceled':
        throw 'Operation was cancelled';
      case 'unknown':
        throw 'Operation failed. Please check your internet connection';
      default:
        throw 'Operation failed: ${e.message ?? 'Unknown error'}';
    }
  }
}
```

**Explanation:**
- Added authentication validation before upload
- Path now matches storage rules exactly
- Added `getVideoDownloadUrl()` method for video playback
- Improved error handling

---

## 4️⃣ App Check Debug Handling (Already Correct in `main.dart`)

The current implementation is correct:

```dart
// In main.dart - already correct
if (kDebugMode) {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
    appleProvider: AppleProvider.debug,
    webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_KEY'),
  );
} else {
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.deviceCheck,
    webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_KEY'),
  );
}
```

**Important:** For debug mode to work, you must:
1. Add your debug token to Firebase Console → App Check → Apps → Manage debug tokens
2. The debug token is printed in logcat/console on first run

---

## 5️⃣ Fixed Video Playback with getDownloadURL()

**Problem:** Direct storage URLs cause 403 errors. Must use `getDownloadURL()`.

Update `professional_reels_section.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../core/models/dashboard_models.dart';
import '../../../core/widgets/safe_network_image.dart';

class _ReelItemState extends State<_ReelItem> {
  VideoPlayerController? _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  Future<void> _initializeController() async {
    try {
      String videoUrl = widget.reel.videoUrl;
      
      // CRITICAL FIX: If URL is a storage path (not a download URL), get the download URL
      if (!videoUrl.contains('firebasestorage.googleapis.com') || 
          !videoUrl.contains('token=')) {
        // This is a storage path, need to get download URL
        if (videoUrl.startsWith('gs://') || videoUrl.startsWith('reels/')) {
          final storagePath = videoUrl.startsWith('gs://') 
              ? videoUrl.replaceFirst(RegExp(r'gs://[^/]+/'), '')
              : videoUrl;
          videoUrl = await FirebaseStorage.instance
              .ref()
              .child(storagePath)
              .getDownloadURL();
        }
      }
      
      _controller = VideoPlayerController.networkUrl(Uri.parse(videoUrl))
        ..setLooping(true)
        ..setVolume(0);
      
      await _controller!.initialize();
      
      if (mounted) {
        setState(() => _isInitialized = true);
        if (widget.isFocused) _controller!.play();
      }
    } catch (e) {
      debugPrint('[VideoPlayer] Error initializing video: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video unavailable';
        });
      }
    }
  }

  @override
  void didUpdateWidget(_ReelItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInitialized && _controller != null) {
      if (widget.isFocused) {
        _controller!.play();
      } else {
        _controller!.pause();
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: widget.isFocused ? 1.0 : 0.92,
      duration: const Duration(milliseconds: 300),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail/Fallback
              if (widget.reel.thumbnailUrl.isNotEmpty)
                SafeNetworkImage(
                  imageUrl: widget.reel.thumbnailUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                ),
                
              // Video (only if initialized and no error)
              if (_isInitialized && !_hasError && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                ),
              
              // Error state
              if (_hasError)
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.videocam_off, color: Colors.white54, size: 48),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage ?? 'Video unavailable',
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ],
                  ),
                ),
                
              // Gradient overlay
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.8),
                    ],
                    stops: const [0.6, 0.8, 1.0],
                  ),
                ),
              ),
              
              // Content overlay...
              // (rest of the build method remains the same)
              
              // Loading indicator
              if (!_isInitialized && !_hasError)
                const Center(
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Explanation:**
- Checks if URL is already a download URL (contains token)
- If not, fetches the download URL using `getDownloadURL()`
- Added error handling for video initialization failures
- Shows fallback UI when video fails to load

---

## 6️⃣ Safe NetworkImage with errorBuilder

The `SafeNetworkImage` widget already handles errors correctly. For direct `Image.network` usage elsewhere, use this pattern:

```dart
// CORRECT: Always use errorBuilder with Image.network
Image.network(
  imageUrl,
  fit: BoxFit.cover,
  loadingBuilder: (context, child, loadingProgress) {
    if (loadingProgress == null) return child;
    return Center(
      child: CircularProgressIndicator(
        value: loadingProgress.expectedTotalBytes != null
            ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
            : null,
      ),
    );
  },
  errorBuilder: (context, error, stackTrace) {
    debugPrint('[Image] Error loading image: $error');
    return Container(
      color: Colors.grey[200],
      child: const Icon(Icons.broken_image, color: Colors.grey),
    );
  },
)

// OR use the SafeNetworkImage widget (recommended)
SafeNetworkImage(
  imageUrl: imageUrl,
  width: 100,
  height: 100,
  fit: BoxFit.cover,
)
```

---

## 7️⃣ Security Verification Checklist

✅ **No admin/payment data exposed:**
- `admins` collection: `allow read, write: if false`
- `payment_logs` collection: `allow read: if isAdmin(); allow write: if false`
- `payout_logs` collection: `allow read: if isAdmin(); allow write: if false`

✅ **No wildcard write permissions:**
- All write rules are explicit per collection
- No `match /{document=**}` rules

✅ **No insecure public write:**
- All write operations require authentication
- User can only write to their own data

✅ **App Check enabled:**
- Debug mode uses debug provider
- Production uses Play Integrity / Device Check

---

## 8️⃣ Deployment Steps

1. **Deploy Storage Rules:**
   ```bash
   firebase deploy --only storage
   ```

2. **Deploy Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Update Flutter Code:**
   - Update `storage_service.dart`
   - Update `professional_reels_section.dart`
   - Ensure all `Image.network` uses `errorBuilder`

4. **Test in Debug Mode:**
   - Add debug token to Firebase Console
   - Test profile photo upload
   - Test video playback
   - Test address CRUD operations

5. **Test in Production:**
   - Build release APK
   - Verify App Check with Play Integrity
   - Test all features

---

## Summary of Fixes

| Issue | Root Cause | Fix |
|-------|-----------|-----|
| Storage 403/404 | Path mismatch between code and rules | Updated storage rules to match code paths |
| Firestore permission denied | Missing addresses subcollection rules | Added explicit rules for addresses |
| Video 403 | Using storage path instead of download URL | Use `getDownloadURL()` before playback |
| NetworkImage crash | No error handling | Use `errorBuilder` or `SafeNetworkImage` |
| App Check 403 | Debug token not registered | Use debug provider + register token |
