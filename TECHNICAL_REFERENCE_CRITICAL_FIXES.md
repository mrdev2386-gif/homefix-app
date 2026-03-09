# 📚 TECHNICAL REFERENCE - CRITICAL FIXES

## Firestore Query Architecture

### Problem: Composite Index Requirements

**Query 1 (BEFORE):**
```dart
collection('technician_services')
  .where('status', isEqualTo: 'approved')
  .where('rating', isGreaterThanOrEqualTo: 4.0)
  .orderBy('rating', descending: true)
  .orderBy('createdAt', descending: true)
  .limit(10)
```
❌ Requires composite index: `(status, rating, createdAt)`

**Query 1 (AFTER):**
```dart
collection('technician_services')
  .where('status', isEqualTo: 'approved')
  .limit(20)
  .snapshots()
  .map((snapshot) {
    final services = snapshot.docs.map(...).toList();
    services.sort((a, b) => b.rating.compareTo(a.rating));
    return services.take(10).toList();
  })
```
✅ No composite index needed

---

## Location-Based Filtering

### User Location Storage

```
customers/{uid}
├── state: "maharashtra"
├── district: "mumbai"
└── ...
```

### Service Location Storage

```
technician_services/{serviceId}
├── technicianDistrict: "mumbai"
├── status: "approved"
└── ...
```

### Filtering Logic

```dart
Future<Map<String, String>?> _getUserLocation(String userId) async {
  final userDoc = await _db.collection('customers').doc(userId).get();
  if (!userDoc.exists) return null;
  final data = userDoc.data();
  return {
    'state': (data?['state'] ?? '').toString().toLowerCase(),
    'district': (data?['district'] ?? '').toString().toLowerCase(),
  };
}

Stream<List<HomeService>> streamNearbyServices(String userId, {int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .limit(limit * 3)
      .snapshots()
      .asyncMap((snapshot) async {
        final userLocation = await _getUserLocation(userId);
        final services = snapshot.docs.map(...).toList();
        
        if (userLocation != null && userLocation['district']!.isNotEmpty) {
          return services
              .where((s) => (s.technicianDistrict?.toLowerCase() ?? '') == userLocation['district'])
              .take(limit)
              .toList();
        }
        return services.take(limit).toList();
      });
}
```

---

## Sub-Services Loading

### Firestore Path Structure

```
categories/{categoryId}
└── services/{serviceId}
    └── subServices/{subServiceId}
        ├── name: "AC Gas Refill"
        ├── price: 300
        ├── duration: "30 mins"
        └── isActive: true
```

### Query Implementation

```dart
Stream<List<HomeService>> streamSubServices(String categoryId, String serviceId) {
  return _db
      .collection('categories')
      .doc(categoryId)
      .collection('services')
      .doc(serviceId)
      .collection('subServices')
      .where('isActive', isEqualTo: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
      });
}
```

---

## Service Details Data Binding

### Firestore Document Structure

```
technician_services/{serviceId}
├── id: "service_123"
├── name: "AC Repair"
├── category: "ac_repair"
├── categoryId: "cat_123"
├── price: 300
├── basePrice: 300
├── originalPrice: 500
├── offerPrice: 300
├── imageUrl: "https://..."
├── description: "Professional AC repair"
├── rating: 4.5
├── reviewCount: 120
├── technicianId: "tech_123"
├── technicianName: "John Doe"
├── technicianDistrict: "Mumbai"
├── urgentBookingEnabled: true
├── status: "approved"
└── createdAt: Timestamp
```

### Data Fetching

```dart
Future<HomeService?> getServiceById(String serviceId) async {
  try {
    final doc = await _db.collection('technician_services').doc(serviceId).get();
    if (!doc.exists) return null;
    return HomeService.fromFirestore(doc);
  } catch (e) {
    debugPrint('Error fetching service: $e');
    return null;
  }
}
```

### UI Binding

```dart
// In service_details_screen.dart
final service = await _categoryService.getServiceById(widget.serviceId);

// Display data
Text(service.title)  // "AC Repair"
Text(service.categoryName)  // "AC Repair"
Text('${service.rating}')  // "4.5"
Text('${service.technicianName}')  // "John Doe"
Text('₹${service.basePrice}')  // "₹300"
if (service.originalPrice != null)
  Text('₹${service.originalPrice}')  // "₹500" (strikethrough)
if (service.urgentBookingEnabled)
  Badge('⚡ Urgent Available')
```

---

## Home Screen Sections Implementation

### Recommended Services (Location-Filtered)

```dart
Stream<List<HomeService>> streamRecommendedServices(String userId, {int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .limit(limit * 3)
      .snapshots()
      .asyncMap((snapshot) async {
        final userLocation = await _getUserLocation(userId);
        final services = snapshot.docs.map(...).toList();
        
        if (userLocation != null && userLocation['state']!.isNotEmpty && userLocation['district']!.isNotEmpty) {
          return services
              .where((s) => (s.technicianDistrict?.toLowerCase() ?? '') == userLocation['district'])
              .take(limit)
              .toList();
        }
        return services.take(limit).toList();
      });
}
```

### Latest Services (Newest First)

```dart
Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
      });
}
```

### Top Rated Services (Highest Rating First)

```dart
Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .limit(limit * 2)
      .snapshots()
      .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        services.sort((a, b) => b.rating.compareTo(a.rating));
        return services.take(limit).toList();
      });
}
```

### Nearby Services (Location-Filtered)

```dart
Stream<List<HomeService>> streamNearbyServices(String userId, {int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .limit(limit * 3)
      .snapshots()
      .asyncMap((snapshot) async {
        final userLocation = await _getUserLocation(userId);
        final services = snapshot.docs.map(...).toList();
        
        if (userLocation != null && userLocation['district']!.isNotEmpty) {
          return services
              .where((s) => (s.technicianDistrict?.toLowerCase() ?? '') == userLocation['district'])
              .take(limit)
              .toList();
        }
        return services.take(limit).toList();
      });
}
```

---

## Pricing Display Logic

### Service Card

```dart
// Original Price (if exists)
if (service.originalPrice != null && service.originalPrice! > 0)
  Text(
    '₹${service.originalPrice!.toStringAsFixed(0)}',
    style: TextStyle(decoration: TextDecoration.lineThrough),
  )

// Offer Price or Base Price
Text(
  '₹${(service.offerPrice ?? service.basePrice).toStringAsFixed(0)}',
  style: TextStyle(fontWeight: FontWeight.bold),
)
```

### Service Details

```dart
// Display pricing
Row(
  children: [
    if (originalPrice != null && originalPrice > 0)
      Padding(
        padding: EdgeInsets.only(right: 8),
        child: Text(
          '₹${originalPrice.toStringAsFixed(0)}',
          style: TextStyle(decoration: TextDecoration.lineThrough),
        ),
      ),
    Text(
      '₹${displayPrice.toStringAsFixed(0)}',
      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
    ),
  ],
)
```

---

## Rating Display Logic

### Service Card

```dart
// Show rating or "New"
Text(
  service.rating > 0 ? service.rating.toStringAsFixed(1) : 'New',
  style: TextStyle(fontWeight: FontWeight.bold),
)
```

### Service Details

```dart
// Show rating or "New"
Row(
  children: [
    Icon(Icons.star_rounded, color: Colors.orange),
    SizedBox(width: 4),
    Text(
      service.rating > 0 ? service.rating.toStringAsFixed(1) : 'New',
      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
    ),
  ],
)
```

---

## Urgent Booking Badge

### Service Card

```dart
if (service.urgentBookingEnabled)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.orange,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flash_on, color: Colors.white, size: 12),
        SizedBox(width: 4),
        Text(
          'Urgent',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  )
```

### Service Details

```dart
if (service.urgentBookingEnabled)
  Container(
    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.orange.withOpacity(0.1),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: Colors.orange, width: 1),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.flash_on, color: Colors.orange, size: 14),
        SizedBox(width: 4),
        Text(
          'Urgent',
          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
        ),
      ],
    ),
  )
```

---

## Error Handling

### Location Fetch Error

```dart
Future<Map<String, String>?> _getUserLocation(String userId) async {
  try {
    final userDoc = await _db.collection('customers').doc(userId).get();
    if (!userDoc.exists) return null;
    final data = userDoc.data();
    return {
      'state': (data?['state'] ?? '').toString().toLowerCase(),
      'district': (data?['district'] ?? '').toString().toLowerCase(),
    };
  } catch (e) {
    debugPrint('Error getting user location: $e');
    return null;  // Fallback: show all services
  }
}
```

### Service Fetch Error

```dart
Future<HomeService?> getServiceById(String serviceId) async {
  try {
    final doc = await _db.collection('technician_services').doc(serviceId).get();
    if (!doc.exists) return null;
    return HomeService.fromFirestore(doc);
  } catch (e) {
    debugPrint('Error fetching service: $e');
    return null;  // Fallback: show error message
  }
}
```

---

## Performance Optimization

### In-Memory Sorting

```dart
// Fetch more than needed, sort in-memory, take limit
.limit(limit * 2)  // Fetch 2x needed
.snapshots()
.map((snapshot) {
  final services = snapshot.docs.map(...).toList();
  services.sort((a, b) => b.rating.compareTo(a.rating));
  return services.take(limit).toList();  // Return only limit
})
```

### Location Filtering

```dart
// Fetch more than needed, filter by location, take limit
.limit(limit * 3)  // Fetch 3x needed
.snapshots()
.asyncMap((snapshot) async {
  final userLocation = await _getUserLocation(userId);
  final services = snapshot.docs.map(...).toList();
  
  if (userLocation != null && userLocation['district']!.isNotEmpty) {
    return services
        .where((s) => (s.technicianDistrict?.toLowerCase() ?? '') == userLocation['district'])
        .take(limit)
        .toList();
  }
  return services.take(limit).toList();
})
```

---

**Reference Document:** Complete  
**Code Examples:** All scenarios covered  
**Ready for Implementation:** ✅ YES
