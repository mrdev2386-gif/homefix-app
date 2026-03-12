# 🎯 CATEGORY SERVICES SCREEN - QUICK REFERENCE

## 📍 File Location
```
apps/customer_app/lib/features/services/presentation/category_services_screen.dart
```

## 🔑 KEY COMPONENTS

### 1. Gradient Header (Lines 180-220)
```dart
SliverAppBar(
  expandedHeight: 180,
  pinned: true,
  flexibleSpace: FlexibleSpaceBar(
    background: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.9),
            AppTheme.secondaryColor.withOpacity(0.8),
          ],
        ),
      ),
    ),
  ),
)
```

### 2. Search Bar (Lines 222-240)
```dart
TextField(
  onChanged: (value) {
    setState(() => _searchQuery = value);
    _applyFilters();
  },
  decoration: InputDecoration(
    hintText: 'Search services...',
    prefixIcon: const Icon(Icons.search_rounded),
  ),
)
```

### 3. Filter Chips (Lines 242-280)
```dart
_FilterChip(
  label: 'Top Rated',
  isSelected: _selectedFilter == 'toprated',
  onTap: () {
    setState(() => _selectedFilter = 'toprated');
    _applyFilters();
  },
)
```

### 4. 2-Column Grid (Lines 290-310)
```dart
SliverGrid(
  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    childAspectRatio: 0.72,
    crossAxisSpacing: 12,
    mainAxisSpacing: 12,
  ),
)
```

### 5. Service Card (Lines 380-480)
```dart
class _ServiceGridCard extends StatelessWidget {
  // Image with overlay gradient
  // Rating badge
  // Price display
  // Favorite button
  // Discount badge
}
```

## 🎨 COLOR SYSTEM

| Color | Value | Usage |
|-------|-------|-------|
| Primary | #6366F1 | Header gradient, filters, price |
| Secondary | #8B5CF6 | Header gradient |
| Background | #FBFBFE | Screen background |
| Text | #0F172A | Titles, labels |
| Subtitle | #64748B | Descriptions, hints |
| Error | #EF4444 | Discount badge |

## 🔄 FILTER LOGIC (Lines 85-110)

```dart
void _applyFilters() {
  List<HomeService> filtered = List.from(_services);

  // Search filter
  if (_searchQuery.isNotEmpty) {
    filtered = filtered
        .where((s) => s.title.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  // Sort filter
  switch (_selectedFilter) {
    case 'toprated':
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
      break;
    case 'lowestprice':
      filtered.sort((a, b) => a.basePrice.compareTo(b.basePrice));
      break;
    case 'fastest':
      filtered.sort((a, b) => (a.estimatedTime ?? 0).compareTo(b.estimatedTime ?? 0));
      break;
    case 'recent':
      filtered.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      break;
    default:
      break;
  }

  setState(() => _filteredServices = filtered);
}
```

## 📦 STATE VARIABLES

```dart
String _selectedFilter = 'all';        // Current filter
String _searchQuery = '';              // Search text
List<HomeService> _services = [];      // All services
List<HomeService> _filteredServices = []; // Filtered services
bool _isLoading = true;                // Loading state
```

## 🎯 FILTER OPTIONS

| Filter | Sort By | Order |
|--------|---------|-------|
| All | - | Default |
| Top Rated | rating | Descending |
| Lowest Price | basePrice | Ascending |
| Fastest | estimatedTime | Ascending |
| Recently Added | createdAt | Descending |

## 📱 RESPONSIVE DESIGN

- **Grid**: 2 columns on all screen sizes
- **Aspect Ratio**: 0.72 (optimal for cards)
- **Spacing**: 12px between cards
- **Padding**: 16px horizontal
- **Header Height**: 180px (expandable)

## 🎬 ANIMATIONS

- Filter chip selection: 200ms ease-in-out
- Container transitions: Smooth color/shadow changes
- Shimmer loading: Animated skeleton loaders
- Scroll behavior: Header pins when scrolling

## 🔧 CUSTOMIZATION

### Change Header Gradient
```dart
gradient: LinearGradient(
  colors: [
    AppTheme.primaryColor.withOpacity(0.9),
    AppTheme.secondaryColor.withOpacity(0.8),
  ],
)
```

### Change Grid Columns
```dart
crossAxisCount: 2,  // Change to 3 for 3-column layout
childAspectRatio: 0.72,  // Adjust card height
```

### Add More Filters
```dart
case 'newfilter':
  filtered.sort((a, b) => /* your sort logic */);
  break;
```

## ⚡ PERFORMANCE TIPS

1. **Limit Services**: `.take(20)` enforces max 20 services
2. **Cache Images**: CachedNetworkImage handles caching
3. **Efficient Filtering**: Uses `.where()` and `.sort()`
4. **Stream Cleanup**: `_servicesSubscription?.cancel()` in dispose
5. **Local State**: Filters managed locally, no extra Firestore queries

## 🐛 TROUBLESHOOTING

### Services not showing
- Check Firestore query in `_fetchServices()`
- Verify category ID is correct
- Check network connectivity

### Filters not working
- Verify `_applyFilters()` is called after state change
- Check filter case names match exactly
- Ensure services have required fields (rating, basePrice, etc.)

### Images not loading
- Check image URLs are valid
- Verify CachedNetworkImage is properly configured
- Check network permissions

### Overflow errors
- Grid aspect ratio is set to 0.72 (prevents overflow)
- Text has maxLines and overflow: ellipsis
- No mainAxisSize: MainAxisSize.min constraints

## 📊 FIRESTORE QUERY

```dart
_categoryService.getServicesByCategoryResult(widget.category.id)
  // Returns services for this category
  // Limited to 20 services
  // Filtered by category ID
```

## 🎨 CARD STRUCTURE

```
┌─────────────────────┐
│   Image (3/5)       │
│  [Gradient Overlay] │
│  [Favorite Button]  │
│  [Discount Badge]   │
├─────────────────────┤
│ Title (2 lines)     │
│ ⭐ 4.6 (45)         │
│                     │
│ ₹299 ₹399           │
└─────────────────────┘
```

## 🚀 DEPLOYMENT CHECKLIST

- [x] Gradient header implemented
- [x] Search functionality working
- [x] Filter system complete
- [x] 2-column grid layout
- [x] Service cards redesigned
- [x] Color system applied
- [x] Loading state implemented
- [x] Empty state implemented
- [x] Performance optimized
- [x] No overflow errors
- [x] Responsive on all screens
- [x] No duplicate files

---

**Status**: ✅ PRODUCTION READY
**Last Updated**: 2024

