import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/providers/location_provider.dart';
import 'package:customer_app/core/providers/checkout_provider.dart';
import 'package:customer_app/core/models/address.dart';
import 'package:customer_app/core/theme/app_theme.dart';
import 'add_edit_address_screen.dart';

class SavedAddressesScreen extends StatefulWidget {
  final bool isSelectionMode;
  final bool isPrimarySelectionMode;

  const SavedAddressesScreen({
    super.key, 
    this.isSelectionMode = false,
    this.isPrimarySelectionMode = false,
  });

  @override
  State<SavedAddressesScreen> createState() => _SavedAddressesScreenState();
}

class _SavedAddressesScreenState extends State<SavedAddressesScreen> {
  late bool isSelectionMode;
  late bool isPrimarySelectionMode;

  @override
  void initState() {
    super.initState();
    isSelectionMode = widget.isSelectionMode;
    isPrimarySelectionMode = widget.isPrimarySelectionMode;
  }

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
          
          if (snapshot.hasError) {
            debugPrint('[SAVED_ADDRESSES] Stream error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading addresses', style: GoogleFonts.outfit(fontSize: 16)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            debugPrint('[SAVED_ADDRESSES] No addresses found');
            return _buildEmptyState(context);
          }
          
          final addresses = snapshot.data!;
          debugPrint('[SAVED_ADDRESSES] Displaying ${addresses.length} addresses');
          
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final address = addresses[index];
              return _buildAddressCard(context, address, firestoreService, userId, isSelectionMode || isPrimarySelectionMode);
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
            decoration: const BoxDecoration(color: AppTheme.accentColor, shape: BoxShape.circle),
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

  Widget _buildAddressCard(BuildContext context, Address address, FirestoreService service, String userId, bool isSelectionMode) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: () async {
          if (isSelectionMode || isPrimarySelectionMode) {
            // Set as primary address
            await service.setPrimaryAddress(userId, address.id);
            if (context.mounted) {
              Navigator.pop(context, address);
            }
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getAddressColor(address.label).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getAddressIcon(address.label),
                  color: _getAddressColor(address.label),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          address.label,
                          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        if (address.isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PRIMARY',
                              style: GoogleFonts.outfit(
                                color: AppTheme.primaryColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      address.fullAddress,
                      style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[700]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${address.city} • ${address.district} • ${address.pincode}',
                      style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (!address.isDefault)
                          TextButton.icon(
                            onPressed: () async {
                              try {
                                await service.setPrimaryAddress(userId, address.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Primary address updated')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.check_circle_outline, size: 16),
                            label: const Text('Set Primary'),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0)),
                          ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddEditAddressScreen(address: address))),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 16),
                        IconButton(
                          onPressed: () => _confirmDelete(context, address, service, userId),
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.red),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getAddressIcon(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'office':
        return Icons.business;
      default:
        return Icons.location_on;
    }
  }

  Color _getAddressColor(String label) {
    switch (label.toLowerCase()) {
      case 'home':
        return Colors.blue;
      case 'office':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  Widget _buildAddressMenu(BuildContext context, Address address, FirestoreService service, String userId) {
    return const SizedBox.shrink();
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
