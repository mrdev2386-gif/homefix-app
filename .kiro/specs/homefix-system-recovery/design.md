# HomeFix Deep System Recovery - Design Document

## Architecture Overview

This recovery effort maintains the existing Firebase-first security architecture while hardening all critical paths. No architectural changes - only defensive improvements and error handling enhancements.

### Core Principles
1. **Security First**: Maintain callable-first architecture, no direct writes
2. **Fail Safe**: All operations must fail gracefully with user feedback
3. **Defense in Depth**: Validate at every layer (UI → Service → Firebase)
4. **Observable**: Log all critical operations for debugging

## Component Design

### 1. App Check Initialization System

**Location**: `apps/customer_app/lib/core/config/firebase_init.dart`

**Current Issue**: App Check may initialize in wrong order or fail silently

**Solution**:
```dart
class FirebaseInitializer {
  static bool _initialized = false;
  
  static Future<void> initialize() async {
    if (_initialized) return;
    
    // Step 1: Core Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Step 2: App Check (must be after Firebase init)
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode 
        ? AndroidProvider.debug 
        : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
        ? AppleProvider.debug
        : AppleProvider.deviceCheck,
    );
    
    // Step 3: Token monitoring
    FirebaseAppCheck.instance.onTokenChange.listen((token) {
      debugPrint('[APP_CHECK_TOKEN] ${token ?? "null"}');
    });
    
    _initialized = true;
    debugPrint('[FIREBASE_INIT] Complete');
  }
}
```

**Validation**: Token appears in logs, no duplicate initialization

---

### 2. Write Operation Guarantee System

**Affected Services**:
- `apps/customer_app/lib/core/services/cart_service.dart`
- `apps/customer_app/lib/core/services/favorites_service.dart`
- `apps/customer_app/lib/core/services/address_service.dart`
- `apps/customer_app/lib/core/services/profile_service.dart`
- `apps/customer_app/lib/core/services/notification_service.dart`
- `apps/customer_app/lib/core/services/booking_service.dart`

**Pattern to Apply**:
```dart
Future<Result<T>> performWriteOperation({
  required String operationName,
  required Future<T> Function() operation,
  required BuildContext? context,
}) async {
  try {
    debugPrint('[$operationName] Starting...');
    
    final result = await operation();
    
    debugPrint('[$operationName] Success');
    
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$operationName completed')),
      );
    }
    
    return Result.success(result);
  } catch (e, stack) {
    debugPrint('[$operationName] Failed: $e');
    debugPrint('[$operationName] Stack: $stack');
    
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    return Result.failure(e.toString());
  }
}
```

**UI Integration**:
- Show loading indicator during operation
- Remove loading on completion
- Display success/error feedback
- Never silently fail

---

### 3. SafeNetworkImage Widget

**Location**: `apps/customer_app/lib/core/widgets/safe_network_image.dart`

**Design**:
```dart
class SafeNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  
  const SafeNetworkImage({
    Key? key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholder,
    this.errorWidget,
  }) : super(key: key);
  
  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    
    // Block known bad patterns
    if (url.contains('unsplash') && url.contains('404')) return false;
    
    return true;
  }
  
  @override
  Widget build(BuildContext context) {
    if (!_isValidUrl(imageUrl)) {
      return _buildFallback();
    }
    
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) => placeholder ?? _buildPlaceholder(),
      errorWidget: (context, url, error) {
        debugPrint('[SAFE_IMAGE] Failed to load: $url - $error');
        return errorWidget ?? _buildFallback();
      },
      fadeInDuration: const Duration(milliseconds: 300),
      memCacheWidth: width?.toInt(),
      memCacheHeight: height?.toInt(),
      maxWidthDiskCache: 1000,
      maxHeightDiskCache: 1000,
    );
  }
  
  Widget _buildPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
  
  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(
        Icons.image_not_supported,
        color: Colors.grey,
      ),
    );
  }
}
```

**Migration Strategy**:
1. Search for all `Image.network` usages
2. Search for all `CachedNetworkImage` direct usages
3. Replace with `SafeNetworkImage`
4. Test image loading and fallbacks

---

### 4. Video Player Defensive Wrapper

**Location**: `apps/customer_app/lib/features/dashboard/widgets/professional_reels_section.dart`

**Current Issue**: Video player crashes on bad URLs or network errors

**Solution**:
```dart
class SafeVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;
  
  const SafeVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.thumbnailUrl,
  }) : super(key: key);
  
  @override
  State<SafeVideoPlayer> createState() => _SafeVideoPlayerState();
}

class _SafeVideoPlayerState extends State<SafeVideoPlayer> {
  VideoPlayerController? _controller;
  bool _hasError = false;
  int _retryCount = 0;
  static const int _maxRetries = 1;
  
  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }
  
  bool _isValidVideoUrl(String url) {
    if (!url.startsWith('https://')) {
      debugPrint('[VIDEO] Invalid protocol: $url');
      return false;
    }
    return true;
  }
  
  Future<void> _initializePlayer() async {
    if (!_isValidVideoUrl(widget.videoUrl)) {
      setState(() => _hasError = true);
      return;
    }
    
    try {
      _controller = VideoPlayerController.network(widget.videoUrl);
      
      await _controller!.initialize();
      
      _controller!.addListener(() {
        if (_controller!.value.hasError) {
          debugPrint('[VIDEO] Playback error: ${_controller!.value.errorDescription}');
          _handleError();
        }
      });
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('[VIDEO] Init failed: $e');
      _handleError();
    }
  }
  
  void _handleError() {
    if (_retryCount < _maxRetries) {
      _retryCount++;
      debugPrint('[VIDEO] Retry attempt $_retryCount');
      _initializePlayer();
    } else {
      if (mounted) {
        setState(() => _hasError = true);
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
    if (_hasError) {
      return _buildErrorFallback();
    }
    
    if (_controller == null || !_controller!.value.isInitialized) {
      return _buildLoadingPlaceholder();
    }
    
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: VideoPlayer(_controller!),
    );
  }
  
  Widget _buildErrorFallback() {
    if (widget.thumbnailUrl != null) {
      return SafeNetworkImage(
        imageUrl: widget.thumbnailUrl,
        fit: BoxFit.cover,
      );
    }
    
    return Container(
      color: Colors.black,
      child: const Center(
        child: Icon(Icons.videocam_off, color: Colors.white, size: 48),
      ),
    );
  }
  
  Widget _buildLoadingPlaceholder() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
```

---

### 5. Document Path Guard System

**Location**: Create `apps/customer_app/lib/core/utils/firestore_guards.dart`

**Design**:
```dart
class FirestoreGuards {
  static bool isValidDocumentId(String? id) {
    if (id == null || id.isEmpty) {
      debugPrint('[PATH_GUARD] Blocked empty/null document ID');
      return false;
    }
    
    if (id.contains('/')) {
      debugPrint('[PATH_GUARD] Blocked invalid character in ID: $id');
      return false;
    }
    
    return true;
  }
  
  static DocumentReference? safeDoc(
    CollectionReference collection,
    String? id,
  ) {
    if (!isValidDocumentId(id)) {
      return null;
    }
    return collection.doc(id);
  }
}
```

**Application Pattern**:
```dart
// Before (unsafe)
final doc = FirebaseFirestore.instance.collection('cart').doc(userId);

// After (safe)
final doc = FirestoreGuards.safeDoc(
  FirebaseFirestore.instance.collection('cart'),
  userId,
);
if (doc == null) {
  debugPrint('[CART] Invalid user ID, aborting');
  return;
}
```

---

### 6. Model Parsing Hardening

**Pattern to Apply Across All Models**:

```dart
class ServiceModel {
  final int price;
  final double rating;
  final int reviewCount;
  
  ServiceModel({
    required this.price,
    required this.rating,
    required this.reviewCount,
  });
  
  factory ServiceModel.fromFirestore(Map<String, dynamic> data) {
    return ServiceModel(
      price: _safeInt(data['price']),
      rating: _safeDouble(data['rating']),
      reviewCount: _safeInt(data['reviewCount']),
    );
  }
  
  static int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num && value.isFinite) return value.toInt();
    debugPrint('[MODEL] Invalid int value: $value');
    return 0;
  }
  
  static double _safeDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double && value.isFinite) return value;
    if (value is num && value.isFinite) return value.toDouble();
    debugPrint('[MODEL] Invalid double value: $value');
    return 0.0;
  }
  
  static String _safeString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}
```

**Models to Harden**:
- Service models (price, rating)
- Cart models (quantity, price)
- Booking models (price, duration)
- Professional models (rating, experience)
- Review models (rating)

---

### 7. Layout Overflow Fixes

**Common Patterns to Fix**:

**Pattern 1: Long Text in Row**
```dart
// Before (causes overflow)
Row(
  children: [
    Text(longString),
  ],
)

// After (safe)
Row(
  children: [
    Expanded(
      child: Text(
        longString,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ],
)
```

**Pattern 2: Unbounded Horizontal ListView**
```dart
// Before (causes issues)
Column(
  children: [
    ListView.builder(
      scrollDirection: Axis.horizontal,
      itemBuilder: ...,
    ),
  ],
)

// After (safe)
Column(
  children: [
    SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: ...,
      ),
    ),
  ],
)
```

**Pattern 3: Expanded in Horizontal Scroll**
```dart
// Before (invalid)
ListView(
  scrollDirection: Axis.horizontal,
  children: [
    Expanded(child: ...),  // Invalid!
  ],
)

// After (safe)
ListView(
  scrollDirection: Axis.horizontal,
  children: [
    SizedBox(
      width: 200,
      child: ...,
    ),
  ],
)
```

---

### 8. User Feedback System

**Create**: `apps/customer_app/lib/core/utils/user_feedback.dart`

```dart
class UserFeedback {
  static void showLoading(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }
  
  static void hideLoading(BuildContext context) {
    Navigator.of(context).pop();
  }
  
  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  static void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
```

## Implementation Strategy

### Phase Execution Order
1. **App Check** (blocks everything else)
2. **Path Guards** (prevents crashes)
3. **Model Hardening** (prevents NaN errors)
4. **Media Safety** (prevents image/video crashes)
5. **Layout Fixes** (prevents overflow warnings)
6. **Write Guarantees** (restores functionality)
7. **User Feedback** (improves UX)
8. **Validation** (confirms success)

### Testing Strategy
- Manual testing of each critical flow
- Log monitoring for errors
- Visual inspection for layout issues
- User feedback verification

## Success Metrics

### Technical Metrics
- Zero App Check attestation failures
- Zero permission-denied errors
- Zero HttpException errors
- Zero RenderFlex overflow warnings
- Zero invalid path errors
- Zero NaN/Infinity errors

### User Experience Metrics
- All buttons provide feedback
- All operations show loading states
- All errors display messages
- No silent failures

## Rollback Plan

If issues arise:
1. Each phase is independent and can be reverted
2. Git commits per phase for easy rollback
3. Feature flags for gradual rollout (if needed)
4. Monitoring for regression detection

## Security Considerations

- No changes to Firestore rules
- No direct client writes introduced
- Callable-first architecture maintained
- App Check remains enabled in production
- All validation is defensive, not security-critical
