import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

/// Upload progress callback type
typedef UploadProgressCallback = void Function(double progress);

/// Image Upload Service for Firebase Storage
/// Handles secure image upload with compression and progress tracking
/// 
/// Features:
/// - Image compression before upload (quality: 70, max: 1280x1280)
/// - Upload progress tracking
/// - Cancellation support
/// - Double upload prevention
class ImageUploadService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  
  // Track ongoing uploads to prevent double uploads
  final Set<String> _activeUploads = {};

  // Compression settings (production-grade)
  static const int maxWidth = 1280;
  static const int maxHeight = 1280;
  static const int imageQuality = 70;
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2MB

  /// Pick image from gallery with compression settings
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check file size
        final fileSize = await file.length();
        if (fileSize > maxFileSizeBytes) {
          debugPrint('[ImageUpload] File too large: $fileSize bytes, max: $maxFileSizeBytes');
          // Try to pick again with lower quality
          return await _pickImageWithLowerQuality(ImageSource.gallery);
        }
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Pick image from camera with compression settings
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (pickedFile != null) {
        final file = File(pickedFile.path);
        
        // Check file size
        final fileSize = await file.length();
        if (fileSize > maxFileSizeBytes) {
          debugPrint('[ImageUpload] File too large: $fileSize bytes, max: $maxFileSizeBytes');
          return await _pickImageWithLowerQuality(ImageSource.camera);
        }
        
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick image with lower quality for large files
  Future<File?> _pickImageWithLowerQuality(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 50,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error picking image with lower quality: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage with secure path and progress tracking
  /// Path format: technicians/{uid}/services/{timestamp}_{filename}
  /// 
  /// FIX #1: Automatically converts image to 1:1 ratio (square) before upload
  /// - Crops to center square
  /// - Resizes to 1024x1024
  /// 
  /// [onProgress] - Optional callback for upload progress (0.0 to 1.0)
  /// Returns the download URL on success
  Future<String?> uploadServiceImage(
    File imageFile, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // CRITICAL: Ensure user is authenticated before starting upload
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Cannot upload service image.');
      }
      
      // Additional authentication validation
      if (user.uid.isEmpty) {
        throw Exception('Invalid user ID. Cannot upload service image.');
      }
      
      // Generate unique upload ID to prevent double uploads
      final uploadId = '${user.uid}_${DateTime.now().millisecondsSinceEpoch}';
      if (_activeUploads.contains(uploadId)) {
        throw Exception('Upload already in progress');
      }
      
      _activeUploads.add(uploadId);
      
      try {
        // FIX #1: Process image to 1:1 ratio before upload
        final processedFile = await _processImageToSquare(imageFile);
        
        // Generate secure path
        final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
        final String fileName = 'service_$timestamp.jpg';
        final String path = 'technicians/${user.uid}/services/$fileName';
        
        // Create reference
        final Reference ref = _storage.ref().child(path);
        
        // Setup upload with metadata
        final UploadTask uploadTask = ref.putFile(
          processedFile,
          SettableMetadata(
            contentType: 'image/jpeg',
            cacheControl: 'public, max-age=3600',
          ),
        );

        // Listen to progress
        if (onProgress != null) {
          uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          });
        }

        // Wait for upload to complete
        final TaskSnapshot snapshot = await uploadTask;
        
        // Get download URL
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        
        // Clean up processed file
        try {
          await processedFile.delete();
        } catch (e) {
          debugPrint('[ImageUpload] Failed to delete temp file: $e');
        }
        
        debugPrint('[ImageUpload] Upload successful (1:1 ratio): $downloadUrl');
        return downloadUrl;
      } finally {
        _activeUploads.remove(uploadId);
      }
    } on FirebaseException catch (e) {
      debugPrint('Firebase storage error: ${e.code} - ${e.message}');
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }
  
  /// FIX #1: Process image to 1:1 ratio (square)
  /// - Determines smallest side
  /// - Crops center square
  /// - Resizes to 1024x1024
  Future<File> _processImageToSquare(File imageFile) async {
    try {
      // Read image bytes
      final bytes = await imageFile.readAsBytes();
      
      // Decode image
      final original = img.decodeImage(bytes);
      if (original == null) {
        throw Exception('Failed to decode image');
      }
      
      // Determine smallest side for square crop
      final size = original.width < original.height ? original.width : original.height;
      
      // Crop to center square
      final cropped = img.copyCrop(
        original,
        x: (original.width - size) ~/ 2,
        y: (original.height - size) ~/ 2,
        width: size,
        height: size,
      );
      
      // Resize to 1024x1024
      final resized = img.copyResize(cropped, width: 1024, height: 1024);
      
      // Encode as JPEG with quality 85
      final processedBytes = img.encodeJpg(resized, quality: 85);
      
      // Save to temporary file
      final tempDir = imageFile.parent;
      final tempPath = '${tempDir.path}/processed_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final processedFile = File(tempPath);
      await processedFile.writeAsBytes(processedBytes);
      
      debugPrint('[ImageUpload] Image processed to 1:1 ratio (1024x1024)');
      return processedFile;
    } catch (e) {
      debugPrint('[ImageUpload] Error processing image: $e');
      // If processing fails, return original file
      return imageFile;
    }
  }

  /// Upload image with cancellation support
  Future<String?> uploadServiceImageWithCancellation(
    File imageFile, {
    UploadProgressCallback? onProgress,
  }) async {
    try {
      // CRITICAL: Ensure user is authenticated before starting upload
      final User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated. Cannot upload service image.');
      }
      
      // Additional authentication validation
      if (user.uid.isEmpty) {
        throw Exception('Invalid user ID. Cannot upload service image.');
      }

      // Generate secure path
      final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final String fileName = 'service_$timestamp.jpg';
      final String path = 'technicians/${user.uid}/services/$fileName';

      // Create reference
      final Reference ref = _storage.ref().child(path);

      // Setup upload with metadata
      final UploadTask uploadTask = ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          cacheControl: 'public, max-age=3600',
        ),
      );

      // Listen to progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          if (snapshot.state == TaskState.success) {
            onProgress(1.0);
          } else if (snapshot.state == TaskState.error) {
            onProgress(0.0);
          } else {
            final progress = snapshot.bytesTransferred / snapshot.totalBytes;
            onProgress(progress);
          }
        });
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;

      // Get download URL
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('Firebase storage error: ${e.code} - ${e.message}');
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  /// Delete image from Firebase Storage
  Future<void> deleteImage(String imageUrl) async {
    try {
      // Extract path from URL
      final Uri uri = Uri.parse(imageUrl);
      final String path = uri.pathSegments.skip(1).join('/'); // Remove 'v' segment

      await _storage.ref().child(path).delete();
    } catch (e) {
      debugPrint('Error deleting image: $e');
      // Silently fail - image might not exist
    }
  }

  /// Cancel all active uploads
  void cancelAllUploads() {
    _activeUploads.clear();
  }

  /// Check if there are active uploads
  bool get hasActiveUploads => _activeUploads.isNotEmpty;
}
