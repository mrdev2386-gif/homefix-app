/// Image URL utilities for HomeFix technician app.
/// Provides safe sanitization of image URLs read from Firestore.
library;

const String _kPlaceholderUrl =
    'https://via.placeholder.com/400x300.png?text=HomeFix';

/// Sanitizes an image URL from Firestore.
///
/// Returns a reliable placeholder if the URL is null, empty, or does not
/// start with "http". Use this wherever imageUrl is read from a Firestore
/// document before passing it to [SafeNetworkImage].
///
/// Example:
/// ```dart
/// SafeNetworkImage(
///   imageUrl: sanitizeImageUrl(technician.profileImageUrl),
/// )
/// ```
String sanitizeImageUrl(String? url) {
  if (url == null || url.isEmpty) {
    return _kPlaceholderUrl;
  }
  if (!url.startsWith('http')) {
    return _kPlaceholderUrl;
  }
  return url;
}
