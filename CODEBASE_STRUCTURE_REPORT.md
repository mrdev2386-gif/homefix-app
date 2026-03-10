# HomeFix Customer App - Codebase Structure Report

Generated: March 9, 2026

---

## 1. HOME SCREEN / DASHBOARD STRUCTURE

### Main Dashboard File
- **File**: [lib/features/dashboard/dashboard_screen.dart](lib/features/dashboard/dashboard_screen.dart)
- **Class**: `DashboardScreen` (StatefulWidget)
- **Key Features**:
  - Custom scroll view with Sliver app bar
  - Premium search bar
  - Quick actions
  - Service sections
  - Upcoming booking widget
  - Bottom navigation integration

### Dashboard Sections Currently Used
Located in [dashboard_screen.dart](lib/features/dashboard/dashboard_screen.dart#L132-L140):
```dart
const TopRatedRealServicesSection(),      // Line 132
const RecommendedServicesSection(),        // Line 140
```

---

## 2. SERVICE CARD WIDGETS - COMPLETE INVENTORY

### Primary Service Card Widgets

#### 1. **PremiumServiceCard** (RECOMMENDED FOR NEW SECTIONS)
- **File**: [lib/features/dashboard/widgets/premium_service_card.dart](lib/features/dashboard/widgets/premium_service_card.dart)
- **Type**: StatefulWidget
- **Features**:
  - Clean modern design with trending badge
  - Star rating display
  - SafeNetworkImage for image handling
  - Navigation to ServiceDetailsScreen on tap
  - Dimensions: Flexible with proper proportions
  - **Note**: No favorite button, no add to cart button

#### 2. **ServiceCard** (FULL FEATURED)
- **File**: [lib/features/dashboard/widgets/service_card.dart](lib/features/dashboard/widgets/service_card.dart)
- **Type**: StatelessWidget
- **Constructor Parameters**:
  ```dart
  ServiceCard({
    required this.service,
    required this.onAddToCart,      // Callback function
    required this.onBookNow,         // Callback function
    this.onTap,                      // Optional override tap
  })
  ```
- **Features**:
  - Premium badge display
  - Trending badge
  - **Favorite button** with animation (`_FavoriteButton`)
  - Price display with rupee symbol
  - Rating and review count
  - **Book Now button** with callback
  - Images via SafeNetworkImage
  - Detailed layout with service name, price, duration, rating
  - RepaintBoundary for performance optimization

#### 3. **ServiceCardGrid** (GRID-ONLY VERSION)
- **File**: [lib/features/dashboard/widgets/service_card_grid.dart](lib/features/dashboard/widgets/service_card_grid.dart)
- **Type**: StatefulWidget
- **Features**:
  - Grid-optimized layout
  - Simple tap navigation to details screen
  - Navigation debouncing (`_isNavigating` flag)

#### 4. **ServiceCardHorizontal** (HORIZONTAL SCROLL VERSION)
- **File**: [lib/features/dashboard/widgets/service_card_horizontal.dart](lib/features/dashboard/widgets/service_card_horizontal.dart)
- **Type**: StatefulWidget
- **Features**:
  - Fixed width: 160dp
  - Right margin: 16dp
  - GestureDetector for tap
  - Horizontal scroll compatible

#### 5. **ProfessionalHomeServiceSection** (DIFFERENT LAYOUT)
- **File**: [lib/features/dashboard/widgets/professional_home_service.dart](lib/features/dashboard/widgets/professional_home_service.dart)
- **Type**: StatefulWidget
- **Input**: `List<HomeService>`
- **Features**:
  - Custom section header with icon
  - Not currently used in dashboard

---

## 3. SERVICE SECTION WIDGETS

### Active Service Sections

#### TopRatedRealServicesSection
- **File**: [lib/features/dashboard/widgets/real_services_sections.dart](lib/features/dashboard/widgets/real_services_sections.dart#L286)
- **Type**: StatelessWidget
- **Stream Source**: `firestoreService.streamTopRatedTechnicianServices(limit: 20)`
- **Layout**:
  - Horizontal GridView with scroll
  - 2 columns, 12sp cross-spacing
  - Child aspect ratio: 0.72
  - Height: 540px
- **Card Widget**: `_PremiumServiceCard`

#### RecommendedServicesSection
- **File**: [lib/features/dashboard/widgets/recommended_services_section.dart](lib/features/dashboard/widgets/recommended_services_section.dart)
- **Type**: StatelessWidget
- **Stream Source**: `CategoryService().getRecommendedServicesResult(limit: limit)`
- **Layout**:
  - Horizontal ListView (not GridView)
  - Height: 200px
  - Right padding on items: 12dp
- **Card Widget**: `_RecommendedServiceCard` (custom, see below)
- **Features**:
  - View All link with optional callback
  - Loading shimmer state
  - Error handling with icon display
  - Empty state handling

#### TopRatedServicesSection
- **File**: [lib/features/dashboard/widgets/top_rated_services_section.dart](lib/features/dashboard/widgets/top_rated_services_section.dart)
- **Type**: StatelessWidget
- **Stream Source**: `CategoryService().getTopRatedServicesResult(limit: limit)`
- **Layout**:
  - Horizontal ListView
  - Height: 200px
- **Card Widget**: `_PremiumRatedCard` (custom)
- **Filter**: rating >= 4.0

### Deprecated/Alternative Section Files

#### real_services_sections_fixed.dart
- **File**: [lib/features/dashboard/widgets/real_services_sections_fixed.dart](lib/features/dashboard/widgets/real_services_sections_fixed.dart)
- **Status**: ⚠️ **DUPLICATE** - Similar structure to real_services_sections.dart
- **Difference**: Minor architectural variations
- **Recommendation**: Use `real_services_sections.dart` with `TopRatedRealServicesSection` class

### Other Service Section Files (Not Currently Used)
- `recent_services_section.dart` - Recently Added Services
- `trending_services_section.dart` - Trending Services
- `popular_services_section.dart` - Popular Services
- `service_spotlight_section.dart` - Service Spotlight
- `cleaning_essentials_section.dart` - Cleaning Essentials

---

## 4. SERVICE MODEL & ENTITY CLASSES

### HomeService Model
- **File**: [lib/core/models/service.dart](lib/core/models/service.dart)
- **Key Properties**:
  ```dart
  // Identification
  final String id;
  final String key;
  final String title;
  final String category;
  final String categoryName;
  
  // Image & Media
  final String imageAssetPath;
  final String imageUrl;
  
  // Pricing
  final double basePrice;
  final double? originalPrice;     // For strikethrough
  final double? offerPrice;        // For offer display
  
  // Status & Flags
  final bool isActive;
  final bool isTopService;
  final bool isTrending;
  final bool isRecommended;
  final bool urgentBookingEnabled;
  final bool technicianApproved;
  final bool isPublished;
  final bool status;               // Derived: true if 'active'
  
  // Metadata
  final double rating;
  final int reviewCount;
  final int order;
  final String duration;
  final DateTime createdAt;
  
  // Technician Info
  final String? technicianId;
  final String? technicianName;
  final String? technicianDistrict;
  
  // Sub-services
  final List<SubService> subServices;
  
  // Aliases for convenience
  String get name => title;
  double get price => basePrice;
  bool get isActiveStatus => status;
  ```

### Firestore Factory Method
```dart
static HomeService? fromFirestore(DocumentSnapshot doc) {
  // Handles mandatory category check
  // Infers categoryId from document path if missing
  // Defensive parsing with fallback values
}
```

---

## 5. CARTPROVIDER & FAVORITESPROVIDER

### CartProvider
- **File**: [lib/core/providers/cart_provider.dart](lib/core/providers/cart_provider.dart)
- **Type**: ChangeNotifier
- **State Management**:
  ```dart
  List<CartItem> _items = [];
  String? _userId;
  StreamSubscription? _cartSubscription;
  bool _isLoading = false;
  Timer? _loadingTimeout;
  ```

#### Public Getters
```dart
List<CartItem> get items => _items;
int get itemCount => _items.length;
bool get isLoading => _isLoading;
double get totalAmount {
  return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
}
```

#### Public Methods
```dart
void updateUserId(String? userId)  // Initializes stream listening
Future<void> addItem(CartItem item)
Future<void> updateQuantity(String itemId, int quantity)
Future<void> removeItem(String itemId)
Future<void> clearCart()
```

### FavoritesProvider
- **File**: [lib/core/providers/favorites_provider.dart](lib/core/providers/favorites_provider.dart)
- **Type**: ChangeNotifier
- **Data Structure**: `Map<String, String>` (serviceId → categoryId)
- **Internal State**:
  ```dart
  Map<String, String> _favoriteServices = {};  // serviceId -> categoryId
  String? _userId;
  StreamSubscription? _favoritesSubscription;
  bool _isLoading = false;
  ```

#### Public Getters
```dart
Set<String> get favoriteIds => _favoriteServices.keys.toSet();
bool isFavorite(String serviceId) => _favoriteServices.containsKey(serviceId);  // O(1)
bool get isLoading => _isLoading;
```

#### Public Methods
```dart
void updateUserId(String? userId)  // Initializes stream listening
Future<void> toggleFavorite(String serviceId, String categoryId)
```

#### Features
- **Optimistic UI Updates**: Immediately updates UI before cloud confirmation
- **Haptic Feedback**: Light impact on toggle
- **Error Recovery**: Reverts changes if cloud function fails
- **Real-time Sync**: Listens to `streamFavoriteIdsWithCategory()`

---

## 6. FIRESTORESERVICE - COMPLETE METHOD REFERENCE

### Cart Stream & Operations
```dart
// Get real-time cart data
Stream<List<CartItem>> streamCart(String userId) {
  // Path: customers/{userId}/cart
  // Auto-cleans invalid items (missing technicianId, serviceId, categoryId)
  // Returns empty list on error (no exception thrown)
}

// Add item to cart via Cloud Function
Future<void> addToCart(String userId, CartItem item) async

// Update item quantity via Cloud Function
Future<void> updateCartItemQuantity(String userId, String itemId, int quantity) async

// Remove single item via Cloud Function
Future<void> removeFromCart(String userId, String itemId) async

// Clear entire cart via Cloud Function
Future<void> clearCart(String userId) async

// Private helper for auto-cleanup
Future<void> _safeDeleteCartItem(String userId, String itemId) async
```

### Favorites Stream & Operations
```dart
// Get favorite service IDs with category mapping
Stream<List<Map<String, String>>> streamFavoriteIdsWithCategory(String userId) {
  // Path: customers/{userId}/favorites/{serviceId}
  // Returns: [{serviceId, categoryId}, ...]
}

// Get full favorite service objects
Stream<List<HomeService>> streamFavoriteServices(String userId) {
  // Async maps favorite IDs to full service documents
  // Queries: categories/{categoryId}/services/{serviceId}
}

// Toggle favorite status via Cloud Function
Future<void> toggleFavorite(
  String userId, 
  String categoryId, 
  String serviceId, 
  bool isFavorite
) async
```

### Service Streams (Dashboard Data)
```dart
// All technician services (no filters)
Stream<List<HomeService>> streamAllTechnicianServices({int limit = 50}) {
  // Query: technician_services where status='approved'
  // Sorted by createdAt descending
}

// Top rated technician services
Stream<List<HomeService>> streamTopRatedTechnicianServices({int limit = 10}) {
  // Query: technician_services where status='approved'
  // Sorted by rating descending
}

// Recently added technician services
Stream<List<HomeService>> streamRecentTechnicianServices({int limit = 10}) {
  // Query: technician_services where status='approved'
  // Sorted by createdAt descending
}

// Recommended services (location-aware)
Stream<List<HomeService>> streamRecommendedServices(
  String userId, 
  {int limit = 10}
) {
  // Filters by user's district if available
  // Queries: technician_services where status='approved'
}
```

### Banner Streams
```dart
Stream<List<BannerModel>> streamBanners()
// Path: home_banners
// Filters: active=true
// Defensive checks for imageUrl presence

Stream<List<ServiceBanner>> streamServiceBottomBanners()
// Path: service_bottom_banners
// Filters: isActive=true
// Defensive checks for missing imageUrl
```

### Address Management
```dart
Stream<List<Address>> streamAddresses(String userId)
// Path: customers/{userId}/addresses
// Sorted by createdAt descending

Stream<Address?> streamPrimaryAddress(String userId)
// Path: customers/{userId}/addresses where isDefault=true, limit 1

Future<void> saveAddress(String userId, Address address)
// Via Cloud Function: manageAddress
// Clears existing defaults if setting new default

Future<Map<String, dynamic>?> getPrimaryAddressFromProfile(String userId)
// Gets primary address from user document
```

### User Profile & Category Data
```dart
Stream<UserModel> streamUserModel(String userId)
Future<Map<String, dynamic>?> getUserData(String userId)
Future<void> updateUserProfile(String userId, Map<String, dynamic> data)

// Categories
Stream<List<TechnicianCategory>> streamTechnicianCategories()
Future<List<TechnicianCategory>> getTechnicianCategories()

// Cleaning Essentials
Stream<List<CleaningEssential>> streamCleaningEssentials()

// Service Spotlight
Stream<List<Map<String, dynamic>>> streamServiceSpotlight()
```

---

## 7. SAFE NETWORK IMAGE WIDGET

### SafeNetworkImage
- **File**: [lib/core/widgets/safe_network_image.dart](lib/core/widgets/safe_network_image.dart)
- **Type**: StatelessWidget
- **Backend**: Uses `CachedNetworkImage` from cached_network_image package

#### Constructor Parameters
```dart
const SafeNetworkImage({
  required String? imageUrl,
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  Widget? placeholder,
  Widget? errorWidget,
  BorderRadius? borderRadius,
  Color? backgroundColor,
  String? serviceName,
  bool usePlaceholder = true,
  String? fallbackUrl,
})
```

#### Features
- URL validation before loading
- Fallback widget on invalid URLs
- LayoutBuilder for responsive dimensions
- NaN/Infinity dimension sanitization
- Caching with max dimensions: 1000x1000
- Fade in/out animations (300ms/100ms)
- Placeholder and error widgets
- BorderRadius support

#### Usage in Service Cards
```dart
SafeNetworkImage(
  imageUrl: widget.service.imageUrl,
  width: double.infinity,
  height: double.infinity,
  fit: BoxFit.cover,
  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
)
```

---

## 8. CURRENT SERVICE SECTION LAYOUT PATTERNS

### Pattern 1: Real Services Sections (TopRatedRealServicesSection)
```dart
// Header with icon gradient + title
// Horizontal GridView with 2 columns
// Card: _PremiumServiceCard
// Height: 540px for 2×3 grid
```

### Pattern 2: Recommended Services Section
```dart
// Header with "View All" link + optional callback
// Horizontal ListView (horizontal scrolling)
// Card: _RecommendedServiceCard (inline card widget)
// Height: 200px
// Loading: Shimmer placeholders
```

### Pattern 3: Generic Service List Section
```dart
// Header with icon + title + "View all" link
// StreamBuilder with fallback states
// Horizontal ListView OR GridView (configurable)
// Placeholder, error, and empty states
```

---

## 9. DUPLICATE & REDUNDANT WIDGETS

### ⚠️ Duplicate Files

| File 1 | File 2 | Status | Recommendation |
|--------|--------|--------|-----------------|
| real_services_sections.dart | real_services_sections_fixed.dart | **DUPLICATE** | Use real_services_sections.dart |
| service_card.dart | premium_service_card.dart | **DIFFERENT** | service_card.dart has favorite button, use for full-featured cards; premium_service_card.dart for simple cards |
| service_card_grid.dart | service_card_horizontal.dart | **VARIANTS** | Grid version vs. horizontal scroll version |

### Unused Service Sections
- `recent_services_section.dart` - Not used in dashboard
- `trending_services_section.dart` - Not used in dashboard
- `popular_services_section.dart` - Not used in dashboard
- `service_spotlight_section.dart` - Not used in dashboard
- `cleaning_essentials_section.dart` - Not used in dashboard
- `service_bottom_banners_section.dart` - Not used in dashboard

### Unused Card Widgets
- `professional_home_service.dart` - Section widget, not currently used
- `service_grid_icon.dart` - Category icon widget
- `premium_service_card.dart` - Used in some sections but not in main dashboard

---

## 10. CARTITEM MODEL

### CartItem Model
- **File**: [lib/core/models/cart_item.dart](lib/core/models/cart_item.dart)

#### Properties
```dart
final String id;
final String categoryId;                    // Mandatory
final String categoryName;                  // Mandatory
final String serviceId;                     // Mandatory
final String? subServiceId;                 // Optional but recommended
final String? subServiceName;               // Optional
final String serviceName;
final String serviceImage;
final double price;
final int quantity;
final double totalPrice;
final String? technicianId;                 // Mandatory for booking
final double finalPriceSnapshot;            // Mandatory - price snapshot
final DateTime? scheduledAt;                // Optional scheduling
```

#### Validation
```dart
bool get isValid => 
  technicianId != null && technicianId!.isNotEmpty &&
  serviceId.isNotEmpty &&
  categoryId.isNotEmpty &&
  categoryName.isNotEmpty &&
  finalPriceSnapshot > 0;
```

#### Firestore Parsing
```dart
factory CartItem.fromFirestore(DocumentSnapshot doc) {
  // Path: customers/{userId}/cart/{itemId}
  // Safe string/double parsing with fallbacks
  // Auto-logs warnings for missing technicianId
}

Map<String, dynamic> toMap() {
  // Converts to Cloud Function payload
}
```

---

## 11. CURRENT ISSUES & STYLING NOTES

### Image Loading Issues
- ✅ Using SafeNetworkImage (proper abstraction)
- ✅ CachedNetworkImage with caching
- ✅ Fallback handling for invalid URLs
- ✅ No raw Image.network calls found

### Service Card Styling
1. **premium_service_card.dart**:
   - Clean, minimal design
   - 4:2 flex ratio (image:details)
   - Trending badge in corner
   - Rating display
   - No action buttons

2. **service_card.dart**:
   - Premium and Trending badges
   - **Favorite button with animation**
   - Price with rupee symbol and duration
   - Rating and review count
   - **Book Now button**
   - 12:11 flex ratio (image:details)
   - RepaintBoundary optimization

3. **Section cards (_PremiumServiceCard in real_services_sections.dart)**:
   - Flex ratio: 4:2
   - Subtle shadows
   - Top badges for status

### Provider Integration
- CartProvider: Accepts callbacks for add/book actions
- FavoritesProvider: Favorite toggle with haptic feedback
- Both implement optimistic UI with error recovery

---

## 12. CRITICAL IMPLEMENTATION DETAILS

### Cloud Function Calls
- **addToCart**: Cloud Function `addToCartCallable`
- **toggleFavorite**: Cloud Function `toggleFavoriteCallable`
- **removeFromCart**: Cloud Function `removeFromCartCallable`
- **updateQuantity**: Cloud Function `updateCartQuantityCallable`
- **clearCart**: Cloud Function `clearCartCallable`
- **manageAddress**: Cloud Function for address operations

### Firestore Path Guards
All setter methods use `FirestoreGuards.isValidDocumentId()` to prevent invalid writes.

### Error Handling
- Cart stream uses StreamTransformer for proper error event handling
- Returns empty list on error instead of throwing
- Optimistic UI updates with rollback on failure
- Haptic feedback on favorites toggle

### Performance Optimizations
1. CartProvider: Loading timeout (15 seconds) to prevent indefinite loading state
2. SafeNetworkImage: Caching with max dimensions (1000x1000)
3. ServiceCard: RepaintBoundary wrapper
4. FavoritesProvider: O(1) lookup with Set<String>

---

## 13. SUMMARY TABLE

| Component | Location | Status | Notes |
|-----------|----------|--------|-------|
| Dashboard | dashboard_screen.dart | ✅ Active | Main entry point |
| TopRatedRealServicesSection | real_services_sections.dart | ✅ Active | Used in dashboard |
| RecommendedServicesSection | recommended_services_section.dart | ✅ Active | Used in dashboard |
| ServiceCard | service_card.dart | ✅ Active | Full-featured card |
| PremiumServiceCard | premium_service_card.dart | ✅ Active | Minimal card |
| CartProvider | cart_provider.dart | ✅ Active | Real-time cart |
| FavoritesProvider | favorites_provider.dart | ✅ Active | Optimistic UI favorites |
| FirestoreService | firestore_service.dart | ✅ Active | All backend calls |
| SafeNetworkImage | safe_network_image.dart | ✅ Active | Image loading |
| HomeService | service.dart | ✅ Active | Service model |
| CartItem | cart_item.dart | ✅ Active | Cart item model |
| real_services_sections_fixed.dart | real_services_sections_fixed.dart | ⚠️ Duplicate | Use real_services_sections.dart instead |

---

## 14. RECOMMENDATIONS FOR NEW SERVICE SECTIONS

### Best Practices
1. **Use `_BaseServicesSection` from `real_services_sections.dart`** as the base for new sections
2. **Use `PremiumServiceCard`** for simple tap-to-details sections
3. **Use `ServiceCard`** when you need favorite or add-to-cart functionality
4. **Use `SafeNetworkImage`** for all network image loading
5. **Implement proper error handling** with fallback states
6. **Add Shimmer loading** during data fetch
7. **Use StreamBuilder** for real-time data with FirestoreService

### Quick Template
```dart
class NewServiceSection extends StatelessWidget {
  const NewServiceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return StreamBuilder<List<HomeService>>(
      stream: firestoreService.streamAllTechnicianServices(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmer();
        }
        if (snapshot.hasError) return _buildError();
        final services = snapshot.data ?? [];
        if (services.isEmpty) return const SizedBox.shrink();
        
        return Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            _buildServicesList(services),
          ],
        );
      },
    );
  }
}
```
