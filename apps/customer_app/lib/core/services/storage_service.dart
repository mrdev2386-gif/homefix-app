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
  /// CRITICAL: Path must match storage.rules
  Future<String> uploadTechnicianDoc({
    required String userId,
    required XFile file,
    required String docType,
  }) async {
    try {
      // SECURITY: Validate user is authenticated and owns this upload
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'Authentication required. Please sign in again.';
      }
      if (currentUser.uid != userId) {
        throw 'You can only upload documents for your own account';
      }

      // Validate file exists
      final fileToUpload = File(file.path);
      if (!await fileToUpload.exists()) {
        throw 'Selected file does not exist';
      }

      // Validate file size (max 5MB)
      final fileSize = await fileToUpload.length();
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        throw 'File size ($sizeMB MB) exceeds 5MB limit';
      }

      // Generate unique filename
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_$docType';
      
      // CRITICAL: Path matches storage.rules
      // Rule: match /technicians/{techId}/{docType}/{fileName}
      final Reference ref = _storage
          .ref()
          .child('technicians')
          .child(userId)
          .child(docType)
          .child(fileName);

      debugPrint('[StorageService] Uploading technician doc: $docType for user: $userId');
      debugPrint('[StorageService] Path: technicians/$userId/$docType/$fileName');
      debugPrint('[StorageService] File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Upload file
      final UploadTask uploadTask = ref.putFile(fileToUpload);
      
      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw 'Upload failed with state: ${snapshot.state}';
      }

      // Get download URL
      final String downloadURL = await ref.getDownloadURL();
      
      debugPrint('[StorageService] Technician doc uploaded successfully');
      debugPrint('[StorageService] Download URL: $downloadURL');

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
  /// Path: users/{userId}/profile/profile.jpg (matches storage.rules)
  /// CRITICAL RULES:
  /// 1. Always uploads to: users/{userId}/profile/profile.jpg (overwrites previous)
  /// 2. Validates file size (max 5MB)
  /// 3. Sets proper content type metadata
  /// 4. Returns download URL on success
  /// 5. Throws exceptions with user-friendly messages
  Future<String> uploadProfilePhoto({
    required String userId,
    required XFile file,
  }) async {
    try {
      // SECURITY: Validate user is authenticated and owns this upload
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw 'You must be signed in to upload a profile photo';
      }
      if (currentUser.uid != userId) {
        throw 'You can only upload your own profile photo';
      }

      // Validate file exists
      final fileToUpload = File(file.path);
      if (!await fileToUpload.exists()) {
        throw 'Selected file does not exist';
      }

      // Validate file size (max 5MB)
      final fileSize = await fileToUpload.length();
      if (fileSize > maxFileSizeBytes) {
        final sizeMB = (fileSize / (1024 * 1024)).toStringAsFixed(1);
        throw 'Image size ($sizeMB MB) exceeds 5MB limit';
      }

      // Determine content type from file extension
      String contentType = 'image/jpeg';
      final extension = file.path.split('.').last.toLowerCase();
      if (extension == 'png') {
        contentType = 'image/png';
      } else if (extension == 'jpg' || extension == 'jpeg') {
        contentType = 'image/jpeg';
      } else {
        throw 'Only JPG and PNG images are supported';
      }

      // CRITICAL: Path matches storage.rules exactly
      // Rule: match /users/{userId}/profile/{fileName}
      final Reference ref = _storage
          .ref()
          .child('users')
          .child(userId)
          .child('profile')
          .child('profile.jpg');

      // Set metadata
      final metadata = SettableMetadata(
        contentType: contentType,
        customMetadata: {
          'uploadedAt': DateTime.now().toIso8601String(),
          'userId': userId,
        },
      );

      debugPrint('[StorageService] Uploading profile photo for user: $userId');
      debugPrint('[StorageService] Path: users/$userId/profile/profile.jpg');
      debugPrint('[StorageService] File size: ${(fileSize / 1024).toStringAsFixed(2)} KB');

      // Upload file
      final UploadTask uploadTask = ref.putFile(fileToUpload, metadata);
      
      // Wait for completion
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state != TaskState.success) {
        throw 'Upload failed with state: ${snapshot.state}';
      }

      // Get download URL
      final String downloadURL = await ref.getDownloadURL();
      
      debugPrint('[StorageService] Profile photo uploaded successfully');
      debugPrint('[StorageService] Download URL: $downloadURL');

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
  /// Direct storage URLs will fail with App Check enabled
  Future<String> getVideoDownloadUrl(String storagePath) async {
    try {
      // Handle gs:// URLs
      String path = storagePath;
      if (storagePath.startsWith('gs://')) {
        path = storagePath.replaceFirst(RegExp(r'gs://[^/]+/'), '');
      }
      
      final Reference ref = _storage.ref().child(path);
      final String downloadUrl = await ref.getDownloadURL();
      
      debugPrint('[StorageService] Got video download URL for: $path');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('[StorageService] Error getting video URL: ${e.code} - ${e.message}');
      _handleFirebaseError(e);
      rethrow;
    }
  }

  /// Check if a URL is a valid Firebase download URL (contains token)
  bool isValidDownloadUrl(String url) {
    return url.contains('firebasestorage.googleapis.com') && 
           url.contains('token=');
  }

  /// Delete profile photo
  Future<void> deleteProfilePhoto(String userId) async {
    try {
      // SECURITY: Validate user owns this photo
      final currentUser = _auth.currentUser;
      if (currentUser == null || currentUser.uid != userId) {
        throw 'You can only delete your own profile photo';
      }

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

  /// Handle Firebase errors with user-friendly messages
  void _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'object-not-found':
        throw 'File not found. Please try again';
      case 'unauthorized':
      case 'permission-denied':
        throw 'You do not have permission to perform this action. Please sign in again.';
      case 'canceled':
        throw 'Operation was cancelled';
      case 'unknown':
        throw 'Operation failed. Please check your internet connection';
      case 'unauthenticated':
        throw 'Please sign in to continue';
      default:
        throw 'Operation failed: ${e.message ?? 'Unknown error'}';
    }
  }
}
