# Customer Location System - Integration Guide

## 🔗 Integration Points

### 1. Dashboard Screens (Service Display)

#### Before (No District Filtering)
```dart
Stream<List<HomeService>> services = categoryService.getServicesByCategory(categoryId);
```

#### After (With District Filtering)
```dart
final locationService = LocationService();
final district = await locationService.getDistrict();
Stream<List<HomeService>> services = categoryService.getServicesByCategory(
  categoryId,
  district: district,
);
```

---

### 2. Category Services Screen

**File**: `apps/customer_app/lib/features/services/presentation/category_services_screen.dart`

```dart
class CategoryServicesScreen extends StatefulWidget {
  @override
  State<CategoryServicesScreen> createState() => _CategoryServicesScreenState();
}

class _CategoryServicesScreenState extends State<CategoryServicesScreen> {
  final LocationService _locationService = LocationService();
  final CategoryService _categoryService = CategoryService();
  String? _customerDistrict;

  @override
  void initState() {
    super.initState();
    _loadCustomerDistrict();
  }

  Future<void> _loadCustomerDistrict() async {
    final district = await _locationService.getDistrict();
    setState(() => _customerDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeService>>(
      stream: _categoryService.getServicesByCategory(
        widget.categoryId,
        district: _customerDistrict,
      ),
      builder: (context, snapshot) {
        // Display services
      },
    );
  }
}
```

---

### 3. Service Details Screen

**File**: `apps/customer_app/lib/features/services/presentation/service_details_screen.dart`

```dart
class ServiceDetailsScreen extends StatefulWidget {
  @override
  State<ServiceDetailsScreen> createState() => _ServiceDetailsScreenState();
}

class _ServiceDetailsScreenState extends State<ServiceDetailsScreen> {
  final LocationService _locationService = LocationService();
  String? _customerDistrict;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await _locationService.getDistrict();
    setState(() => _customerDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Service Details')),
      body: Column(
        children: [
          // Service info
          Text('Available in: $_customerDistrict'),
          // Booking button
        ],
      ),
    );
  }
}
```

---

### 4. Dashboard Screen (Multiple Service Sections)

**File**: `apps/customer_app/lib/features/dashboard/dashboard_screen.dart`

```dart
class DashboardScreen extends StatefulWidget {
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final LocationService _locationService = LocationService();
  final CategoryService _categoryService = CategoryService();
  String? _customerDistrict;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await _locationService.getDistrict();
    setState(() => _customerDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Recently Added Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getRecentlyAddedServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              return RecentServicesSection(services: snapshot.data ?? []);
            },
          ),
          
          // Top Rated Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getTopRatedServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              return TopRatedSection(services: snapshot.data ?? []);
            },
          ),
          
          // Popular Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getPopularServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              return PopularSection(services: snapshot.data ?? []);
            },
          ),
          
          // Trending Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getTrendingServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              return TrendingSection(services: snapshot.data ?? []);
            },
          ),
        ],
      ),
    );
  }
}
```

---

### 5. Technician Selection Screen

**File**: `apps/customer_app/lib/features/services/presentation/technician_selection_screen.dart`

```dart
class TechnicianSelectionScreen extends StatefulWidget {
  final String serviceId;
  final String categoryId;

  const TechnicianSelectionScreen({
    required this.serviceId,
    required this.categoryId,
  });

  @override
  State<TechnicianSelectionScreen> createState() => _TechnicianSelectionScreenState();
}

class _TechnicianSelectionScreenState extends State<TechnicianSelectionScreen> {
  final LocationService _locationService = LocationService();
  final CategoryService _categoryService = CategoryService();
  String? _customerDistrict;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await _locationService.getDistrict();
    setState(() => _customerDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeService>>(
      stream: _categoryService.getSubServices(
        widget.categoryId,
        widget.serviceId,
        district: _customerDistrict,
      ),
      builder: (context, snapshot) {
        // Show available technicians in customer's district
      },
    );
  }
}
```

---

### 6. Search Results Screen

**File**: `apps/customer_app/lib/features/services/presentation/service_list_screen.dart`

```dart
class ServiceListScreen extends StatefulWidget {
  final String searchQuery;

  const ServiceListScreen({required this.searchQuery});

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> {
  final LocationService _locationService = LocationService();
  final CategoryService _categoryService = CategoryService();
  String? _customerDistrict;

  @override
  void initState() {
    super.initState();
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await _locationService.getDistrict();
    setState(() => _customerDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<HomeService>>(
      stream: _categoryService.getAllServices(
        district: _customerDistrict,
      ),
      builder: (context, snapshot) {
        final allServices = snapshot.data ?? [];
        final filtered = allServices
            .where((s) => s.name.toLowerCase().contains(widget.searchQuery.toLowerCase()))
            .toList();
        
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) => ServiceCard(service: filtered[index]),
        );
      },
    );
  }
}
```

---

### 7. Booking Flow Integration

**File**: `apps/customer_app/lib/features/cart/presentation/checkout_screen.dart`

```dart
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;

  const CheckoutScreen({required this.items});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final LocationService _locationService = LocationService();
  String? _customerState;
  String? _customerDistrict;

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  Future<void> _loadLocation() async {
    final location = await _locationService.getLocation();
    setState(() {
      _customerState = location['state'];
      _customerDistrict = location['district'];
    });
  }

  Future<void> _createBooking() async {
    // Create booking with location info
    final booking = Booking(
      serviceId: widget.items.first.serviceId,
      customerId: currentUser.uid,
      state: _customerState,
      district: _customerDistrict,
      // ... other fields
    );
    
    await bookingService.createBooking(booking);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Column(
        children: [
          Text('Booking for: $_customerState, $_customerDistrict'),
          // Checkout form
          ElevatedButton(
            onPressed: _createBooking,
            child: const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🔄 Update Pattern

For any screen that displays services:

1. **Import LocationService**
   ```dart
   import 'package:customer_app/core/services/location_service.dart';
   ```

2. **Load District in initState**
   ```dart
   Future<void> _loadDistrict() async {
     final district = await _locationService.getDistrict();
     setState(() => _customerDistrict = district);
   }
   ```

3. **Pass to Service Queries**
   ```dart
   categoryService.getServicesByCategory(
     categoryId,
     district: _customerDistrict,
   )
   ```

---

## 📋 Screens to Update

| Screen | File | Status |
|--------|------|--------|
| Dashboard | `dashboard_screen.dart` | ⏳ TODO |
| Category Services | `category_services_screen.dart` | ⏳ TODO |
| Service Details | `service_details_screen.dart` | ⏳ TODO |
| Technician Selection | `technician_selection_screen.dart` | ⏳ TODO |
| Service List | `service_list_screen.dart` | ⏳ TODO |
| Checkout | `checkout_screen.dart` | ⏳ TODO |
| Search Results | `search_results_screen.dart` | ⏳ TODO |

---

## ✅ Integration Checklist

- [ ] Import LocationService in all service-displaying screens
- [ ] Load customer district in initState
- [ ] Pass district parameter to all service queries
- [ ] Test with multiple districts
- [ ] Verify services filter correctly
- [ ] Test location change updates services
- [ ] Verify empty state when no services in district

---

## 🚀 Deployment Steps

1. **Update all screens** with district filtering
2. **Test signup flow** end-to-end
3. **Test service filtering** with multiple districts
4. **Deploy Cloud Function** for profile updates
5. **Monitor Firestore** for customer location data
6. **Verify Firestore indexes** for district queries
7. **Release to production**

---

## 📊 Expected Behavior

### Before Integration
- Services show from all districts
- No location selection during signup
- No location persistence

### After Integration
- Services show only from customer's district
- Location mandatory during signup
- Location persists across sessions
- Customer can change location anytime
- Services refresh when location changes
