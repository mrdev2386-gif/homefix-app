import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/app_theme.dart';
import '../../../core/services/functions_service.dart';
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
          Expanded(child: _ServicesListStream(uid: uid)),
          _buildAddServiceButton(context),
        ],
      ),
    );
  }

  Widget _buildAddServiceButton(BuildContext context) {
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
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .collection('services')
          .where('isDeleted', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .limit(100)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text('Something went wrong'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

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
            final service = services[index].data() as Map<String, dynamic>;
            final serviceId = services[index].id;
            return _ServiceCard(
              serviceId: serviceId,
              service: service,
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
    final isActive = widget.service['isActive'] ?? true;
    final district = widget.service['district'] ?? 'N/A';
    final rating = widget.service['averageRating'] ?? 0.0;
    final reviews = widget.service['totalReviews'] ?? 0;

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
    if (imageUrl.isEmpty) {
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
        imageUrl,
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
    final price = (widget.service['price'] as num?)?.toDouble() ?? 0.0;
    final ratingValue = (widget.service['averageRating'] as num?)?.toDouble() ?? 0.0;
    final reviewCount = (widget.service['totalReviews'] as num?)?.toInt() ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.service['name'] ?? 'Unnamed Service',
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
                color: isActive ? const Color(0xFFDCFCE7) : Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: isActive ? const Color(0xFF16A34A) : Colors.grey[700],
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
