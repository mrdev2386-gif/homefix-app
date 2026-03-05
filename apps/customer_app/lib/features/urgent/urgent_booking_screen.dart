import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/theme/app_theme.dart';

class UrgentBookingScreen extends StatefulWidget {
  const UrgentBookingScreen({super.key});

  @override
  State<UrgentBookingScreen> createState() => _UrgentBookingScreenState();
}

class _UrgentBookingScreenState extends State<UrgentBookingScreen> {
  String? _userDistrict;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserDistrict();
  }

  Future<void> _loadUserDistrict() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isLoading = false;
          _error = 'User not logged in';
        });
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists || !userDoc.data()!.containsKey('district')) {
        setState(() {
          _isLoading = false;
          _error = 'Please set your district in your profile';
        });
        return;
      }

      setState(() {
        _userDistrict = userDoc.data()!['district'] as String?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Error loading user data: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Urgent Booking',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildTechnicianList();
  }

  Widget _buildTechnicianList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('services')
          .where('urgentBooking.enabled', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: GoogleFonts.outfit(color: Colors.red),
            ),
          );
        }

        final services = snapshot.docs ?? [];
        
        // Filter by district - we need to get technician data to check district
        final filteredServices = <QueryDocumentSnapshot>[];
        
        for (final serviceDoc in services) {
          final serviceData = serviceDoc.data() as Map<String, dynamic>?;
          if (serviceData == null) continue;
          
          // Get parent technician document reference
          final techRef = serviceDoc.reference.parent.parent;
          if (techRef == null) continue;
          
          try {
            final techDoc = await techRef.get();
            final techData = techDoc.data() as Map<String, dynamic>?;
            if (techData == null) continue;
            
            final techDistrict = techData['district'] as String?;
            if (techDistrict != null && techDistrict.toLowerCase() == _userDistrict?.toLowerCase()) {
              filteredServices.add(serviceDoc);
            }
          } catch (e) {
            // Skip this service if we can't get technician data
            continue;
          }
        }

        if (filteredServices.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No urgent booking services available in your district',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current district: ${_userDistrict ?? "Not set"}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 16),
          itemCount: filteredServices.length,
          itemBuilder: (context, index) {
            final serviceDoc = filteredServices[index];
            return _buildServiceCard(serviceDoc);
          },
        );
      },
    );
  }

  Widget _buildServiceCard(QueryDocumentSnapshot serviceDoc) {
    final serviceData = serviceDoc.data() as Map<String, dynamic>;
    final serviceName = serviceData['name'] ?? serviceData['serviceName'] ?? 'Service';
    final categoryName = serviceData['category'] ?? serviceData['categoryName'] ?? 'General';
    final urgentBooking = serviceData['urgentBooking'] as Map<String, dynamic>?;
    final arrivalTime = urgentBooking?['arrivalTime'] ?? 'Quick';
    final urgentFee = urgentBooking?['urgentFee'] as int? ?? 0;

    // Get technician data
    final techRef = serviceDoc.reference.parent.parent;
    
    return FutureBuilder<DocumentSnapshot>(
      future: techRef?.get(),
      builder: (context, techSnapshot) {
        String technicianName = 'Loading...';
        double rating = 4.5;
        String district = '';
        String? technicianId;

        if (techSnapshot.hasData && techSnapshot.data != null) {
          final techData = techSnapshot.data!.data() as Map<String, dynamic>?;
          if (techData != null) {
            technicianName = techData['name'] ?? 'Unknown Technician';
            rating = (techData['rating'] is num) 
                ? (techData['rating'] as num).toDouble() 
                : 4.5;
            district = techData['district'] ?? '';
            technicianId = techSnapshot.data!.id;
          }
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 6,
                color: Colors.black.withValues(alpha: 0.08),
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Technician name
                Text(
                  technicianName,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppTheme.textColor,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Service category
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        categoryName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        serviceName,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Rating and District
                Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                    const SizedBox(width: 4),
                    Text(
                      rating.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.location_on, size: 16, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(
                      district,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Urgent info
                Row(
                  children: [
                    Icon(Icons.flash_on, size: 16, color: Colors.orange),
                    const SizedBox(width: 4),
                    Text(
                      'Arrival: $arrivalTime',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.currency_rupee, size: 14, color: Colors.green),
                    Text(
                      '+$urgentFee urgent fee',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Book Now button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Implement booking logic
                      // This would create a booking with the selected technician and service
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Booking with $technicianName for $serviceName'),
                          backgroundColor: AppTheme.primaryColor,
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Book Now',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
