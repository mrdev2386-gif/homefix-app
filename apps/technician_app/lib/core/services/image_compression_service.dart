import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class ImageCompressionService {
  static const int maxWidth = 1280;
  static const int jpegQuality = 75;
  static const int maxSizeBytes = 500 * 1024; // 500KB

  /// Compress image before upload
  /// Returns compressed file, throws if compression fails
  static Future<File> compressImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      
      // Read image
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
          height: (image.height * maxWidth ~/ image.width),
          interpolation: img.Interpolation.linear,
        );
      }

      // Encode as JPEG with quality
      final compressed = img.encodeJpg(resized, quality: jpegQuality);

      // Check size
      if (compressed.length > maxSizeBytes) {
        throw Exception('Compressed image still too large: ${compressed.length} bytes');
      }

      // Write to temp file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await tempFile.writeAsBytes(compressed);

      debugPrint('[ImageCompression] Compressed: ${bytes.length} → ${compressed.length} bytes');
      return tempFile;
    } catch (e) {
      debugPrint('[ImageCompression] Error: $e');
      rethrow;
    }
  }
}
