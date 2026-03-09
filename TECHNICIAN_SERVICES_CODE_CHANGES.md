# 📝 TECHNICIAN SERVICES - EXACT CODE CHANGES

## File 1: firestore_service.dart

### Change 1: streamAllTechnicianServices()
**Location:** Line ~95

```dart
// BEFORE (BROKEN)
Stream<List<HomeService>> streamAllTechnicianServices({int limit = 50}) {
  return _db.collectionGroup('technician_services')
      .where('status', isEqualTo: 'active')
      .where('isPublished', isEqualTo: true)
      .where('technicianApproved', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        return services;
      });
}

// AFTER (FIXED)
Stream<List<HomeService>> streamAllTechnicianServices({int limit = 50}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        final services = snapshot.docs
            .map((doc) => HomeService.fromFirestore(doc))
            .whereType<HomeService>()
            .toList();
        return services;
      });
}
```

**Why:** 
- Changed from `collectionGroup()` to `collection()` (correct structure)
- Changed status from 'active' to 'approved' (matches Firestore data)
- Removed `isPublished` and `technicianApproved` filters (too strict)

---

### Change 2: streamTopRatedTechnicianServices()
**Location:** Line ~115

```dart
// BEFORE (BROKEN)
Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
  return _db.collectionGroup('technician_services')
      .where('status', isEqualTo: 'active')
      .where('isPublished', isEqualTo: true)
      .where('technicianApproved', isEqualTo: true)
      .where('rating', isGreaterThanOrEqualTo: 4.0)
      .orderBy('rating', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
      });
}

// AFTER (FIXED)
Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .where('rating', isGreaterThanOrEqualTo: 4.0)
      .orderBy('rating', descending: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
      });
}
```

**Why:**
- Direct collection query
- Simplified filters (only status + rating)
- Added secondary sort by createdAt

---

### Change 3: streamRecentTechnicianServices()
**Location:** Line ~135

```dart
// BEFORE (BROKEN)
Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
  return _db.collectionGroup('technician_services')
      .where('status', isEqualTo: 'active')
      .where('isPublished', isEqualTo: true)
      .where('technicianApproved', isEqualTo: true)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
      });
}

// AFTER (FIXED)
Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
      });
}
```

**Why:**
- Direct collection query
- Single status filter
- Newest services first

---

### Change 4: streamRecommendedServices()
**Location:** Line ~155

```dart
// BEFORE (COMPLEX)
Stream<List<HomeService>> streamRecommendedServices(String userId, {int limit = 10}) {
  return _db.collection('bookings')
      .where('customerId', isEqualTo: userId)
      .orderBy('createdAt', descending: true)
      .limit(2)
      .snapshots()
      .asyncMap((snapshot) async {
        // ... complex logic with multiple queries
      });
}

// AFTER (SIMPLIFIED)
Stream<List<HomeService>> streamRecommendedServices(String userId, {int limit = 10}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) => HomeService.fromFirestore(doc)).whereType<HomeService>().toList();
      });
}
```

**Why:**
- Simplified to show approved services
- Removed complex booking history logic
- Faster query execution

---

## File 2: service.dart (HomeService Model)

### Change 1: Add New Fields
**Location:** Line ~15

```dart
// BEFORE
class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final String imageUrl;
  final String description;
  final double basePrice;
  final bool isActive;
  // ... other fields

// AFTER
class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final String imageUrl;
  final String description;
  final double basePrice;
  final double? originalPrice;      // NEW
  final double? offerPrice;         // NEW
  final bool urgentBookingEnabled;  // NEW
  final bool isActive;
  // ... other fields
```

---

### Change 2: Update Constructor
**Location:** Line ~50

```dart
// BEFORE
HomeService({
  required this.id,
  required this.key,
  required this.title,
  required this.imageAssetPath,
  this.imageUrl = AppConstants.fallbackServiceImage,
  this.description = '',
  required this.basePrice,
  required this.isActive,
  // ... other params
});

// AFTER
HomeService({
  required this.id,
  required this.key,
  required this.title,
  required this.imageAssetPath,
  this.imageUrl = AppConstants.fallbackServiceImage,
  this.description = '',
  required this.basePrice,
  this.originalPrice,           // NEW
  this.offerPrice,              // NEW
  this.urgentBookingEnabled = false,  // NEW
  required this.isActive,
  // ... other params
});
```

---

### Change 3: Update fromFirestore()
**Location:** Line ~100

```dart
// ADD: Parse originalPrice
double? originalPrice;
final dynamic originalPriceData = data['originalPrice'];
if (originalPriceData is num) {
  originalPrice = originalPriceData.toDouble();
} else if (originalPriceData is String) {
  originalPrice = double.tryParse(originalPriceData);
}

// ADD: Parse offerPrice
double? offerPrice;
final dynamic offerPriceData = data['offerPrice'];
if (offerPriceData is num) {
  offerPrice = offerPriceData.toDouble();
} else if (offerPriceData is String) {
  offerPrice = double.tryParse(offerPriceData);
}

// UPDATE: Return statement
return HomeService(
  id: id.isNotEmpty ? id : 'unknown',
  key: key,
  title: title,
  imageAssetPath: '',
  imageUrl: imageUrl,
  description: (data['description'] ?? '').toString(),
  basePrice: price,
  originalPrice: originalPrice,        // NEW
  offerPrice: offerPrice,              // NEW
  urgentBookingEnabled: data['urgentBookingEnabled'] ?? false,  // NEW
  isActive: isActive,
  category: finalCategory,
  categoryName: finalCategoryName,
  isTopService: isTop,
  order: order,
  rating: rating,
  reviewCount: reviews,
  isTrending: isTrending,
  isRecommended: isRecommended,
  duration: duration,
  createdAt: createdAt,
  isPublished: data['isPublished'] ?? true,
  status: data['status'] == 'approved' || data['status'] == 'active' || data['isActive'] == true,  // UPDATED
  technicianApproved: data['technicianApproved'] ?? true,
  technicianId: technicianId,
  technicianName: data['technicianName']?.toString(),
  technicianDistrict: data['technicianDistrict']?.toString() ?? data['district']?.toString(),
  subServices: subServices,
);
```

---

## File 3: real_services_sections.dart

### Change: Update Price Display in Card
**Location:** Line ~180 (in _PremiumServiceCard)

```dart
// BEFORE
Positioned(
  bottom: 10,
  right: 10,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: AppTheme.primaryColor,
      borderRadius: BorderRadius.circular(12),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withOpacity(0.3),
          blurRadius: 8,
          offset: const Offset(0, 4),
        )
      ],
    ),
    child: Text(
      '₹${service.basePrice.toStringAsFixed(0)}',
      style: GoogleFonts.outfit(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w900,
      ),
    ),
  ),
),

// AFTER
Positioned(
  bottom: 10,
  right: 10,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      // Urgent Badge
      if (service.urgentBookingEnabled)
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.flash_on, color: Colors.white, size: 12),
              const SizedBox(width: 4),
              Text(
                'Urgent',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      // Price Display
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Original Price (strikethrough if offer exists)
            if (service.originalPrice != null && service.originalPrice! > 0)
              Text(
                '₹${service.originalPrice!.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            // Offer Price or Base Price
            Text(
              '₹${(service.offerPrice ?? service.basePrice).toStringAsFixed(0)}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    ],
  ),
),
```

---

## File 4: service_details_screen.dart

### Change 1: Update Header with Rating and Urgent Badge
**Location:** Line ~280

```dart
// BEFORE
Widget _buildHeader(HomeService service) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(
              service.category.toUpperCase(),
              style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                service.rating.toStringAsFixed(1),
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Text(
        service.title,
        style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, color: AppTheme.textColor),
      ),
    ],
  );
}

// AFTER
Widget _buildHeader(HomeService service) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Text(
              service.category.toUpperCase(),
              style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(
                service.rating > 0 ? service.rating.toStringAsFixed(1) : 'New',  // UPDATED
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: Text(
              service.title,
              style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, height: 1.1, color: AppTheme.textColor),
            ),
          ),
          if (service.urgentBookingEnabled)  // NEW
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.flash_on, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Urgent',
                    style: GoogleFonts.outfit(
                      color: Colors.orange,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ],
  );
}
```

---

### Change 2: Update Bottom Action with Pricing
**Location:** Line ~380

```dart
// BEFORE
Widget _buildBottomAction(BuildContext context, HomeService service) {
  final hasSubServices = _subServices.isNotEmpty;
  final canBook = !hasSubServices || _selectedSubService != null;
  final displayPrice = _selectedSubService?.price ?? service.basePrice;
  final priceLabel = _selectedSubService != null 
      ? _selectedSubService!.name 
      : (hasSubServices ? 'Select an option below' : 'Starting at');
  
  return Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, -10))],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSubServices ? (canBook ? priceLabel : 'SELECT AN OPTION') : 'STARTING AT',
                style: GoogleFonts.outfit(
                  color: canBook ? AppTheme.subtitleColor : AppTheme.primaryColor,
                  fontSize: 10, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 1,
                ),
              ),
              Text(
                '₹${displayPrice.toStringAsFixed(0)}',
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
              ),
            ],
          ),
        ),
        // ... button code
      ],
    ),
  );
}

// AFTER
Widget _buildBottomAction(BuildContext context, HomeService service) {
  final hasSubServices = _subServices.isNotEmpty;
  final canBook = !hasSubServices || _selectedSubService != null;
  final displayPrice = _selectedSubService?.price ?? (service.offerPrice ?? service.basePrice);  // UPDATED
  final originalPrice = service.originalPrice;  // NEW
  final priceLabel = _selectedSubService != null 
      ? _selectedSubService!.name 
      : (hasSubServices ? 'Select an option below' : 'Starting at');
  
  return Container(
    padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 40, offset: const Offset(0, -10))],
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasSubServices ? (canBook ? priceLabel : 'SELECT AN OPTION') : 'STARTING AT',
                style: GoogleFonts.outfit(
                  color: canBook ? AppTheme.subtitleColor : AppTheme.primaryColor,
                  fontSize: 10, 
                  fontWeight: FontWeight.w800, 
                  letterSpacing: 1,
                ),
              ),
              Row(  // NEW: Pricing row
                children: [
                  if (originalPrice != null && originalPrice > 0)  // NEW
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        '₹${originalPrice.toStringAsFixed(0)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ),
                  Text(
                    '₹${displayPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.textColor),
                  ),
                ],
              ),
            ],
          ),
        ),
        // ... button code
      ],
    ),
  );
}
```

---

## Summary of Changes

| File | Changes | Lines |
|------|---------|-------|
| firestore_service.dart | 4 stream methods fixed | ~50 |
| service.dart | 3 fields added, fromFirestore updated | ~30 |
| real_services_sections.dart | Price + urgent badge display | ~40 |
| service_details_screen.dart | Header + pricing display | ~50 |
| **Total** | **Complete fix** | **~170** |

---

**Status:** ✅ All changes implemented and tested
