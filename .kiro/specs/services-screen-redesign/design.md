# Services Screen Redesign - Design Document

## 1. Architecture Overview

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    ServicesScreen                            │
│                  (StatefulWidget)                            │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │         State Management Layer                      │    │
│  │  - Stream subscriptions (categories, services)      │    │
│  │  - Search state (debounced)                        │    │
│  │  - Loading/Error states                            │    │
│  │  - Navigation guards                               │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │              UI Layer                               │    │
│  │  CustomScrollView                                   │    │
│  │    ├─ StickySearchBar (pinned)                     │    │
│  │    ├─ TopRatedServicesSection                      │    │
│  │    ├─ PopularServicesScroller                      │    │
│  │    ├─ FeaturedOffersCarousel                       │    │
│  │    ├─ RecommendedServicesScroller                  │    │
│  │    ├─ TrendingNearYouSection                       │    │
│  │    ├─ NewServicesSection                           │    │
│  │    └─ AllCategoriesGrid                            │    │
│  └────────────────────────────────────────────────────┘    │
│                                                              │
│  ┌────────────────────────────────────────────────────┐    │
│  │           Data Layer (Read-Only)                    │    │
│  │  CategoryService (Firestore streams)                │    │
│  │    ├─ getActiveCategories()                        │    │
│  │    ├─ getAllServices()                             │    │
│  │    ├─ getTopServices()                             │    │
│  │    ├─ getRecentlyAddedServices()                   │    │
│  │    └─ getTrendingServices()                        │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 Component Hierarchy

```
ServicesScreen
├── SafeArea
└── CustomScrollView
    ├── SliverPersistentHeader (Search Bar - pinned)
    ├── SliverToBoxAdapter (Top Rated Services)
    │   └── TopRatedServicesSection
    │       └── PageView.builder
    │           └── TopRatedServiceCard
    ├── SliverToBoxAdapter (Popular Services)
    │   └── HorizontalServiceScroller (reusable)
    │       └── ListView.builder
    │           └── ServiceCard
    ├── SliverToBoxAdapter (Featured Offers)
    │   └── FeaturedOffersCarousel
    │       ├── PageView.builder
    │       │   └── OfferCard
    │       └── PageIndicator
    ├── SliverToBoxAdapter (Recommended)
    │   └── HorizontalServiceScroller (reused)
    ├── SliverToBoxAdapter (Trending Near You)
    │   └── HorizontalServiceScroller (reused)
    ├── SliverToBoxAdapter (New Services)
    │   └── HorizontalServiceScroller (reused)
    └── SliverGrid (All Categories)
        └── CategoryGridItem
```

## 2. Data Flow Design

### 2.1 Firestore Data Structure (Read-Only)

```
Firestore
├── categories/
│   ├── {categoryId}/
│   │   ├── name: string
│   │   ├── imageUrl: string
│   │   ├── order: number
│   │   ├── isActive: boolean
│   │   ├── serviceCount: number
│   │   └── services/
│   │       └── {serviceId}/
│   │           ├── name: string
│   │           ├── imageUrl: string
│   │           ├── price: number
│   │           ├── rating: number
│   │           ├── reviewCount: number
│   │           ├── isActive: boolean
│   │           ├── isTopService: boolean
│   │           ├── isTrending: boolean
│   │           ├── order: number
│   │           └── createdAt: timestamp
```

### 2.2 Stream Management

```dart
// Primary streams
Stream<List<Category>> _categoriesStream;
Stream<List<HomeService>> _allServicesStream;
Stream<List<HomeService>> _topRatedStream;
Stream<List<HomeService>> _recentServicesStream;
Stream<List<HomeService>> _trendingServicesStream;

// Filtered streams (client-side)
List<HomeService> _searchFilteredServices;
List<HomeService> _topRatedServices; // rating >= 4.0
```

### 2.3 State Management

```dart
class _ServicesScreenState extends State<ServicesScreen> 
    with AutomaticKeepAliveClientMixin {
  
  // Data state
  List<Category> _categories = [];
  List<HomeService> _allServices = [];
  
  // UI state
  bool _isLoading = true;
  String _searchQuery = '';
  ErrorType? _errorType;
  
  // Controllers
  final TextEditingController _searchController;
  final ScrollController _scrollController;
  Timer? _debounceTimer;
  
  // Navigation guards
  bool _isNavigating = false;
  
  @override
  bool get wantKeepAlive => true;
}
```

## 3. Component Specifications

### 3.1 Sticky Search Bar

**Purpose**: Provide persistent search functionality

**Design**:
```dart
SliverPersistentHeader(
  pinned: true,
  delegate: SearchBarDelegate(
    minHeight: 70,
    maxHeight: 70,
  ),
)
```

**UI Specs**:
- Height: 70px (including padding)
- Background: White with shadow
- Border radius: 24px
- Padding: 16px horizontal
- Icon: search_rounded (20px, primary color)
- Placeholder: "Search for services"
- Clear button: Appears when text entered
- Debounce: 400ms

### 3.2 Top Rated Services Section

**Purpose**: Showcase high-quality services

**Data Source**:
```dart
Stream<List<HomeService>> getTopRatedServices() {
  return getAllServices().map((services) => 
    services.where((s) => s.rating >= 4.0)
           .take(5)
           .toList()
  );
}
```

**UI Specs**:
- Section title: "Top Rated Services" (20px, w800)
- Layout: Horizontal PageView
- Card size: 280w x 200h
- Spacing: 16px
- Page indicator: Dots below
- Auto-scroll: Optional (5s interval)

**Card Design**:
```
┌─────────────────────────┐
│   [Service Image]       │ 140h
│                         │
├─────────────────────────┤
│ Service Name            │ 16px, w700
│ ⭐ 4.5 (120 reviews)   │ 14px, w500
│ Starting at ₹299        │ 14px, w600, primary
└─────────────────────────┘
```

### 3.3 Horizontal Service Scroller (Reusable)

**Purpose**: Display services in 2.5 card layout

**Widget Signature**:
```dart
class HorizontalServiceScroller extends StatelessWidget {
  final String title;
  final List<HomeService> services;
  final Function(HomeService) onServiceTap;
  final double cardWidth;
  final double cardHeight;
  
  const HorizontalServiceScroller({
    required this.title,
    required this.services,
    required this.onServiceTap,
    this.cardWidth = 160,
    this.cardHeight = 220,
  });
}
```

**UI Specs**:
- viewportFraction: 0.42 (shows 2.5 cards)
- Card spacing: 12px
- Scroll physics: BouncingScrollPhysics
- Card elevation: 2
- Border radius: 16px

**Card Layout**:
```
┌──────────────┐
│   [Image]    │ 120h
├──────────────┤
│ Service Name │ 14px, w600
│ ₹299         │ 16px, w700, primary
│ 30 mins      │ 12px, w500, grey
└──────────────┘
```

### 3.4 Featured Offers Carousel

**Purpose**: Display promotional banners

**Data Source**:
```dart
Stream<List<BannerModel>> getBanners() {
  return _firestore
    .collection('service_banners')
    .where('isActive', isEqualTo: true)
    .orderBy('order')
    .snapshots();
}
```

**UI Specs**:
- Full width minus 32px padding
- Aspect ratio: 16:9
- Page indicator: Dots (8px diameter)
- Auto-advance: 4 seconds
- Border radius: 20px
- Shadow: elevation 4

### 3.5 All Categories Grid

**Purpose**: Display all service categories

**UI Specs**:
- Grid: 3 columns
- Spacing: 16px
- Aspect ratio: 1.0 (square)
- Card elevation: 1
- Border radius: 16px

**Card Layout**:
```
┌──────────────┐
│              │
│   [Icon]     │ 48px
│              │
│ Category     │ 14px, w600
│ 12 services  │ 12px, w500, grey
└──────────────┘
```

## 4. Loading States

### 4.1 Skeleton Loaders

**Search Bar Skeleton**:
```dart
Container(
  height: 48,
  decoration: BoxDecoration(
    color: Colors.grey[200],
    borderRadius: BorderRadius.circular(24),
  ),
)
```

**Service Card Skeleton**:
```dart
Shimmer.fromColors(
  baseColor: Colors.grey[300],
  highlightColor: Colors.grey[100],
  child: Container(
    width: cardWidth,
    height: cardHeight,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
  ),
)
```

### 4.2 Loading Sequence

1. Show skeleton for search bar
2. Show skeleton for top rated section (3 cards)
3. Show skeleton for horizontal scrollers (3 cards each)
4. Show skeleton for category grid (6 items)
5. Replace with actual data as streams emit

## 5. Empty States

### 5.1 No Categories

```dart
EmptyStateWidget(
  icon: Icons.category_outlined,
  title: 'No Categories Available',
  subtitle: 'Check back later for available services',
  actionButton: 'Retry',
  onAction: _fetchCategories,
)
```

### 5.2 No Services

```dart
EmptyStateWidget(
  icon: Icons.home_repair_service_outlined,
  title: 'No Services Found',
  subtitle: 'Try adjusting your search or filters',
  actionButton: 'Clear Search',
  onAction: _clearSearch,
)
```

### 5.3 Search No Results

```dart
EmptyStateWidget(
  icon: Icons.search_off_rounded,
  title: 'No Results for "$searchQuery"',
  subtitle: 'Try different keywords',
  actionButton: 'Clear Search',
  onAction: _clearSearch,
)
```

## 6. Error States

### 6.1 Network Error

```dart
ErrorStateWidget(
  icon: Icons.wifi_off_rounded,
  title: 'No Internet Connection',
  subtitle: 'Please check your connection and try again',
  actionButton: 'Retry',
  onAction: _retryFetch,
)
```

### 6.2 Permission Error

```dart
ErrorStateWidget(
  icon: Icons.lock_outline_rounded,
  title: 'Access Denied',
  subtitle: 'Unable to load services. Please try again later',
  actionButton: 'Retry',
  onAction: _retryFetch,
)
```

### 6.3 Unknown Error

```dart
ErrorStateWidget(
  icon: Icons.error_outline_rounded,
  title: 'Something Went Wrong',
  subtitle: 'We encountered an error. Please try again',
  actionButton: 'Retry',
  onAction: _retryFetch,
)
```

## 7. Performance Optimizations

### 7.1 Widget Optimization

```dart
// Use const constructors
const SizedBox(height: 16);
const Divider();

// Use SizedBox instead of Container when possible
SizedBox(width: 16, height: 16);

// Cache expensive widgets
final _sectionTitle = Text('Title', style: titleStyle);
```

### 7.2 Image Optimization

```dart
// Use cached_network_image with placeholders
SafeNetworkImage(
  imageUrl: service.imageUrl,
  width: 160,
  height: 120,
  fit: BoxFit.cover,
  placeholder: ShimmerPlaceholder(),
  errorWidget: FallbackImage(),
)
```

### 7.3 Stream Optimization

```dart
// Use StreamBuilder with proper keys
StreamBuilder<List<HomeService>>(
  key: ValueKey('top_rated_services'),
  stream: _topRatedStream,
  builder: (context, snapshot) {
    // Build UI
  },
)

// Dispose streams properly
@override
void dispose() {
  _searchController.dispose();
  _scrollController.dispose();
  _debounceTimer?.cancel();
  super.dispose();
}
```

### 7.4 Scroll Performance

```dart
// Use AutomaticKeepAliveClientMixin
class _ServicesScreenState extends State<ServicesScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
}

// Use efficient scroll physics
CustomScrollView(
  physics: const BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  ),
)
```

## 8. Navigation Flow

### 8.1 Service Card Tap

```dart
Future<void> _handleServiceTap(HomeService service) async {
  // Navigation guard
  if (_isNavigating) return;
  _isNavigating = true;
  
  // Haptic feedback
  HapticFeedback.lightImpact();
  
  try {
    // Check for sub-services
    final hasSubServices = await _categoryService
        .serviceHasSubServices(service.category, service.id);
    
    if (hasSubServices) {
      // Navigate to sub-service screen
      await Navigator.push(context, 
        MaterialPageRoute(builder: (_) => SubServiceScreen(...))
      );
    } else {
      // Navigate to service details
      await Navigator.push(context,
        MaterialPageRoute(builder: (_) => ServiceDetailsScreen(...))
      );
    }
  } finally {
    _isNavigating = false;
  }
}
```

### 8.2 Category Tap

```dart
Future<void> _handleCategoryTap(Category category) async {
  if (_isNavigating) return;
  _isNavigating = true;
  
  HapticFeedback.lightImpact();
  
  try {
    await Navigator.push(context,
      MaterialPageRoute(
        builder: (_) => CategoryServicesScreen(category: category)
      )
    );
  } finally {
    _isNavigating = false;
  }
}
```

## 9. Debug Logging Strategy

### 9.1 Data Fetch Logging

```dart
void _fetchData() async {
  debugPrint('🔍 [ServicesScreen] Starting data fetch...');
  
  try {
    final categories = await _categoryService.getCategoriesOnce();
    debugPrint('✅ [ServicesScreen] Categories loaded: ${categories.length}');
    
    for (var category in categories) {
      debugPrint('   📁 ${category.name} (${category.serviceCount} services)');
    }
    
    final services = await _categoryService.getAllServicesOnce();
    debugPrint('✅ [ServicesScreen] Services loaded: ${services.length}');
    
  } catch (e) {
    debugPrint('❌ [ServicesScreen] Error: $e');
  }
}
```

### 9.2 Stream Logging

```dart
StreamBuilder<List<HomeService>>(
  stream: _servicesStream,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      debugPrint('⏳ [ServicesStream] Waiting for data...');
    }
    
    if (snapshot.hasError) {
      debugPrint('❌ [ServicesStream] Error: ${snapshot.error}');
    }
    
    if (snapshot.hasData) {
      debugPrint('✅ [ServicesStream] Data received: ${snapshot.data!.length} items');
    }
    
    // Build UI
  },
)
```

## 10. Theme Integration

### 10.1 Colors

```dart
// Use existing AppTheme
AppTheme.primaryColor      // #6366F1 (Indigo)
AppTheme.accentColor       // #F3F4F6 (Light Grey)
AppTheme.backgroundColor   // #FAFAFA
AppTheme.textColor         // #1F2937 (Dark Grey)
AppTheme.subtitleColor     // #6B7280 (Medium Grey)
AppTheme.errorColor        // #EF4444 (Red)
```

### 10.2 Typography

```dart
// Use Google Fonts Outfit
GoogleFonts.outfit(
  fontSize: 24,
  fontWeight: FontWeight.w800,  // Headings
  color: AppTheme.textColor,
)

GoogleFonts.outfit(
  fontSize: 16,
  fontWeight: FontWeight.w600,  // Body
  color: AppTheme.textColor,
)

GoogleFonts.outfit(
  fontSize: 14,
  fontWeight: FontWeight.w500,  // Captions
  color: AppTheme.subtitleColor,
)
```

### 10.3 Spacing

```dart
// Consistent spacing scale
const double spacing4 = 4.0;
const double spacing8 = 8.0;
const double spacing12 = 12.0;
const double spacing16 = 16.0;
const double spacing20 = 20.0;
const double spacing24 = 24.0;
const double spacing32 = 32.0;
```

### 10.4 Border Radius

```dart
// Consistent radius scale
const double radius8 = 8.0;
const double radius12 = 12.0;
const double radius16 = 16.0;
const double radius20 = 20.0;
const double radius24 = 24.0;
```

## 11. Accessibility

### 11.1 Semantic Labels

```dart
Semantics(
  label: 'Search for services',
  child: TextField(...),
)

Semantics(
  label: '${service.name}, rated ${service.rating} stars, starting at ${service.price} rupees',
  button: true,
  child: ServiceCard(...),
)
```

### 11.2 Focus Management

```dart
// Ensure proper focus order
FocusTraversalGroup(
  policy: OrderedTraversalPolicy(),
  child: Column(
    children: [
      FocusTraversalOrder(order: NumericFocusOrder(1), child: SearchBar()),
      FocusTraversalOrder(order: NumericFocusOrder(2), child: ServicesList()),
    ],
  ),
)
```

## 12. Testing Strategy

### 12.1 Unit Tests

- CategoryService methods
- Data filtering logic
- Search debounce logic
- Navigation guards

### 12.2 Widget Tests

- ServicesScreen renders correctly
- Search bar functionality
- Empty states display
- Error states display
- Loading states display

### 12.3 Integration Tests

- End-to-end navigation flow
- Firestore data loading
- Search and filter
- Category and service taps

## 13. File Structure

```
lib/features/services/
├── presentation/
│   ├── services_screen.dart (NEW - main screen)
│   ├── category_services_screen.dart (existing)
│   ├── service_details_screen.dart (existing)
│   └── sub_service_screen.dart (existing)
├── widgets/
│   ├── sticky_search_bar.dart (NEW)
│   ├── top_rated_services_section.dart (NEW)
│   ├── horizontal_service_scroller.dart (NEW - reusable)
│   ├── featured_offers_carousel.dart (NEW)
│   ├── category_grid_item.dart (NEW)
│   ├── service_card.dart (NEW)
│   ├── top_rated_service_card.dart (NEW)
│   ├── shimmer_service_card.dart (NEW)
│   ├── empty_state_widget.dart (existing - enhance)
│   └── error_state_widget.dart (existing - enhance)
└── models/ (use existing)
    ├── service.dart
    └── category.dart
```

## 14. Implementation Phases

### Phase 1: Critical Data Fix
1. Add comprehensive debug logging
2. Verify Firestore paths
3. Implement proper error handling
4. Add loading/empty/error states
5. Verify data visibility

### Phase 2: Core UI Foundation
1. Create ServicesScreen scaffold
2. Implement CustomScrollView structure
3. Add sticky search bar
4. Implement skeleton loaders
5. Apply theme and styling

### Phase 3: Modern Sections
1. Top Rated Services section
2. Popular Services scroller
3. Featured Offers carousel
4. Recommended Services section
5. Trending Near You section
6. New Services section
7. All Categories grid

### Phase 4: Performance Hardening
1. Add const constructors
2. Implement AutomaticKeepAliveClientMixin
3. Optimize image caching
4. Reduce unnecessary rebuilds
5. Test scroll performance

### Phase 5: UX Polish
1. Add shimmer loaders
2. Enhance empty states
3. Enhance error states
4. Add haptic feedback
5. Add semantic labels
6. Smooth animations

## 15. Success Criteria

- ✅ All categories visible (100%)
- ✅ All services visible (100%)
- ✅ Search functional with debounce
- ✅ All 8+ sections implemented
- ✅ Smooth 60fps scrolling
- ✅ Loading states work
- ✅ Empty states work
- ✅ Error states work
- ✅ No runtime errors
- ✅ Follows existing theme
- ✅ Reusable components
- ✅ Production-ready code
