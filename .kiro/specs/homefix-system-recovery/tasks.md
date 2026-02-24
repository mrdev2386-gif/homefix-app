# HomeFix Deep System Recovery - Implementation Tasks

## Task List

- [x] 1. App Check Initialization Fix
  - [x] 1.1 Locate Firebase initialization file
  - [x] 1.2 Implement correct initialization order
  - [x] 1.3 Add token change listener
  - [x] 1.4 Add initialization guard
  - [x] 1.5 Verify token appears in logs

- [-] 2. Document Path Guards
  - [x] 2.1 Create FirestoreGuards utility class
  - [x] 2.2 Apply guards to cart service
  - [x] 2.3 Apply guards to favorites service
  - [x] 2.4 Apply guards to address service
  - [x] 2.5 Apply guards to booking service
  - [x] 2.6 Apply guards to notification service
  - [x] 2.7 Apply guards to profile service

- [-] 3. Model Parsing Hardening
  - [x] 3.1 Create safe parsing utility functions
  - [x] 3.2 Harden service models
  - [x] 3.3 Harden cart models
  - [x] 3.4 Harden booking models
  - [x] 3.5 Harden professional models
  - [x] 3.6 Harden review models
  - [x] 3.7 Test with invalid Firestore data

- [-] 4. SafeNetworkImage Implementation
  - [x] 4.1 Create SafeNetworkImage widget
  - [x] 4.2 Find all Image.network usages
  - [x] 4.3 Find all CachedNetworkImage usages
  - [x] 4.4 Replace with SafeNetworkImage
  - [x] 4.5 Test image loading and fallbacks

- [-] 5. Video Player Hardening
  - [-] 5.1 Create SafeVideoPlayer widget
  - [x] 5.2 Update ProfessionalReelsSection
  - [x] 5.3 Add URL validation
  - [x] 5.4 Add error handling
  - [x] 5.5 Add retry logic
  - [x] 5.6 Test with invalid video URLs

- [ ] 6. Layout Overflow Fixes
  - [ ] 6.1 Scan for Row with long Text
  - [ ] 6.2 Scan for unbounded horizontal ListView
  - [ ] 6.3 Scan for Expanded in horizontal scroll
  - [ ] 6.4 Fix identified overflow issues
  - [ ] 6.5 Verify zero overflow warnings

- [ ] 7. Write Operation Guarantees
  - [x] 7.1 Create UserFeedback utility
  - [ ] 7.2 Audit cart service operations
  - [ ] 7.3 Audit favorites service operations
  - [ ] 7.4 Audit address service operations
  - [ ] 7.5 Audit profile service operations
  - [ ] 7.6 Audit notification service operations
  - [ ] 7.7 Audit booking service operations
  - [ ] 7.8 Add logging to all operations
  - [ ] 7.9 Add user feedback to all operations
  - [ ] 7.10 Remove silent failure paths

- [ ] 8. Final Validation
  - [ ] 8.1 Verify App Check token in logs
  - [ ] 8.2 Test cart operations
  - [ ] 8.3 Test favorites operations
  - [ ] 8.4 Test address save operations
  - [ ] 8.5 Test image loading
  - [ ] 8.6 Test video playback
  - [ ] 8.7 Check for overflow warnings
  - [ ] 8.8 Check for invalid path errors
  - [ ] 8.9 Check for NaN/Infinity errors
  - [ ] 8.10 Verify user feedback on all operations

## Task Details

### 1.1 Locate Firebase initialization file
**Description**: Find where Firebase is initialized in the app (likely main.dart or a dedicated firebase_init.dart file)

**Files to check**:
- `apps/customer_app/lib/main.dart`
- `apps/customer_app/lib/core/config/firebase_init.dart`
- `apps/customer_app/lib/core/services/firebase_service.dart`

### 1.2 Implement correct initialization order
**Description**: Ensure Firebase.initializeApp() is called before FirebaseAppCheck.instance.activate()

**Implementation**:
```dart
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);

await FirebaseAppCheck.instance.activate(
  androidProvider: kDebugMode 
    ? AndroidProvider.debug 
    : AndroidProvider.playIntegrity,
  appleProvider: kDebugMode
    ? AppleProvider.debug
    : AppleProvider.deviceCheck,
);
```

### 1.3 Add token change listener
**Description**: Add listener to monitor App Check token generation

**Implementation**:
```dart
FirebaseAppCheck.instance.onTokenChange.listen((token) {
  debugPrint('[APP_CHECK_TOKEN] ${token ?? "null"}');
});
```

### 1.4 Add initialization guard
**Description**: Prevent duplicate initialization

**Implementation**:
```dart
static bool _initialized = false;

static Future<void> initialize() async {
  if (_initialized) return;
  // ... initialization code
  _initialized = true;
}
```

### 2.1 Create FirestoreGuards utility class
**Description**: Create utility class for validating document IDs

**Location**: `apps/customer_app/lib/core/utils/firestore_guards.dart`

**Implementation**: See design document

### 2.2-2.7 Apply guards to services
**Description**: Apply FirestoreGuards.safeDoc() to all Firestore document references

**Pattern**:
```dart
final doc = FirestoreGuards.safeDoc(
  FirebaseFirestore.instance.collection('collectionName'),
  documentId,
);
if (doc == null) {
  debugPrint('[SERVICE] Invalid document ID');
  return;
}
```

### 3.1 Create safe parsing utility functions
**Description**: Create _safeInt, _safeDouble, _safeString helper functions

**Implementation**: See design document

### 3.2-3.6 Harden models
**Description**: Replace all direct field access with safe parsing functions

**Pattern**:
```dart
factory Model.fromFirestore(Map<String, dynamic> data) {
  return Model(
    price: _safeInt(data['price']),
    rating: _safeDouble(data['rating']),
    name: _safeString(data['name']),
  );
}
```

### 4.1 Create SafeNetworkImage widget
**Description**: Create widget that validates URLs and handles errors gracefully

**Location**: `apps/customer_app/lib/core/widgets/safe_network_image.dart`

**Implementation**: See design document

### 4.2-4.3 Find image usages
**Description**: Search codebase for Image.network and CachedNetworkImage

**Commands**:
```bash
grep -r "Image.network" apps/customer_app/lib/
grep -r "CachedNetworkImage" apps/customer_app/lib/
```

### 4.4 Replace with SafeNetworkImage
**Description**: Replace all found usages with SafeNetworkImage

**Pattern**:
```dart
// Before
Image.network(url)

// After
SafeNetworkImage(imageUrl: url)
```

### 5.1 Create SafeVideoPlayer widget
**Description**: Create widget that validates video URLs and handles errors

**Location**: `apps/customer_app/lib/core/widgets/safe_video_player.dart`

**Implementation**: See design document

### 5.2 Update ProfessionalReelsSection
**Description**: Replace direct VideoPlayerController usage with SafeVideoPlayer

**File**: `apps/customer_app/lib/features/dashboard/widgets/professional_reels_section.dart`

### 6.1-6.3 Scan for layout issues
**Description**: Search for common overflow patterns

**Patterns to find**:
- Row with Text (no Expanded)
- ListView without height constraint
- Expanded in horizontal scroll

### 6.4 Fix identified overflow issues
**Description**: Apply appropriate fixes based on pattern

**Fixes**:
- Add Expanded + overflow to Text
- Add SizedBox height to ListView
- Replace Expanded with SizedBox width

### 7.1 Create UserFeedback utility
**Description**: Create utility for consistent user feedback

**Location**: `apps/customer_app/lib/core/utils/user_feedback.dart`

**Implementation**: See design document

### 7.2-7.7 Audit service operations
**Description**: Review each service method for proper error handling and feedback

**Checklist per operation**:
- [ ] Has try/catch block
- [ ] Logs operation start
- [ ] Logs success/failure
- [ ] Shows loading state
- [ ] Shows success feedback
- [ ] Shows error feedback
- [ ] No silent returns after errors

### 7.8 Add logging to all operations
**Description**: Add debugPrint statements for operation lifecycle

**Pattern**:
```dart
debugPrint('[OPERATION_NAME] Starting...');
// ... operation
debugPrint('[OPERATION_NAME] Success');
```

### 7.9 Add user feedback to all operations
**Description**: Use UserFeedback utility for all user-facing operations

**Pattern**:
```dart
try {
  // operation
  UserFeedback.showSuccess(context, 'Operation completed');
} catch (e) {
  UserFeedback.showError(context, 'Operation failed: $e');
}
```

### 7.10 Remove silent failure paths
**Description**: Ensure no operation can fail without user notification

**Check for**:
- Early returns without feedback
- Caught exceptions without user notification
- Missing error handling

### 8.1-8.10 Final Validation
**Description**: Comprehensive testing of all fixed systems

**Test Procedure**:
1. Check logs for App Check token
2. Perform cart add/remove operations
3. Toggle favorites
4. Save new address
5. Load screens with images
6. Play professional reels
7. Monitor logs for overflow warnings
8. Monitor logs for path errors
9. Monitor logs for NaN errors
10. Verify all operations show feedback

## Execution Notes

- Execute tasks in order (dependencies exist)
- Test after each major phase
- Commit after each completed task group
- Monitor logs continuously during testing
- Do not skip validation tasks

## Success Criteria

All tasks complete AND:
- Zero App Check errors
- Zero permission-denied errors
- Zero image crash errors
- Zero video crash errors
- Zero layout overflow warnings
- Zero invalid path errors
- Zero NaN/Infinity errors
- All user operations provide feedback
