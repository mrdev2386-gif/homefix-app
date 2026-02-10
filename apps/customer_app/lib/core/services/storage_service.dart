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
  Future<String?> uploadTechnicianDoc({
    required String userId,
    required dynamic file,
    required String docType,
  }) async {
    if (kIsWeb) return null;
    
    try {
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}_file';
      final Reference ref = _storage.ref().child('technician_docs').child(userId).child(docType).child(fileName);
      
      File fileToUpload;
      if (file is XFile) {
        fileToUpload = File(file.path);
      } else if (file is File) {
        fileToUpload = file;
      } else {
        debugPrint('[StorageService] Invalid file type: ${file.runtimeType}');
        return null;
      }

      final UploadTask uploadTask = ref.putFile(fileToUpload);
      final TaskSnapshot snapshot = await uploadTask;
      
      if (snapshot.state == TaskState.success) {
        return await ref.getDownloadURL();
      }
      return null;
    } catch (e) {
      debugPrint('[StorageService] Error uploading document: $e');
      return null;
    }
  }

  /// Upload profile photo with validation and proper error handling
  /// 
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

      // CRITICAL: Always use same path to overwrite previous image
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
      
      // User-friendly error messages
      switch (e.code) {
        case 'unauthorized':
          throw 'You do not have permission to upload images';
        case 'canceled':
          throw 'Upload was cancelled';
        case 'unknown':
          throw 'Upload failed. Please check your internet connection';
        default:
          throw 'Upload failed: ${e.message ?? 'Unknown error'}';
      }
    } catch (e) {
      debugPrint('[StorageService] Error uploading profile photo: $e');
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
}
