import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Image upload utility for technician services
/// Handles image selection and Firebase Storage upload
/// Note: 1:1 aspect ratio is enforced on the server/cloud function side
class ServiceImageUtils {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final ImagePicker _picker = ImagePicker();

  /// Service images storage path
  static const String _storagePath = 'technician_services';

  /// Pick an image from gallery
  static Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('❌ [ServiceImage] Error picking image: $e');
      return null;
    }
  }

  /// Pick an image from camera
  static Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('❌ [ServiceImage] Error capturing image: $e');
      return null;
    }
  }

  static Future<String> uploadKycImage(XFile imageFile, String type) async {
    return _uploadImage(imageFile, 'technician_kyc', type);
  }

  static Future<String> _uploadImage(XFile imageFile, String folder, String type) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) {
        throw Exception('User not authenticated');
      }

      final bytes = await imageFile.readAsBytes();
      
      if (bytes.length > 10 * 1024 * 1024) {
        throw Exception('Image size must be less than 10MB');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = imageFile.path.split('.').last.toLowerCase();
      final validExtension = ['jpg', 'jpeg', 'png', 'webp'].contains(extension) 
          ? extension 
          : 'jpg';
      final fileName = '${type}_${uid}_$timestamp.$validExtension';
      final path = '$folder/$uid/$fileName';
      
      final uploadTask = _storage.ref().child(path).putData(
        bytes,
        SettableMetadata(
          contentType: 'image/${validExtension == 'jpg' ? 'jpeg' : validExtension}',
          customMetadata: {
            'userId': uid,
            'uploadedAt': DateTime.now().toIso8601String(),
            'type': type,
          },
        ),
      );

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('✅ [ImageUtility] Uploaded successfully: $downloadUrl');
      return downloadUrl;
    } on FirebaseException catch (e) {
      debugPrint('❌ [ImageUtility] Firebase error: ${e.message}');
      throw Exception('Failed to upload image: ${e.message}');
    } catch (e) {
      debugPrint('❌ [ImageUtility] Error: $e');
      rethrow;
    }
  }

  /// Upload a service image
  /// 
  /// Returns the download URL of the uploaded image
  static Future<String> uploadServiceImage(XFile imageFile) async {
    return _uploadImage(imageFile, _storagePath, 'service_image');
  }

  /// Validate image before upload (file type, size)
  static Future<String?> validateImage(XFile imageFile) async {
    // Check file size (max 10MB)
    final fileSize = await imageFile.length();
    if (fileSize > 10 * 1024 * 1024) {
      return 'Image size must be less than 10MB';
    }

    // Check file extension
    final extension = imageFile.path.split('.').last.toLowerCase();
    final allowedExtensions = ['jpg', 'jpeg', 'png', 'webp'];
    if (!allowedExtensions.contains(extension)) {
      return 'Only JPG, PNG, and WebP images are allowed';
    }

    return null; // Valid
  }

  /// Delete a service image from storage
  static Future<void> deleteServiceImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      if (uri.pathSegments.length >= 3) {
        // Format: /v0/b/{bucket}/o/{path}
        final path = uri.pathSegments.skip(2).join('/');
        if (path.isNotEmpty) {
          await _storage.ref().child(path).delete();
          debugPrint('✅ [ServiceImage] Deleted: $path');
        }
      }
    } catch (e) {
      debugPrint('❌ [ServiceImage] Error deleting image: $e');
      // Don't throw - image deletion is not critical
    }
  }

  /// Show image source selection dialog
  static Future<XFile?> pickImage({bool allowCamera = true}) async {
    // For simplicity, directly use gallery
    // Can be extended to show a dialog for camera/gallery choice
    return pickImageFromGallery();
  }
}
