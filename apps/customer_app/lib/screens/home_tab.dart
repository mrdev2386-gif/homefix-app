import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../core/providers/category_provider.dart';
import '../core/providers/auth_provider.dart';
import '../features/dashboard/widgets/dashboard_app_bar.dart';
import '../features/dashboard/widgets/dashboard_search_bar.dart';
import '../features/dashboard/widgets/category_card.dart';
import '../features/dashboard/widgets/service_card.dart';
import '../core/providers/service_provider.dart';
import '../core/providers/cart_provider.dart';
import '../core/providers/booking_provider.dart';
import '../core/models/service.dart';
import '../core/services/location_service.dart';
import '../features/dashboard/widgets/banner_slider.dart';
import '../screens/request_service_screen.dart';
import '../features/booking/presentation/slot_selection_screen.dart';
import '../screens/addresses_screen.dart';
import '../core/models/address.dart';
import '../features/dashboard/widgets/professional_reels_section.dart';
import '../features/dashboard/widgets/cleaning_essentials_section.dart';
import '../features/dashboard/widgets/service_spotlight_section.dart';
import '../core/services/firestore_service.dart';


class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(context),
      body: _buildDashboardContent(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final customer = authProvider.customer;
    
    // Get default address or first from list or use default text
    String address = customer?.defaultAddress ?? 'Add your address';
    String city = 'Select City';

    if (customer?.addresses.isNotEmpty == true) {
      final firstAddress = customer!.addresses.first;
      if (customer.defaultAddress == null) {
        address = firstAddress['fullAddress'] ?? 'Add your address';
      }
      city = firstAddress['city'] ?? 'Select City';
    }

    return DashboardAppBar(
      city: city,
      address: address,
      onLocationTap: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Select Location',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: Icon(Icons.my_location, color: Colors.white),
                ),
                title: const Text('Use Current Location'),
                subtitle: const Text('Enable GPS to detect location'),
                onTap: () async {
                  Navigator.pop(context);
                  final position = await LocationService.getCurrentPosition();
                  if (position != null) {
                    final details = await LocationService.getCityAndAddressFromLatLng(position);
                    if (details != null && customer != null) {
                      await authProvider.updateDefaultAddress(details['fullAddress']!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location updated successfully')),
                        );
                      }
                    }
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not fetch location. Please enable permissions.')),
                      );
                    }
                  }
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.location_on_outlined, color: Colors.grey[800]),
                ),
                title: const Text('Select Saved Address'),
                subtitle: const Text('Choose from your address book'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddressesScreen(isSelectionMode: true),
                    ),
                  );
                  
                  if (result != null && result is Address) {
                    if (customer != null) {
                      await authProvider.updateDefaultAddress(result.fullAddress);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Location updated')),
                        );
                      }
                    }
                  }
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
      onCartTap: () {
        // Navigate to cart
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart - Coming soon')),
        );
      },
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Expert Care for All Your Devices',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
                letterSpacing: -0.5,
              ),
            ),
          ),
          
          // Search Bar
          Consumer<CategoryProvider>(
            builder: (context, categoryProvider, child) {
              return DashboardSearchBar(
                onChanged: (query) {
                  categoryProvider.setSearchQuery(query);
                  Provider.of<ServiceProvider>(context, listen: false).setSearchQuery(query);
                },
                onClear: () {
                  categoryProvider.clearSearch();
                  Provider.of<ServiceProvider>(context, listen: false).setSearchQuery('');
                },
                currentQuery: categoryProvider.searchQuery,
              );
            },
          ),

          // Banner Slider
          const SizedBox(height: 16),
          const BannerSlider(),
          
          // Professional Reels Section
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.streamProfessionalReels(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return ProfessionalReelsSection(
                reels: snapshot.data!,
                onTechnicianTap: (technicianId) {
                  // TODO: Navigate to technician profile
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening technician profile: $technicianId')),
                  );
                },
              );
            },
          ),
          
          // Cleaning Essentials Section
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.streamCleaningEssentials(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return CleaningEssentialsSection(
                essentials: snapshot.data!,
                onEssentialTap: (categoryId) {
                  // Navigate to category services
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening category: $categoryId')),
                  );
                },
              );
            },
          ),
          
          // In the Spotlight Section
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.streamServiceSpotlight(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              return ServiceSpotlightSection(
                spotlightServices: snapshot.data!,
                onServiceTap: (service) {
                  _showServiceDetailBottomSheet(context, service);
                },
              );
            },
          ),
          
          // Professional Services Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Professional Services',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildServicesGrid(context),

          // Request Service CTA
          _buildRequestServiceCTA(context),

          // Categories Section
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 24, 16, 12),
            child: Text(
              'Browse Categories',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildCategoriesGrid(context),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildServicesGrid(BuildContext context) {
    return Consumer3<ServiceProvider, CartProvider, BookingProvider>(
      builder: (context, serviceProvider, cartProvider, bookingProvider, child) {
        if (serviceProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final services = serviceProvider.services.take(12).toList();

        if (services.isEmpty) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('No services available'),
          ));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.75,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final service = services[index];
            return ServiceCard(
              service: service,
              onAddToCart: () {
                cartProvider.addItem(service);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${service.title} added to cart')),
                );
              },
              onBookNow: () {
                // Navigate to slot selection
                _navigateToSlotSelection(context, service);
              },
            );
          },
        );
      },
    );
  }

  Widget _buildRequestServiceCTA(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Can't find a service?",
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Request a custom service",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showRequestServiceDialog(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Request'),
          ),
        ],
      ),
    );
  }

  void _showRequestServiceDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RequestServiceScreen()),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context) {
    return Consumer<CategoryProvider>(
      builder: (context, categoryProvider, child) {
        if (categoryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        final categories = categoryProvider.categories;

        if (categories.isEmpty) {
          return const Center(child: Text('No categories available'));
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              category: category,
              onTap: () {
                _navigateToCategoryDetails(context, category.id, category.title);
              },
            );
          },
        );
      },
    );
  }

  void _navigateToCategoryDetails(BuildContext context, String categoryId, String categoryTitle) {
    // Navigate to category details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Opening $categoryTitle...')),
    );
    
    // TODO: Implement navigation
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (context) => CategoryDetailsScreen(categoryId: categoryId),
    //   ),
    // );
  }

  void _navigateToSlotSelection(BuildContext context, HomeService service) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SlotSelectionScreen(service: service),
      ),
    );
  }

  void _showServiceDetailBottomSheet(BuildContext context, Map<String, dynamic> service) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Service image
                if (service['imageUrl'] != null && (service['imageUrl'] as String).isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      service['imageUrl'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 200,
                        color: Colors.grey[200],
                        child: const Icon(Icons.home_repair_service, size: 60),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                
                // Service title
                Text(
                  service['title'] ?? 'Service',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Rating and price row
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      (service['rating'] ?? 0.0).toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '₹${(service['price'] ?? 0.0).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6366F1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Available technicians
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.people, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${service['availableTechnicians'] ?? 0} technicians available',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Description (if available)
                if (service['description'] != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        service['description'],
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                
                // Book now button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking feature - Coming soon')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Book Now',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
