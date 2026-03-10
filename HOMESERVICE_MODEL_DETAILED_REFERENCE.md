# HomeService Model - Complete Reference

**File:** `lib/core/models/service.dart`  
**Purpose:** Core data model for all service display throughout the customer app

---

## Class Declaration

```dart
class HomeService {
  final String id;
  final String key;
  final String title;
  final String imageAssetPath;
  final String imageUrl;
  final String description;
  final double basePrice;
  final double? originalPrice;
  final double? offerPrice;
  final bool urgentBookingEnabled;
  final bool isActive;
  final String category;
  final String categoryName;
  final bool isTopService;
  final int order;
  final double rating;
  final int reviewCount;
  final bool isTrending;
  final bool isRecommended;
  final String duration;
  final DateTime createdAt;
  final bool isPublished;
  final bool status;
  final bool technicianApproved;
  final String? technicianId;
  final String? technicianName;
  final String? technicianDistrict;
  final List<SubService> subServices;
}
```

---

## Property Details

### Core Identification

#### `id: String`
- **Source:** Firestore document ID
- **Null Safe:** No (always populated)
- **Example:** `"service_abc12345"`
- **Usage:** Primary key for navigation and API calls
- **Mapping:** DocumentSnapshot.id

---

#### `key: String`
- **Source:** Firestore field `id`, `serviceId`, `key`, or fallback to `id`
- **Null Safe:** No (always populated)
- **Example:** `"service_key_123"`
- **Usage:** Secondary identifier, sometimes used for lookups
- **Parsing Priority:** data['id'] → data['serviceId'] → data['key'] → doc id

---

#### `title: String`
- **Source:** Firestore field `name` or `title`
- **Null Safe:** No (fallback: "Service")
- **Example:** `"Professional Cleaning Service"`
- **Usage:** Display in service cards and headers
- **Parsing Priority:** data['name'] → data['title']
- **Alias Property:** `name` getter (returns title)

---

### Image & Media

#### `imageUrl: String`
- **Source:** Firestore field with fallback chain
- **Null Safe:** NO - **NEVER NULL** (safety guarantee)
- **Fallback Order:**
  1. `imageUrl` (preferred)
  2. `image` 
  3. `thumbnail`
  4. `bannerUrl`
  5. `imageAssetPath`
  6. `AppConstants.fallbackServiceImage` (global fallback)
- **Example:** `"https://storage.googleapis.com/.../service_image.jpg"`
- **Usage:** Safe to use directly in Image.network()
- **Why Safe:** All parsing paths ensure non-null value
- **Parsing Code:**
  ```dart
  String? imageUrl = (data['imageUrl'] ?? data['image'] ?? 
    data['thumbnail'] ?? data['bannerUrl'] ?? 
    data['imageAssetPath'])?.toString().trim();
  
  if (imageUrl == null || imageUrl.isEmpty) {
    imageUrl = AppConstants.fallbackServiceImage;
  }
  ```

---

#### `imageAssetPath: String`
- **Source:** Firestore field (deprecated)
- **Current Status:** DEPRECATED
- **Reason:** Network images (imageUrl) are preferred over assets
- **Usage:** None (legacy support)
- **Value:** Always empty string in new services

---

### Pricing

#### `basePrice: double`
- **Source:** Firestore field `price` or `basePrice`
- **Null Safe:** No (fallback: 0.0)
- **Type Handling:** Accepts num, String, null
- **Example:** `₹499.99`
- **Usage:** List price / regular price
- **Alias Property:** `price` getter (returns basePrice)
- **Parsing Logic:**
  ```dart
  double price = 0.0;
  final dynamic priceData = data['price'] ?? data['basePrice'];
  if (priceData is num) {
    price = priceData.toDouble();
  } else if (priceData is String) {
    price = double.tryParse(priceData) ?? 0.0;
  }
  ```

---

#### `originalPrice: double?`
- **Source:** Firestore field `originalPrice`
- **Null Safe:** Yes - can be null
- **Type Handling:** Accepts num, String, null
- **Example:** `₹699.99`
- **Usage:** Display with strikethrough when offer exists
- **When to Show:** When `originalPrice < basePrice`
- **Purpose:** Shows original list price before discount

---

#### `offerPrice: double?`
- **Source:** Firestore field `offerPrice`
- **Null Safe:** Yes - can be null
- **Type Handling:** Accepts num, String, null
- **Example:** `₹399.99`
- **Usage:** Discounted price to display prominently
- **When Valid:** offerPrice > 0 AND offerPrice < basePrice
- **Must Check:**
  ```dart
  final hasOffer = service.offerPrice != null && 
                   service.offerPrice! > 0 && 
                   service.offerPrice! < service.basePrice;
  ```

---

### Service Classification

#### `category: String`
- **Source:** Firestore field `category`, `categoryId`
- **Null Safe:** No (fallback: empty string)
- **Example:** `"cleaning"`, `"electrical"`, `"plumbing"`
- **Usage:** Service category identifier for filtering and grouping
- **Path Inference:** Extracted from Firestore path if missing
- **Parsing:**
  ```dart
  String? categoryId = data['category'] ?? data['categoryId'];
  
  if (categoryId == null || categoryId.toString().isEmpty) {
    // Try to infer from document path: categories/{catId}/services/{serviceId}
    final pathSegments = doc.reference.path.split('/');
    final catIndex = pathSegments.indexOf('categories');
    if (catIndex != -1 && catIndex + 1 < pathSegments.length) {
      categoryId = pathSegments[catIndex + 1];
    }
  }
  
  // Final fallback: empty string (logging warning)
  if (categoryId == null || categoryId.toString().isEmpty) {
    categoryId = '';
  }
  ```

---

#### `categoryName: String`
- **Source:** Firestore field `categoryName` or `category`
- **Null Safe:** No (fallback: "General")
- **Example:** `"Home Cleaning"`, `"Electrical Repair"`
- **Usage:** Display-friendly category label
- **Parsing:** data['categoryName'] → data['category']

---

### Flags & Status

#### `isActive: bool`
- **Source:** Firestore field `isActive`
- **Null Safe:** No (default: true)
- **True Meaning:** Service is currently available
- **False Meaning:** Service is inactive/archived
- **Usage:** Filter in service lists

---

#### `status: bool` (Derived)
- **Source:** Derived from Firestore field `status`, `isActive`
- **Computation:**
  ```dart
  status: data['status'] == 'approved' || 
          data['status'] == 'active' || 
          data['isActive'] == true
  ```
- **True Meanings:** status='approved' OR status='active' OR isActive=true
- **Usage:** Display eligibility check
- **Alias:** `isActiveStatus` getter

---

#### `isPublished: bool`
- **Source:** Firestore field `isPublished`
- **Null Safe:** No (default: true)
- **Usage:** Editorial control flag

---

#### `technicianApproved: bool`
- **Source:** Firestore field `technicianApproved`
- **Null Safe:** No (default: true)
- **Usage:** Admin approval status

---

#### `isTopService: bool`
- **Source:** Firestore field `isTopService`
- **Null Safe:** No (default: false)
- **Effect:** Shows "PREMIUM" badge on card
- **Usage:** Featured service highlighting

---

#### `isTrending: bool`
- **Source:** Firestore field `isTrending`
- **Null Safe:** No (default: false)
- **Effect:** Shows "Trending" badge with flash icon
- **Usage:** Highlight popular services

---

#### `isRecommended: bool`
- **Source:** Firestore field `isRecommended`
- **Null Safe:** No (default: false)
- **Usage:** Section filtering and recommendation logic

---

#### `urgentBookingEnabled: bool`
- **Source:** Firestore field `urgentBookingEnabled`
- **Null Safe:** No (default: false)
- **Meaning:** Service can be booked with urgent/rush fees
- **Usage:** UI marker for urgent booking availability

---

### Ratings & Reviews

#### `rating: double`
- **Source:** Firestore field `rating`, `ratingValue`
- **Null Safe:** No (fallback: 0.0)
- **Type Handling:** Accepts num, String, null
- **Range:** 0.0 - 5.0
- **Example:** `4.5`
- **Usage:** Display star rating
- **Display Formula:** `(rating / 5) * 100` for percentage
- **Parsing:**
  ```dart
  double rating = 0.0;
  final dynamic ratingData = data['rating'] ?? data['ratingValue'];
  if (ratingData is num) {
    rating = ratingData.toDouble();
  } else if (ratingData is String) {
    rating = double.tryParse(ratingData) ?? 0.0;
  }
  ```

---

#### `reviewCount: int`
- **Source:** Firestore field `reviewCount`, `reviews`
- **Null Safe:** No (fallback: 0)
- **Type Handling:** Accepts num, String, null
- **Example:** `127`
- **Usage:** Display "127 reviews" text
- **Parsing:**
  ```dart
  int reviews = 0;
  final dynamic reviewsDataRaw = data['reviewCount'] ?? data['reviews'] ?? 0;
  if (reviewsDataRaw is num) {
    reviews = (reviewsDataRaw.isFinite ? reviewsDataRaw : 0).toInt();
  } else if (reviewsDataRaw is String) {
    reviews = int.tryParse(reviewsDataRaw) ?? 0;
  }
  ```

---

### Metadata

#### `duration: String`
- **Source:** Firestore field `duration`
- **Null Safe:** No (fallback: "1 hour")
- **Example:** `"2 hours"`, `"30 minutes"`, `"1-2 hours"`
- **Usage:** Display estimated service duration
- **Format:** Human-readable string

---

#### `description: String`
- **Source:** Firestore field `description`
- **Null Safe:** No (fallback: empty string)
- **Example:** `"Professional carpet and furnishing cleaning with eco-friendly products"`
- **Usage:** Detailed service description on details screen
- **Max Length:** No enforced limit

---

#### `createdAt: DateTime`
- **Source:** Firestore Timestamp field `createdAt`
- **Null Safe:** No (fallback: DateTime.now())
- **Usage:** Service listing date, sorting (recent services)
- **Parsing:**
  ```dart
  DateTime createdAt = DateTime.now();
  if (data['createdAt'] is Timestamp) {
    createdAt = (data['createdAt'] as Timestamp).toDate();
  }
  ```

---

#### `order: int`
- **Source:** Firestore field `order`
- **Null Safe:** No (fallback: 0)
- **Type Handling:** Accepts num, String
- **Example:** `1`, `2`, `3` (for display ordering)
- **Usage:** Sort services by explicit order
- **Parsing:**
  ```dart
  int order = 0;
  final dynamic orderData = data['order'] ?? 0;
  if (orderData is num) {
    order = (orderData.isFinite ? orderData : 0).toInt();
  } else if (orderData is String) {
    order = int.tryParse(orderData) ?? 0;
  }
  ```

---

### Technician Information

#### `technicianId: String?`
- **Source:** Firestore field `technicianId` or inferred from document path
- **Null Safe:** Yes - can be null
- **Example:** `"tech_user_12345"`
- **Usage:** Link service to technician profile
- **Path Inference:** Extracted from path: `technicians/{techId}/services/{serviceId}`
- **Parsing:**
  ```dart
  String? technicianId = data['technicianId']?.toString();
  if (technicianId == null || technicianId.isEmpty) {
    try {
      final pathSegments = doc.reference.path.split('/');
      final techIndex = pathSegments.indexOf('technicians');
      if (techIndex != -1 && techIndex + 1 < pathSegments.length) {
        technicianId = pathSegments[techIndex + 1];
      }
    } catch (_) {}
  }
  ```

---

#### `technicianName: String?`
- **Source:** Firestore field `technicianName`
- **Null Safe:** Yes - can be null
- **Example:** `"Rajesh Kumar"`
- **Usage:** Display technician name on service card
- **Fallback:** Shows no technician name if null

---

#### `technicianDistrict: String?`
- **Source:** Firestore field `technicianDistrict` or `district`
- **Null Safe:** Yes - can be null
- **Example:** `"bangalore"` (lowercase)
- **Usage:** Location-based filtering in recommendations
- **Note:** Used in `streamRecommendedServices()` for geographic matching

---

### Complex Types

#### `subServices: List<SubService>`
- **Source:** Firestore field `subServices`
- **Null Safe:** No (fallback: empty list)
- **Type:** Array of sub-service objects
- **Parsing:**
  ```dart
  List<SubService> subServices = [];
  if (data['subServices'] is List) {
    subServices = (data['subServices'] as List)
        .map((item) => SubService.fromMap(item as Map<String, dynamic>))
        .toList();
  }
  ```
- **SubService Model:** See `lib/core/models/sub_service.dart`

---

## Computed Properties (Getters)

### Derived Aliases

```dart
/// Returns title - backward compatibility
String get name => title;

/// Returns basePrice - backward compatibility
double get price => basePrice;

/// Returns status - alternative naming
bool get isActiveStatus => status;
```

---

## Constructor

### Full Constructor
```dart
HomeService({
  required this.id,
  required this.key,
  required this.title,
  required this.imageAssetPath,
  this.imageUrl = AppConstants.fallbackServiceImage,
  this.description = '',
  required this.basePrice,
  this.originalPrice,
  this.offerPrice,
  this.urgentBookingEnabled = false,
  required this.isActive,
  required this.category,
  required this.categoryName,
  required this.isTopService,
  required this.order,
  this.rating = 4.5,
  this.reviewCount = 0,
  this.isTrending = false,
  this.isRecommended = false,
  this.duration = '1 hour',
  required this.createdAt,
  this.isPublished = true,
  this.status = true,
  this.technicianApproved = true,
  this.technicianId,
  this.technicianName,
  this.technicianDistrict,
  this.subServices = const [],
})
```

---

## Firestore Deserialization

### fromFirestore Method
**Location:** `HomeService.fromFirestore(DocumentSnapshot doc)`  
**Returns:** `HomeService?` (returns null only on catastrophic parse failure)

**Flow:**
1. Extract document ID
2. Mandatory category check with path inference
3. Map Firestore fields with fallbacks
4. Strict image URL validation
5. Safe number parsing (num → double)
6. Technician ID inference from path
7. SubService mapping if present
8. Construct HomeService instance

**Logging:**
- ⚠️ Logs warning if categoryId missing (but doesn't drop service)
- 📊 DEBUG: Prints service ID, category, name on parse
- ❌ Logs errors if sub-services can't be parsed

---

## Serialization

### toMap Method
```dart
Map<String, dynamic> toMap() {
  return {
    'id': key,
    'title': title,
    'imageUrl': imageUrl,
    'basePrice': basePrice,
    'offerPrice': offerPrice,
    'originalPrice': originalPrice,
    // ... all other fields
  };
}
```

---

## Usage Examples

### Display Service Card
```dart
Container(
  child: Column(
    children: [
      // Image with fallback
      Image.network(service.imageUrl, fit: BoxFit.cover),
      
      // Title
      Text(service.title, style: Theme.of(context).textTheme.titleMedium),
      
      // Price display
      Row(
        children: [
          if (service.originalPrice != null)
            Text(
              '₹${service.originalPrice}',
              style: TextStyle(
                decoration: TextDecoration.lineThrough,
                color: Colors.grey,
              ),
            ),
          Text(
            '₹${(service.offerPrice ?? service.basePrice)}',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
      
      // Rating
      Row(
        children: [
          Icon(Icons.star, color: Colors.amber),
          Text('${service.rating} (${service.reviewCount} reviews)'),
        ],
      ),
      
      // Duration
      Text('Duration: ${service.duration}'),
    ],
  ),
)
```

### Filter Services
```dart
// Top-rated services
final topRated = allServices
    .where((s) => s.rating >= 4.0)
    .toList()
  ..sort((a, b) => b.rating.compareTo(a.rating));

// Services with offers
final onSale = allServices
    .where((s) => s.offerPrice != null && 
            s.offerPrice! < s.basePrice)
    .toList();

// Trending services
final trending = allServices
    .where((s) => s.isTrending)
    .toList();

// By category
final cleaning = allServices
    .where((s) => s.category == 'cleaning')
    .toList();
```

### Navigation
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ServiceDetailsScreen(
      serviceId: service.id,
      categoryId: service.category,
      serviceName: service.title,
      serviceData: service,
    ),
  ),
);
```

---

## Null Safety Matrix

| Property | Type | Null? | Fallback | Comments |
|----------|------|-------|----------|----------|
| id | String | No | Never | Firestore doc ID |
| key | String | No | Never | Always has value |
| title | String | No | "Service" | Safe for display |
| imageUrl | String | No | Fallback image | **NEVER NULL** - Safe to use directly |
| basePrice | double | No | 0.0 | Safe for calculations |
| offerPrice | double? | Yes | null | Check before use |
| originalPrice | double? | Yes | null | Check before use |
| category | String | No | Empty string | May be empty if missing |
| categoryName | String | No | "General" | Safe for display |
| rating | double | No | 0.0 | Safe for calculations |
| reviewCount | int | No | 0 | Safe for display |
| isActive | bool | No | true | Default to active |
| status | bool | No | true | Default to active |
| createdAt | DateTime | No | Now | Never null |
| technicianId | String? | Yes | null | May be null |
| technicianName | String? | Yes | null | May be null |
| technicianDistrict | String? | Yes | null | May be null |
| subServices | List | No | Empty list | Never null |

---

## Common Validation Patterns

### Check if Service Has Offer
```dart
final hasOffer = service.offerPrice != null && 
                 service.offerPrice! > 0 && 
                 service.offerPrice! < service.basePrice;
```

### Calculate Discount Percentage
```dart
final discountPercent = hasOffer 
  ? ((service.basePrice - service.offerPrice!) / service.basePrice * 100).round()
  : 0;
```

### Get Display Price
```dart
final displayPrice = service.offerPrice ?? service.basePrice;
```

### Check Rating Validity
```dart
final hasGoodRating = service.rating >= 4.0 && service.reviewCount > 0;
```

### Construct Technician Label
```dart
final techLabel = service.technicianName != null 
  ? 'by ${service.technicianName}'
  : 'Professional Service';
```

---

## Performance Considerations

| Operation | Complexity | Notes |
|-----------|-----------|-------|
| Create from Firestore | O(n) where n = subServices | Parsing is instant for most services |
| Property access | O(1) | All getters are instant |
| Filter by category | O(n) | Linear scan required |
| Sort by rating | O(n log n) | Use for smaller lists |
| Check if favorited | O(1) | When using Set<String> in provider |

---

**End of HomeService Model Reference**
