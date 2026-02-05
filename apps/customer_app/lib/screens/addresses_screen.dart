import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/models/address.dart';
import '../core/services/auth_service.dart';
import '../core/services/firestore_service.dart';

class AddressesScreen extends StatefulWidget {
  final bool isSelectionMode;
  const AddressesScreen({super.key, this.isSelectionMode = false});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login to manage addresses")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(widget.isSelectionMode ? "Select Address" : "My Addresses"),
      ),
      body: StreamBuilder<List<Address>>(
        stream: firestoreService.streamAddresses(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final addresses = snapshot.data ?? [];
          if (addresses.isEmpty) {
            return _buildEmptyState();
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: addresses.length,
            itemBuilder: (context, index) {
              final addr = addresses[index];
              return _buildAddressCard(addr, user.uid, firestoreService);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddAddressDialog(context, user.uid, firestoreService),
        label: const Text("Add New"),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_off_rounded, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text("No addresses saved", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text("Add an address to book services", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAddressCard(Address addr, String userId, FirestoreService firestoreService) {
    return GestureDetector(
      onTap: () {
        if (widget.isSelectionMode) {
          Navigator.pop(context, addr);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: addr.isDefault ? Colors.blue : Colors.grey.shade200),
          boxShadow: widget.isSelectionMode 
              ? [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          children: [
            Icon(addr.label == "Home" ? Icons.home : Icons.work, 
                 color: addr.isDefault ? Colors.blue : Colors.grey),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(addr.label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      if (addr.isDefault)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: const Text("DEFAULT", style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                  Text(addr.fullAddress, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            if (!widget.isSelectionMode)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                    onPressed: () => _showEditAddressDialog(context, userId, firestoreService, addr),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _confirmDeleteAddress(context, userId, firestoreService, addr),
                  ),
                ],
              ),
            if (widget.isSelectionMode)
              Radio<String>(
                value: addr.id,
                groupValue: null, // Just for UI, selection logic is onTap
                onChanged: (_) => Navigator.pop(context, addr),
              )
          ],
        ),
      ),
    );
  }

  void _showAddAddressDialog(BuildContext context, String userId, FirestoreService service) {
    final titleController = TextEditingController();
    final addressController = TextEditingController();
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "Contact Name")),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(hintText: "Phone Number"), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: titleController, decoration: const InputDecoration(hintText: "Label (e.g. Home, Office)")),
            const SizedBox(height: 12),
            TextField(controller: addressController, decoration: const InputDecoration(hintText: "Full Address with Pincode"), maxLines: 2),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (context, setState) {
              return CheckboxListTile(
                title: const Text("Set as default"),
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v!),
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                   if (addressController.text.isEmpty || titleController.text.isEmpty) return;
                   
                   final addr = Address(
                    id: '', // Firestore will generate
                    label: titleController.text,
                    name: nameController.text,
                    phone: phoneController.text,
                    fullAddress: addressController.text,
                    landmark: '',
                    city: '', // Could parse from address
                    pincode: '',
                    latitude: 0.0,
                    longitude: 0.0,
                    isDefault: isDefault,
                    createdAt: DateTime.now(),
                  );
                  await service.saveAddress(userId, addr);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Save Address"),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, String userId, FirestoreService service, Address address) {
    final titleController = TextEditingController(text: address.label);
    final addressController = TextEditingController(text: address.fullAddress);
    final phoneController = TextEditingController(text: address.phone);
    final nameController = TextEditingController(text: address.name);
    bool isDefault = address.isDefault;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Edit Address", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(hintText: "Contact Name")),
            const SizedBox(height: 12),
            TextField(controller: phoneController, decoration: const InputDecoration(hintText: "Phone Number"), keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            TextField(controller: titleController, decoration: const InputDecoration(hintText: "Label (e.g. Home, Office)")),
            const SizedBox(height: 12),
            TextField(controller: addressController, decoration: const InputDecoration(hintText: "Full Address with Pincode"), maxLines: 2),
            const SizedBox(height: 12),
            StatefulBuilder(builder: (context, setState) {
              return CheckboxListTile(
                title: const Text("Set as default"),
                value: isDefault,
                onChanged: (v) => setState(() => isDefault = v!),
                contentPadding: EdgeInsets.zero,
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                   if (addressController.text.isEmpty || titleController.text.isEmpty) return;
                   
                   final updatedAddr = Address(
                    id: address.id,
                    label: titleController.text,
                    name: nameController.text,
                    phone: phoneController.text,
                    fullAddress: addressController.text,
                    landmark: address.landmark,
                    city: address.city,
                    pincode: address.pincode,
                    latitude: address.latitude,
                    longitude: address.longitude,
                    isDefault: isDefault,
                    createdAt: address.createdAt,
                  );
                  await service.saveAddress(userId, updatedAddr);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text("Update Address"),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAddress(BuildContext context, String userId, FirestoreService service, Address address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Address"),
        content: Text("Are you sure you want to delete '${address.label}'?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await service.deleteAddress(userId, address.id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Address deleted")),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
