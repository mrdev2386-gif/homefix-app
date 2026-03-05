import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload a file to Firebase Storage and return the download URL
  Future<String> uploadFile({
    required File file,
    required String path,
    String? fileName,
  }) async {
    try {
      final String name = fileName ?? '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final Reference ref = _storage.ref().child(path).child(name);

      // Metadata to help with identification
      final SettableMetadata metadata = SettableMetadata(
        contentType: _getContentType(file.path),
        customMetadata: {'uploadedAt': DateTime.now().toIso8601String()},
      );

      final UploadTask task = ref.putFile(file, metadata);

      // Monitor progress if needed (optional)
      task.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        if (kDebugMode) {
          debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(2)}%');
        }
      });

      final TaskSnapshot snapshot = await task;
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      
      return downloadUrl;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error uploading file to storage: $e');
      }
      rethrow;
    }
  }

  /// Upload multiple files
  Future<List<String>> uploadMultipleFiles({
    required List<File> files,
    required String path,
  }) async {
    final List<Future<String>> uploadFutures = files.map((file) => uploadFile(
      file: file,
      path: path,
    )).toList();

    return await Future.wait(uploadFutures);
  }

  String _getContentType(String path) {
    final extension = p.extension(path).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }

  /// Delete a file from storage accurately
  Future<void> deleteFile(String url) async {
    try {
      final Reference ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error deleting file from storage: $e');
      }
    }
  }

  // Phase 4 additions
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  Future<String> uploadProfilePhoto(String userId, File file) async {
    final int size = await file.length();
    if (size > maxFileSizeBytes) {
      throw Exception('File size exceeds maximum allowed size.');
    }
    return uploadFile(
      file: file,
      path: 'users/$userId/profile',
      fileName: 'profile_photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
  }

  Future<String> uploadTechnicianDoc(String technicianId, File file, String docType) async {
    final int size = await file.length();
    if (size > maxFileSizeBytes) {
      throw Exception('File size exceeds maximum allowed size.');
    }
    return uploadFile(
      file: file,
      path: 'technicians/$technicianId/documents',
      fileName: '${docType}_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}',
    );
  }

  Future<String> uploadCustomRequestImage(File file, String userId) async {
    final int size = await file.length();
    if (size > maxFileSizeBytes) {
      throw Exception('File size exceeds maximum allowed size.');
    }
    return uploadFile(
      file: file,
      path: 'custom_requests/$userId/images',
      fileName: 'request_image_${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}',
    );
  }
}
