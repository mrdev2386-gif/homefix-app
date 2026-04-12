## HOMEFIX PRODUCTION-READY ARCHITECTURE GUIDE

### QUICK START FOR DEVELOPERS

---

## 1. SERVICE ARCHITECTURE

### Single Source of Truth: FirestoreService
All Firestore operations go through `FirestoreService`. Never access Firestore directly from UI.

```dart
// ✅ CORRECT - Use FirestoreService
final firestoreService = FirestoreService();
final services = firestoreService.streamTechnicianServices();

// ❌ WRONG - Direct Firestore access
final services = FirebaseFirestore.instance.collection('technician_services').snapshots();
```

### Service Delegation Pattern
CategoryService, AddressService, and BookingService are thin wrappers:

```dart
// CategoryService delegates to FirestoreService
Stream<List<HomeService>> getServicesByCategory(String categoryId) {
  return _firestoreService.streamTechnicianServices(...)
      .map((services) => services.where((s) => s.categoryId == categoryId).toList());
}
```

---

## 2. FIRESTORE OPERATIONS

### All Writes Go Through Cloud Functions
Never write directly to Firestore from client:

```dart
// ✅ CORRECT - Use Cloud Function
final callable = functions.httpsCallable('manageAddress');
await callable.call({'action': 'add', 'addressData': address.toMap()});

// ❌ WRONG - Direct write
await _db.collection('customers').doc(userId).collection('addresses').add(address.toMap());
```

### Query Limits (Performance)
Always use limits to prevent unbounded queries:

```dart
// ✅ CORRECT - Limited query
final query = _db.collection('technician_services')
    .where('status', isEqualTo: 'approved')
    .orderBy('createdAt', descending: true)
    .limit(15); // Use FirebaseConstants.defaultLimit

// ❌ WRONG - Unbounded query
final query = _db.collection('technician_services').snapshots();
```

### Pagination Support
Use cursor-based pagination for large datasets:

```dart
// First page
final firstPage = await firestoreService.streamTechnicianServices(limit: 15).first;

// Next page (using last document as cursor)
final lastDoc = firstPage.last;
final nextPage = await firestoreService.streamTechnicianServices(
  limit: 15,
  startAfter: lastDoc,
).first;
```

### Firestore OrderBy (Not In-Memory Sorting)
Always use Firestore `orderBy` instead of sorting in Dart:

```dart
// ✅ CORRECT - Firestore orderBy
final query = _db.collection('banners')
    .where('active', isEqualTo: true)
    .orderBy('order')
    .limit(10);

// ❌ WRONG - In-memory sorting
final banners = await _db.collection('banners').get();
final sorted = banners.docs.map(...).toList();
sorted.sort((a, b) => a.order.compareTo(b.order)); // SLOW!
```

---

## 3. ERROR HANDLING

### Proper Error Propagation
Never silently convert errors to empty lists:

```dart
// ✅ CORRECT - Proper error handling
Stream<List<Booking>> getBookings(String userId) {
  return _db.collection('bookings')
      .where('customerId', isEqualTo: userId)
      .snapshots()
      .handleError((e) {
        if (kDebugMode) debugPrint('Error: $e');
        throw e; // Propagate error to UI
      });
}

// ❌ WRONG - Silent failure
Stream<List<Booking>> getBookings(String userId) {
  return _db.collection('bookings')
      .where('customerId', isEqualTo: userId)
      .snapshots()
      .handleError((e) => <Booking>[]); // Hides errors!
}
```

### Retry on Authentication Failure
Automatically retry with fresh token:

```dart
try {
  await callable.call(data);
} catch (e) {
  if (e is FirebaseFunctionsException && e.code == 'unauthenticated') {
    await user.getIdToken(true); // Refresh token
    final retryCallable = functions.httpsCallable('functionName');
    await retryCallable.call(data); // Retry
  } else {
    rethrow;
  }
}
```

---

## 4. INPUT VALIDATION

### Validate Before Sending to Backend
Always validate IDs and data:

```dart
// ✅ CORRECT - Validate before sending
if (!FirestoreGuards.isValidDocumentId(userId)) {
  throw Exception('Invalid user ID');
}
if (item.serviceId.isEmpty) {
  throw Exception('serviceId is mandatory');
}
if (item.price <= 0) {
  throw Exception('price must be > 0');
}

final callable = functions.httpsCallable('addToCart');
await callable.call(item.toMap());

// ❌ WRONG - No validation
await functions.httpsCallable('addToCart').call(item.toMap());
```

---

## 5. LOGGING

### Use debugPrint Instead of print()
Prevents sensitive data in production logs:

```dart
// ✅ CORRECT - debugPrint
if (kDebugMode) {
  debugPrint('User ID: $userId');
  debugPrint('Booking created: $bookingId');
}

// ❌ WRONG - print() in production
print('User ID: $userId'); // Visible in production!
```

---

## 6. CONSTANTS

### Use FirebaseConstants
Centralized configuration for easy maintenance:

```dart
import '../constants/firebase_constants.dart';

// ✅ CORRECT - Use constants
final query = _db.collection(FirebaseConstants.customersCollection)
    .doc(userId)
    .collection(FirebaseConstants.addressesSubcollection)
    .limit(FirebaseConstants.defaultLimit);

// ❌ WRONG - Hardcoded strings
final query = _db.collection('customers')
    .doc(userId)
    .collection('addresses')
    .limit(15);
```

### Available Constants
```dart
// Collections
FirebaseConstants.customersCollection // 'customers'
FirebaseConstants.bookingsCollection // 'bookings'
FirebaseConstants.technicianServicesCollection // 'technician_services'

// Limits
FirebaseConstants.defaultLimit // 15
FirebaseConstants.maxLimit // 100
FirebaseConstants.bannerLimit // 10

// Status values
FirebaseConstants.statusApproved // 'approved'
FirebaseConstants.bookingStatusConfirmed // 'confirmed'
```

---

## 7. DEPENDENCY INJECTION

### Services Are Injected
Never create services directly:

```dart
// ✅ CORRECT - Use Provider
final firestoreService = Provider.of<FirestoreService>(context);
final bookings = firestoreService.streamBookings(userId);

// ❌ WRONG - Create directly
final firestoreService = FirestoreService();
```

### Constructor Injection for Testing
Services accept dependencies:

```dart
// Production
final categoryService = CategoryService();

// Testing with mock
final mockFirestore = MockFirestoreService();
final categoryService = CategoryService(firestoreService: mockFirestore);
```

---

## 8. CACHING STRATEGY

### Cached Streams
Services cache streams to prevent duplicate reads:

```dart
// First call - fetches from Firestore
final services1 = firestoreService.getCachedServicesStream();

// Second call - returns cached stream
final services2 = firestoreService.getCachedServicesStream();

// Clear cache when location changes
firestoreService.clearCachedServicesStream();
```

### User Interaction Cache
Personalization data is cached for 5 minutes:

```dart
// First call - fetches from Firestore
final data = await firestoreService.getUserInteractionData(userId);

// Within 5 minutes - returns cached data
final data2 = await firestoreService.getUserInteractionData(userId);

// Clear cache when cart/favorites change
firestoreService.clearUserInteractionCache();
```

---

## 9. PAGINATION EXAMPLE

### Implementing Infinite Scroll
```dart
class ServiceListProvider extends ChangeNotifier {
  List<HomeService> services = [];
  DocumentSnapshot? lastDocument;
  bool isLoading = false;
  bool hasMore = true;

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;
    
    isLoading = true;
    notifyListeners();

    try {
      final newServices = await firestoreService
          .streamTechnicianServices(
            limit: 15,
            startAfter: lastDocument,
          )
          .first;

      if (newServices.isEmpty) {
        hasMore = false;
      } else {
        services.addAll(newServices);
        lastDocument = newServices.last; // Store for next page
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
```

---

## 10. COMMON PATTERNS

### Stream with Error Handling
```dart
StreamBuilder<List<Booking>>(
  stream: firestoreService.streamBookings(userId),
  builder: (context, snapshot) {
    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error);
    }
    if (!snapshot.hasData) {
      return LoadingWidget();
    }
    return BookingList(bookings: snapshot.data!);
  },
)
```

### Async Operation with Validation
```dart
Future<void> saveAddress(Address address) async {
  try {
    // Validate
    if (address.fullAddress.isEmpty) {
      throw Exception('Address is required');
    }
    
    // Call Cloud Function
    await firestoreService.saveAddress(userId, address);
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Address saved')),
    );
  } catch (e) {
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

---

## CHECKLIST FOR NEW FEATURES

When adding new features, ensure:

- [ ] All Firestore writes go through Cloud Functions
- [ ] Input validation before sending to backend
- [ ] Proper error handling and propagation
- [ ] Query limits applied (use FirebaseConstants)
- [ ] Use Firestore orderBy instead of in-memory sorting
- [ ] Use debugPrint instead of print()
- [ ] Services injected via Provider
- [ ] Pagination support for list queries
- [ ] Cache invalidation when data changes
- [ ] No direct Firestore access from UI

---

## TROUBLESHOOTING

### Issue: "Unauthenticated" Error
**Solution:** Ensure token refresh before Cloud Function call
```dart
final user = FirebaseAuth.instance.currentUser;
await user?.getIdToken(true); // Refresh token
```

### Issue: Slow Queries
**Solution:** Check for in-memory sorting and add limits
```dart
// ❌ SLOW
final items = await _db.collection('items').get();
items.docs.sort(...); // In-memory sorting

// ✅ FAST
final items = await _db.collection('items')
    .orderBy('createdAt')
    .limit(15)
    .get();
```

### Issue: Memory Leaks
**Solution:** Clear caches when data changes
```dart
firestoreService.clearCachedServicesStream();
firestoreService.clearUserInteractionCache();
```

---

## RESOURCES

- **Firebase Constants**: `lib/core/constants/firebase_constants.dart`
- **Firestore Service**: `lib/core/services/firestore_service.dart`
- **Firestore Guards**: `lib/core/utils/firestore_guards.dart`
- **Production Summary**: `PRODUCTION_READY_FIXES_SUMMARY.md`

---

**Last Updated:** 2025
**Status:** Production Ready ✅
