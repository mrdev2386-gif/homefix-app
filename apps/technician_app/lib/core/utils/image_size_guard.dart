import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

class ImageSizeGuard {
  static const int maxFileSizeBytes = 500 * 1024; // 500KB
  static const int maxWidth = 1280;
  static const int targetQuality = 75;

  /// Validate and compress image to ensure < 500KB
  /// Returns compressed file or throws exception if exceeds limit
  static Future<File> validateAndCompress(File imageFile) async {
    try {
      // Check initial size
      final initialSize = await imageFile.length();
      debugPrint('[ImageSizeGuard] Initial size: ${(initialSize / 1024).toStringAsFixed(2)}KB');

      // Read and decode image
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Resize if needed
      img.Image resized = image;
      if (image.width > maxWidth) {
        resized = img.copyResize(
          image,
          width: maxWidth,
          height: (image.height * maxWidth / image.width).toInt(),
          interpolation: img.Interpolation.linear,
        );
        debugPrint('[ImageSizeGuard] Resized to ${resized.width}x${resized.height}');
      }

      // Encode as JPEG with target quality
      final compressed = img.encodeJpg(resized, quality: targetQuality);

      // Check final size
      if (compressed.length > maxFileSizeBytes) {
        // Try lower quality
        final recompressed = img.encodeJpg(resized, quality: 60);
        if (recompressed.length > maxFileSizeBytes) {
          throw Exception(
            'Image too large: ${(recompressed.length / 1024).toStringAsFixed(2)}KB (max 500KB)',
          );
        }
        final tempFile = File(imageFile.path + '.compressed.jpg');
        await tempFile.writeAsBytes(recompressed);
        debugPrint('[ImageSizeGuard] Final size: ${(recompressed.length / 1024).toStringAsFixed(2)}KB');
        return tempFile;
      }

      // Write compressed file
      final tempFile = File(imageFile.path + '.compressed.jpg');
      await tempFile.writeAsBytes(compressed);
      debugPrint('[ImageSizeGuard] Final size: ${(compressed.length / 1024).toStringAsFixed(2)}KB');

      return tempFile;
    } catch (e) {
      debugPrint('[ImageSizeGuard] Error: $e');
      rethrow;
    }
  }

  /// Check if file size is within limit
  static Future<bool> isWithinLimit(File file) async {
    final size = await file.length();
    return size <= maxFileSizeBytes;
  }

  /// Get human-readable file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(2)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
