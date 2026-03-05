# Customer Location System - Code Integration Snippets

## 🔧 Copy-Paste Ready Code

### 1. Update main.dart Routes

Add this route to your route definitions:

```dart
'/districtSelection': (context) => const DistrictSelectionScreen(),
```

---

### 2. Update login_screen.dart (Google Sign-In)

Replace the Google Sign-In success handler:

```dart
Future<void> _handleGoogleSignIn() async {
  setState(() => _isLoading = true);
  try {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.signInWithGoogle();
    
    // Navigate to district selection - user MUST select district before proceeding
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DistrictSelectionScreen()),
        (route) => false, // Remove all previous routes
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
```

---

### 3. Update OTP Screen (Phone Sign-In)

After successful OTP verification, navigate to district selection:

```dart
// In OtpScreen, after successful sign-in
if (mounted) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const DistrictSelectionScreen()),
    (route) => false,
  );
}
```

---

### 4. Dashboard Screen - Filter All Services

```dart
import 'package:customer_app/core/services/location_service.dart';

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
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: ShimmerLoader());
              }
              return RecentServicesSection(services: snapshot.data ?? []);
            },
          ),
          
          // Top Rated Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getTopRatedServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: ShimmerLoader());
              }
              return TopRatedSection(services: snapshot.data ?? []);
            },
          ),
          
          // Popular Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getPopularServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: ShimmerLoader());
              }
              return PopularSection(services: snapshot.data ?? []);
            },
          ),
          
          // Trending Services
          StreamBuilder<List<HomeService>>(
            stream: _categoryService.getTrendingServices(
              district: _customerDistrict,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: ShimmerLoader());
              }
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

### 5. Category Services Screen

```dart
import 'package:customer_app/core/services/location_service.dart';

class CategoryServicesScreen extends StatefulWidget {
  final String categoryId;
  final String categoryName;

  const CategoryServicesScreen({
    required this.categoryId,
    required this.categoryName,
  });

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
    _loadDistrict();
  }

  Future<void> _loadDistrict() async {
    final district = await _locationService.getDistrict();
    setState(() => _customerDistrict = district);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.categoryName)),
      body: StreamBuilder<List<HomeService>>(
        stream: _categoryService.getServicesByCategory(
          widget.categoryId,
          district: _customerDistrict,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('No services available in your area'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) => ServiceCard(
              service: services[index],
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/serviceDetails',
                  arguments: services[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

### 6. Service Details Screen

```dart
import 'package:customer_app/core/services/location_service.dart';

class ServiceDetailsScreen extends StatefulWidget {
  final HomeService service;

  const ServiceDetailsScreen({required this.service});

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
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service image
            Image.network(widget.service.imageUrl),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.service.name,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Location info
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          'Available in: $_customerDistrict',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  Text(
                    'Price: ₹${widget.service.price}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/checkout',
                          arguments: widget.service,
                        );
                      },
                      child: const Text('Book Now'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### 7. Checkout Screen

```dart
import 'package:customer_app/core/services/location_service.dart';

class CheckoutScreen extends StatefulWidget {
  final HomeService service;

  const CheckoutScreen({required this.service});

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
    final booking = Booking(
      serviceId: widget.service.id,
      customerId: currentUser.uid,
      state: _customerState,
      district: _customerDistrict,
      date: selectedDate,
      timeSlot: selectedTimeSlot,
      totalPrice: widget.service.price,
    );
    
    await bookingService.createBooking(booking);
    
    if (mounted) {
      Navigator.pushNamed(context, '/bookingConfirmation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Service summary
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Price: ₹${widget.service.price}'),
                      const SizedBox(height: 8),
                      Text('Location: $_customerState, $_customerDistrict'),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Booking button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _createBooking,
                  child: const Text('Confirm Booking'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### 8. Search Results Screen

```dart
import 'package:customer_app/core/services/location_service.dart';

class SearchResultsScreen extends StatefulWidget {
  final String searchQuery;

  const SearchResultsScreen({required this.searchQuery});

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
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
    return Scaffold(
      appBar: AppBar(title: Text('Results for "${widget.searchQuery}"')),
      body: StreamBuilder<List<HomeService>>(
        stream: _categoryService.getAllServices(
          district: _customerDistrict,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allServices = snapshot.data ?? [];
          final filtered = allServices
              .where((s) => s.name
                  .toLowerCase()
                  .contains(widget.searchQuery.toLowerCase()))
              .toList();

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No results for "${widget.searchQuery}"'),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            itemBuilder: (context, index) => ServiceCard(
              service: filtered[index],
              onTap: () {
                Navigator.pushNamed(
                  context,
                  '/serviceDetails',
                  arguments: filtered[index],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
```

---

## 🎯 Integration Pattern

For any screen that displays services, follow this pattern:

```dart
// 1. Import
import 'package:customer_app/core/services/location_service.dart';

// 2. Add to State
final LocationService _locationService = LocationService();
String? _customerDistrict;

// 3. Load in initState
@override
void initState() {
  super.initState();
  _loadDistrict();
}

Future<void> _loadDistrict() async {
  final district = await _locationService.getDistrict();
  setState(() => _customerDistrict = district);
}

// 4. Use in queries
categoryService.getServicesByCategory(
  categoryId,
  district: _customerDistrict,
)
```

---

## ✅ Checklist

- [ ] Copy all code snippets to respective files
- [ ] Update routes in main.dart
- [ ] Update auth flow to navigate to DistrictSelectionScreen
- [ ] Update all dashboard screens with district filtering
- [ ] Test signup flow end-to-end
- [ ] Test service filtering with multiple districts
- [ ] Test location change updates services
- [ ] Deploy Cloud Function for profile updates
- [ ] Verify Firestore indexes for district queries

---

**Ready to integrate!** Copy these snippets into your screens and test thoroughly.
