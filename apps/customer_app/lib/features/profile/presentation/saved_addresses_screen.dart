import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/firestore_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/models/address.dart';
import '../../../core/theme/app_theme.dart';
import 'add_edit_address_screen.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return const Scaffold(body: Center(child: Text('Login required')));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text('Saved Addresses', style: GoogleFonts.outfit(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: StreamBuilder<List<Address>>(
        stream: firestoreService.streamAddresses(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, address, firestoreService, userId);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditAddressScreen())),
        backgroundColor: AppTheme.primaryColor,
        label: Text('ADD NEW ADDRESS', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
            child: const Icon(Icons.location_off_rounded, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 24),
          Text(
            'No Addresses Found',
            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your home or office address to see how fast we deliver!',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, Address address, FirestoreService service, String userId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: InkWell(
        onTap: () {
          Provider.of<LocationProvider>(context, listen: false).setSelectedAddress(address);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: AppTheme.accentColor, borderRadius: BorderRadius.circular(10)),
                        child: Icon(
                          address.label.toLowerCase() == 'home' ? Icons.home_rounded : 
                          address.label.toLowerCase() == 'office' ? Icons.work_rounded : Icons.location_on_rounded,
                          color: AppTheme.primaryColor,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        address.label,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      if (address.isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            'DEFAULT',
                            style: GoogleFonts.outfit(color: Colors.teal, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                  _buildAddressMenu(context, address, service, userId),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                address.name,
                style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 15, color: AppTheme.textColor),
              ),
              const SizedBox(height: 4),
              Text(
                address.fullAddress,
                style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey.shade500, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.phone_outlined, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    address.phone,
                    style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressMenu(BuildContext context, Address address, FirestoreService service, String userId) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade300),
      onSelected: (value) async {
        if (value == 'edit') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address)));
        } else if (value == 'delete') {
          _confirmDelete(context, address, service, userId);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
      ],
    );
  }

  void _confirmDelete(BuildContext context, Address address, FirestoreService service, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure you want to remove this address?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await service.deleteAddress(userId, address.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
