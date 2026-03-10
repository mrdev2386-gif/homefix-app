# HomeFix Customer App - Widget Quick Reference Guide

**Quick lookup for service cards, sections, and providers**

---

## SERVICE CARD QUICK REFERENCE

### 1. ServiceCard (Multi-Action)
**File:** `lib/features/dashboard/widgets/service_card.dart`  
**Use when:** Need optional add-to-cart and book-now buttons

```dart
ServiceCard(
  service: homeService,
  onAddToCart: () => cartProvider.addItem(...),
  onBookNow: () => navigateToBooking(...),
  onTap: () => navigateToDetails(...),  // Image tap
)
```

---

### 2. PremiumServiceCard (Auto-Navigation)
**File:** `lib/features/dashboard/widgets/premium_service_card.dart`  
**Use when:** Auto-navigate to service details on tap

```dart
PremiumServiceCard(
  service: homeService,
  // onTap is optional; defaults to navigate to ServiceDetailsScreen
)
```

---

### 3. ServiceCardHorizontal (Fixed Width, Horizontal List)
**File:** `lib/features/dashboard/widgets/service_card_horizontal.dart`  
**Dimensions:** 160px width, auto height  
**Use when:** Horizontal ListView with uniform card widths

```dart
ListView.builder(
  scrollDirection: Axis.horizontal,
  itemBuilder: (ctx, idx) => ServiceCardHorizontal(
    service: services[idx],
  ),
)
```

---

### 4. ServiceCardGrid (Aspect Ratio, Grid)
**File:** `lib/features/dashboard/widgets/service_card_grid.dart`  
**Aspect Ratio:** 0.75  
**Use when:** GridView with uniform card sizing

```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.75,
  ),
  itemBuilder: (ctx, idx) => ServiceCardGrid(
    service: services[idx],
  ),
)
```

---

### 5. _PremiumServiceCard (Internal in Sections)
**File:** `lib/features/dashboard/widgets/real_services_sections.dart`  
**Nested:** Private class, used by _BaseServicesSection  
**Dimensions:** 170px (horizontal) | Auto (grid), 280px height

```dart
// Usage within section widgets
_PremiumServiceCard(
  service: service,
  isGrid: false,  // true for grid layout
)
```

---

## SERVICE SECTION QUICK REFERENCE

### Base Section Infrastructure
**File:** `lib/features/dashboard/widgets/real_services_sections.dart`

#### _BaseServicesSection (Reusable template)
```dart
_BaseServicesSection(
  title: 'Section Title',
  titleIcon: Icons.star_rounded,
  iconGradient: [Color(0xFF...),  Color(0xFF...)],
  limit: 10,
  isGrid: false,  // horizontal list
  streamProvider: (fs, limit) => fs.streamSomeServices(limit: limit),
)
```

---

### Individual Section Classes

| Section | File | Stream | Limit | Layout |
|---------|------|--------|-------|--------|
| **AllServicesSection** | real_services_sections.dart | `streamAllTechnicianServices()` | 50 | Horizontal |
| **TopRatedRealServicesSection** | real_services_sections.dart | `streamTopRatedTechnicianServices()` | 20 | Horizontal |
| **RecentlyAddedServicesSection** | real_services_sections.dart | `streamRecentTechnicianServices()` | 10 | Grid |
| **RecommendedServicesSection** | real_services_sections.dart | `streamRecommendedServices(userId)` | 10 | Grid |

---

### Standalone Section Widgets

#### RecommendedServicesSection
**File:** `lib/features/dashboard/widgets/recommended_services_section.dart`  
**Stream:** CategoryService (location-aware)
```dart
RecommendedServicesSection(
  limit: 10,
  showViewAll: true,
  onViewAllTap: () => {...},
)
```

---

#### TopRatedServicesSection
**File:** `lib/features/dashboard/widgets/top_rated_services_section.dart`  
**Stream:** CategoryService
```dart
TopRatedServicesSection(
  limit: 10,
  showViewAll: true,
  onViewAllTap: () => {...},
)
```

---

#### PopularServicesSection
**File:** `lib/features/dashboard/widgets/popular_services_section.dart`  
**Layout:** PageView carousel (2.5 cards visible)
```dart
PopularServicesSection(
  limit: 10,
  title: 'Popular Services',
  showViewAll: true,
  onViewAllTap: () => {...},
)
```

---

#### RecentServicesSection
**File:** `lib/features/dashboard/widgets/recent_services_section.dart`  
**Stream:** CategoryService, sorted by createdAt
```dart
RecentServicesSection(
  limit: 10,
  showViewAll: true,
  onViewAllTap: () => {...},
)
```

---

#### TrendingServicesSection
**File:** `lib/features/dashboard/widgets/trending_services_section.dart`  
**Filter:** isTrending = true
```dart
TrendingServicesSection(
  limit: 10,
  showViewAll: true,
  onViewAllTap: () => {...},
)
```

---

#### ServiceSpotlightSection
**File:** `lib/features/dashboard/widgets/service_spotlight_section.dart`  
**Stream:** `streamServiceSpotlight()`
```dart
ServiceSpotlightSection()  // No parameters
```

---

#### HorizontalServiceSection
**File:** `lib/features/dashboard/widgets/horizontal_service_section.dart`  
**Reusable:** Custom filter function
```dart
HorizontalServiceSection(
  title: 'Cleaning Services',
  serviceFilter: (category) => category == 'cleaning',
  maxItems: 8,
  viewAllCategory: 'cleaning',
)
```

---

#### ProfessionalHomeServiceSection
**File:** `lib/features/dashboard/widgets/professional_home_service.dart`  
**Layout:** Two-column card grid
```dart
ProfessionalHomeServiceSection(
  services: serviceList,
)
```

---

## HOMESERVICE MODEL QUICK REFERENCE

**File:** `lib/core/models/service.dart`

### Creating HomeService from Firestore
```dart
final doc = await _db.collection('technician_services').doc(serviceId).get();
final service = HomeService.fromFirestore(doc);
```

### Accessing Common Properties
```dart
service.title           // String
service.basePrice       // double
service.offerPrice      // double? - null if no offer
service.originalPrice   // double? - for strikethrough
service.imageUrl        // String (never null, has fallback)
service.rating          // double (0.0-5.0)
service.reviewCount     // int
service.isTrending      // bool
service.isRecommended   // bool
service.category        // String (categoryId)
service.technicianName  // String?
service.technicianDistrict  // String?
```

### Computing Discount
```dart
final hasOffer = service.offerPrice != null && 
                 service.offerPrice! > 0 && 
                 service.offerPrice! < service.basePrice;
final discountPercent = hasOffer 
  ? ((service.basePrice - service.offerPrice!) / service.basePrice * 100).round()
  : 0;
```

### Safe Image URL
```dart
// ImageUrl is never null - direct use is safe
Image.network(service.imageUrl)  // Always valid
```

---

## PROVIDER QUICK REFERENCE

### CartProvider
**File:** `lib/core/providers/cart_provider.dart`

#### Getting CartProvider
```dart
final cartProvider = Provider.of<CartProvider>(context);
// or
final cartProvider = context.read<CartProvider>();
```

#### Public Methods
```dart
// Add to cart
await cartProvider.addItem(CartItem(...));

// Update quantity
await cartProvider.updateQuantity(itemId, newQuantity);

// Remove item
await cartProvider.removeItem(itemId);

// Clear all
await cartProvider.clearCart();
```

#### Public Properties
```dart
cartProvider.items           // List<CartItem>
cartProvider.itemCount       // int
cartProvider.totalAmount     // double
cartProvider.isLoading       // bool
```

#### Usage in UI
```dart
Consumer<CartProvider>(
  builder: (ctx, cart, child) {
    return Text('Items: ${cart.itemCount}');
  },
)
```

---

### FavoritesProvider
**File:** `lib/core/providers/favorites_provider.dart`

#### Getting FavoritesProvider
```dart
final favProvider = Provider.of<FavoritesProvider>(context);
// or
final favProvider = context.read<FavoritesProvider>();
```

#### Public Methods
```dart
// Toggle favorite (optimistic UI)
await favProvider.toggleFavorite(serviceId, categoryId);
```

#### Public Properties
```dart
favProvider.favoriteIds  // Set<String> - O(1) lookup
favProvider.isLoading    // bool

// Check if service is favorited
if (favProvider.isFavorite(serviceId)) { ... }
```

#### Usage in UI
```dart
IconButton(
  icon: Icon(
    favProvider.isFavorite(serviceId) 
      ? Icons.favorite 
      : Icons.favorite_border,
  ),
  onPressed: () => favProvider.toggleFavorite(serviceId, categoryId),
)
```

---

## FIRESTORE STREAM METHODS QUICK REFERENCE

**File:** `lib/core/services/firestore_service.dart`

### All Methods at a Glance:

| Method | Returns | Query | Limit |
|--------|---------|-------|-------|
| `streamAllTechnicianServices()` | `Stream<List<HomeService>>` | status='approved' | 50 |
| `streamTopRatedTechnicianServices()` | `Stream<List<HomeService>>` | status='approved', sorted by rating | 10 |
| `streamRecentTechnicianServices()` | `Stream<List<HomeService>>` | status='approved', sorted by createdAt | 10 |
| `streamRecommendedServices(userId)` | `Stream<List<HomeService>>` | status='approved', filtered by user district | 10 |
| `streamFavoriteServices(userId)` | `Stream<List<HomeService>>` | customers/{userId}/favorites | - |
| `streamFavoriteIdsWithCategory(userId)` | `Stream<List<Map<String, String>>>` | favorites with categoryId | - |

### Common Usage Pattern:
```dart
StreamBuilder<List<HomeService>>(
  stream: firestoreService.streamTopRatedTechnicianServices(limit: 20),
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return LoadingShimmer();
    }
    if (snapshot.hasError) {
      return ErrorWidget(error: snapshot.error.toString());
    }
    final services = snapshot.data ?? [];
    if (services.isEmpty) return EmptyWidget();
    
    return ListView.builder(
      itemCount: services.length,
      itemBuilder: (ctx, idx) => ServiceCard(
        service: services[idx],
      ),
    );
  },
)
```

---

## NAVIGATION PATTERNS

### To Service Details
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => ServiceDetailsScreen(
      serviceId: service.id,
      categoryId: service.category,
      serviceName: service.title,
      serviceData: service,  // Full HomeService object
    ),
  ),
);
```

### Using Card Widget onTap
```dart
PremiumServiceCard(
  service: service,
  onTap: () {
    // Custom navigation logic
    Navigator.push(...);
  },
)
```

---

## COMMON PATTERNS

### Adding to Cart from Service Card
```dart
ElevatedButton(
  onPressed: () async {
    final cart = context.read<CartProvider>();
    final cartItem = CartItem(
      id: service.id,
      serviceName: service.title,
      serviceId: service.id,
      price: service.basePrice,
      quantity: 1,
    );
    await cart.addItem(cartItem);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to cart')),
    );
  },
  child: Text('Add to Cart'),
)
```

### Toggling Favorite
```dart
IconButton(
  icon: Consumer<FavoritesProvider>(
    builder: (_, fav, __) => Icon(
      fav.isFavorite(service.id) 
        ? Icons.favorite 
        : Icons.favorite_border,
      color: fav.isFavorite(service.id) ? Colors.red : Colors.grey,
    ),
  ),
  onPressed: () async {
    await context.read<FavoritesProvider>().toggleFavorite(
      service.id,
      service.category,
    );
  },
)
```

### Display Price with Offer
```dart
// Check if offer exists
final hasOffer = service.offerPrice != null && 
                 service.offerPrice! < service.basePrice;

Column(
  children: [
    if (hasOffer)
      Text(
        '₹${service.basePrice.toStringAsFixed(0)}',
        style: TextStyle(
          decoration: TextDecoration.lineThrough,
          color: Colors.grey,
        ),
      ),
    Text(
      '₹${(service.offerPrice ?? service.basePrice).toStringAsFixed(0)}',
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.green,
      ),
    ),
  ],
)
```

---

## DEBUGGING TIPS

### Check Service Image Loading
```dart
// Images that fail to load will show AppConstants.fallbackServiceImage
// homeService.imageUrl is never null
debugPrint('Service image: ${service.imageUrl}');
```

### Monitor Cart Changes
```dart
// From main.dart or any screen
Consumer<CartProvider>(
  builder: (ctx, cart, child) {
    debugPrint('Cart items: ${cart.itemCount}, Total: ₹${cart.totalAmount}');
    return child!;
  },
  child: yourWidget,
)
```

### Check Favorite Status
```dart
// Fast O(1) check
if (context.read<FavoritesProvider>().isFavorite(serviceId)) {
  debugPrint('Service is favorited');
}
```

### Stream Debug Info
```dart
StreamBuilder<List<HomeService>>(
  stream: fs.streamTopRatedTechnicianServices(),
  builder: (ctx, snapshot) {
    if (snapshot.hasData) {
      debugPrint('Services loaded: ${snapshot.data?.length ?? 0}');
    }
    if (snapshot.hasError) {
      debugPrint('Stream error: ${snapshot.error}');
    }
    return ...;
  },
)
```

---

## FILE ORGANIZATION SUMMARY

```
Service Cards:         5 implementations (4 public + 1 private)
Service Sections:      8 distinct section widgets
Models:                1 primary (HomeService)
Providers:             2 (CartProvider, FavoritesProvider)
Stream Methods:        6 primary + helpers
```

**Total Service-Related Widget Files:** 24 in dashboard/widgets/  
**Active Implementations:** 23  
**Duplicates to Remove:** 1 (real_services_sections_fixed.dart)

---

**End of Quick Reference**
