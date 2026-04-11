/// Image URL utilities for HomeFix technician app.
/// Provides safe sanitization of image URLs read from Firestore.
library;

/// Sanitizes an image URL from Firestore.
///
/// Returns null if the URL is invalid, which signals SafeNetworkImage
/// to show an icon-based fallback instead of attempting to load an image.
///
/// Example:
/// ```dart
/// SafeNetworkImage(
///   imageUrl: sanitizeImageUrl(technician.profileImageUrl),
/// )
/// ```
String? sanitizeImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return null;
  }
  if (!url.startsWith('http')) {
    return null;
  }
  return url;
}
