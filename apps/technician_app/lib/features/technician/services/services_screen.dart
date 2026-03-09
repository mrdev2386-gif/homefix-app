import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/app_theme.dart';
import '../../../core/services/functions_service.dart';
import '../../../core/utils/firestore_safe_parser.dart';
import '../../../core/providers/technician_provider.dart';
import 'add_service_screen.dart';
import 'widgets/quick_add_service_dialog.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _functionsService = FunctionsService();

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not authenticated')),
      );
    }

    return Consumer<TechnicianProvider>(
      builder: (context, provider, child) {
        final technician = provider.technician;
        final canCreate = provider.canCreateServices();
        
        return Scaffold(
          backgroundColor: AppTheme.bgLight,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              'My Services',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          body: Column(
            children: [
              if (canCreate) 
                Expanded(child: _ServicesListStream(uid: uid))
              else
                Expanded(child: _buildProfileIncompleteScreen(context, technician)),
              _buildAddServiceButton(context),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProfileIncompleteScreen(BuildContext context, dynamic technician) {
    if (technician == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final profileCompletion = technician.getProfileCompletion();
    final isProfileApproved = technician.status == "approved" || technician.profileApproved;
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_circle_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'Complete Your Profile First',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'You need to complete your profile and get admin approval to start listing services.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: const Color(0xFF6B7280),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Profile Completion',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        '$profileCompletion%',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6366F1),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: profileCompletion / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: profileCompletion < 100 
                          ? Colors.orange.shade50 
                          : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: profileCompletion < 100 
                            ? Colors.orange.shade200 
                            : Colors.blue.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          profileCompletion < 100 ? Icons.info_outline : Icons.schedule,
                          color: profileCompletion < 100 
                              ? Colors.orange.shade700 
                              : Colors.blue.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            profileCompletion < 100 
                                ? 'Profile incomplete' 
                                : 'Waiting for admin approval',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: profileCompletion < 100 
                                  ? Colors.orange.shade700 
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildAddServiceButton(BuildContext context) {
    return Consumer<TechnicianProvider>(
      builder: (context, provider, child) {
        final canCreate = provider.canCreateServices();
        final technician = provider.technician;
        
        if (technician == null) {
          return const SizedBox.shrink();
        }
        
        final profileCompletion = technician.getProfileCompletion();
        final isProfileApproved = technician.status == "approved";
        
        // Show friendly completion screen when profile is incomplete or not approved
        if (profileCompletion < 100 || !isProfileApproved) {
          return _buildProfileIncompleteButton(context, profileCompletion, isProfileApproved);
        }
        
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () => _openAddServiceSheet(context),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Add New Service',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 2,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildProfileIncompleteButton(BuildContext context, int profileCompletion, bool isProfileApproved) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: profileCompletion < 100 ? Colors.orange.shade50 : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: profileCompletion < 100 ? Colors.orange.shade200 : Colors.blue.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    profileCompletion < 100 ? Icons.info_outline : Icons.schedule,
                    color: profileCompletion < 100 ? Colors.orange.shade700 : Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      profileCompletion < 100 
                          ? 'Complete your profile ($profileCompletion%) to list services'
                          : 'Complete profile and wait for admin approval',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: profileCompletion < 100 ? Colors.orange.shade700 : Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (profileCompletion < 100)
              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushNamed('/onboarding');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6366F1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Complete Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _openAddServiceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddServiceSheet(),
    );
  }
}

class _ServicesListStream extends StatelessWidget {
  final String uid;

  const _ServicesListStream({required this.uid});

  @override
  Widget build(BuildContext context) {
    debugPrint('[SERVICES LIST] Querying technician_services for uid: $uid');
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('technician_services')
          .where('technicianId', isEqualTo: uid)
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          debugPrint('[SERVICES LIST ERROR] ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Service index missing. Please create Firestore index.',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.red,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: ${snapshot.error}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        debugPrint('[SERVICES LIST] Connection: ${snapshot.connectionState}');
        debugPrint('[SERVICES LIST] Has data: ${snapshot.hasData}');
        debugPrint('[SERVICES LIST] Doc count: ${snapshot.data?.docs.length ?? 0}');

        final services = snapshot.data?.docs ?? [];

        if (services.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.home_repair_service_outlined,
                      size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Text(
                    'No services added yet',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Tap the button below to add your first service',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: false,
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
          itemCount: services.length,
          itemBuilder: (context, index) {
            final serviceData = FirestoreSafeParser.toSafeMap(services[index].data());
            final serviceId = services[index].id;
            return _ServiceCard(
              serviceId: serviceId,
              service: serviceData,
            );
          },
        );
      },
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String serviceId;
  final Map<String, dynamic> service;

  const _ServiceCard({
    required this.serviceId,
    required this.service,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  final _functionsService = FunctionsService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final isActive = FirestoreSafeParser.toSafeBool(widget.service['isActive'], fallback: true);
    final district = FirestoreSafeParser.toSafeString(widget.service['district'], fallback: 'N/A');
    final rating = FirestoreSafeParser.toSafeDouble(widget.service['averageRating']);
    final reviews = FirestoreSafeParser.toSafeInt(widget.service['totalReviews']);
    
    // DEBUG: Log service status
    final status = widget.service['status'];
    debugPrint('[SERVICE CARD] ID: ${widget.serviceId}');
    debugPrint('[SERVICE CARD] Status: $status');
    debugPrint('[SERVICE CARD] isActive: $isActive');

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildServiceImage(widget.service['imageUrl'] ?? ''),
          const SizedBox(width: 12),
          Expanded(child: _buildServiceInfo(isActive, district, rating, reviews)),
          _buildServiceActions(isActive),
        ],
      ),
    );
  }

  Widget _buildServiceImage(String imageUrl) {
    final safeImageUrl = FirestoreSafeParser.toSafeString(widget.service['imageUrl']);
    if (safeImageUrl.isEmpty) {
      return Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        safeImageUrl,
        width: 72,
        height: 72,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            width: 72,
            height: 72,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceInfo(bool isActive, String district, double rating, int reviews) {
    final price = FirestoreSafeParser.toSafeDouble(widget.service['price']);
    final ratingValue = FirestoreSafeParser.toSafeDouble(widget.service['averageRating']);
    final reviewCount = FirestoreSafeParser.toSafeInt(widget.service['totalReviews']);
    
    // CRITICAL FIX: Check status field, not just isActive
    final status = FirestoreSafeParser.toSafeString(widget.service['status'], fallback: 'pending');
    
    // Determine display status based on actual status field
    String displayStatus;
    Color statusColor;
    Color statusBgColor;
    
    if (status == 'pending') {
      displayStatus = 'Pending Approval';
      statusColor = const Color(0xFFF59E0B); // Orange
      statusBgColor = const Color(0xFFFEF3C7); // Light orange
    } else if (status == 'approved') {
      displayStatus = isActive ? 'Active' : 'Inactive';
      statusColor = isActive ? const Color(0xFF16A34A) : Colors.grey[700]!;
      statusBgColor = isActive ? const Color(0xFFDCFCE7) : Colors.grey[200]!;
    } else if (status == 'rejected') {
      displayStatus = 'Rejected';
      statusColor = const Color(0xFFDC2626); // Red
      statusBgColor = const Color(0xFFFEE2E2); // Light red
    } else {
      displayStatus = 'Unknown';
      statusColor = Colors.grey[700]!;
      statusBgColor = Colors.grey[200]!;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          FirestoreSafeParser.toSafeString(widget.service['name'], fallback: 'Unnamed Service'),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0F172A),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        Text(
          '₹${price.toStringAsFixed(0)}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6366F1),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBgColor,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                displayStatus,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (reviewCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                    const SizedBox(width: 2),
                    Text(
                      ratingValue.toStringAsFixed(1),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
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

  Widget _buildServiceActions(bool isActive) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _editService,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.edit_outlined, color: Color(0xFF6366F1), size: 22),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _toggleStatus,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                isActive ? Icons.toggle_on : Icons.toggle_off,
                color: isActive ? const Color(0xFF16A34A) : Colors.grey,
                size: 28,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoading ? null : _deleteService,
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.delete_outline, color: Colors.red, size: 22),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _toggleStatus() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    try {
      await _functionsService.toggleServiceStatus(widget.serviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service status updated'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _editService() async {
    if (_isLoading) return;
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddServiceScreen(
          service: widget.service,
          serviceId: widget.serviceId,
          isEdit: true,
        ),
      ),
    );
    // Refresh handled by stream
  }

  Future<void> _deleteService() async {
    if (_isLoading) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service'),
        content: const Text('Are you sure you want to delete this service?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _functionsService.deleteService(widget.serviceId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}


// ============ ADD SERVICE BOTTOM SHEET ============

class AddServiceSheet extends StatelessWidget {
  const AddServiceSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Text(
                'Add New Service',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to add your service',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              // Quick Add Option
              _buildOptionCard(
                context: context,
                icon: Icons.flash_on,
                iconColor: const Color(0xFFF59E0B),
                title: 'Quick Add',
                subtitle: 'Add service with basic details',
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 150));
                  if (!context.mounted) return;
                  _showQuickAddDialog(context);
                },
              ),
              const SizedBox(height: 14),
              // Full Form Option
              _buildOptionCard(
                context: context,
                icon: Icons.edit_note,
                iconColor: const Color(0xFF6366F1),
                title: 'Detailed Form',
                subtitle: 'Add service with complete information',
                onTap: () async {
                  // 🔥 SAFE ROOT CONTEXT NAVIGATION - FIXES REDIRECT TO HOME
                  final rootContext = Navigator.of(context, rootNavigator: true).context;
                  
                  Navigator.of(context).pop(); // close sheet
                  
                  await Future.delayed(const Duration(milliseconds: 200));
                  
                  if (!rootContext.mounted) return;
                  
                  Navigator.of(rootContext).push(
                    MaterialPageRoute(
                      builder: (_) => const AddServiceScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => const QuickAddServiceDialog(),
    );
  }
}
