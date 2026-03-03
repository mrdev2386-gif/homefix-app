import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Modern Quick Add Service Dialog with Image Support
/// 
/// Features:
/// - Image URL input with preview
/// - Service name input
/// - Price input with validation
/// - Loading state handling
/// - Safe Firebase integration
class QuickAddServiceDialog extends StatefulWidget {
  const QuickAddServiceDialog({super.key});

  @override
  State<QuickAddServiceDialog> createState() =>
      _QuickAddServiceDialogState();
}

class _QuickAddServiceDialogState
    extends State<QuickAddServiceDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _imageUrl;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Quick Add Service',
        style: GoogleFonts.plusJakartaSans(
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🔥 IMAGE PICK
              InkWell(
                onTap: _loading ? null : _pickImage,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 110,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: _imageUrl == null || _imageUrl!.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 32,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add Image URL',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _imageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 32,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Invalid Image URL',
                                  style: TextStyle(
                                    color: Colors.red.shade300,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameCtrl,
                enabled: !_loading,
                decoration: InputDecoration(
                  labelText: 'Service Name',
                  hintText: 'e.g., AC Repair',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter service name';
                  }
                  if (v.trim().length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Price
              TextFormField(
                controller: _priceCtrl,
                enabled: !_loading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price',
                  prefixText: '₹ ',
                  hintText: 'e.g., 500',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Enter price';
                  }
                  final price = double.tryParse(v.trim());
                  if (price == null || price <= 0) {
                    return 'Invalid price';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _loading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _loading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                )
              : const Text('Add'),
        ),
      ],
    );
  }

  // 🔥 IMAGE PICK - URL based version
  Future<void> _pickImage() async {
    final url = await _showImageUrlDialog(context);
    if (url != null && mounted) {
      setState(() => _imageUrl = url);
    }
  }

  // 🔥 IMAGE URL HELPER DIALOG
  Future<String?> _showImageUrlDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: _imageUrl);

    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Paste Image URL'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'https://example.com/image.jpg',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Image is optional for quick add, but validate if provided
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      // Basic URL validation
      if (!_imageUrl!.startsWith('http://') && 
          !_imageUrl!.startsWith('https://')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid URL starting with http:// or https://'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    final price = double.tryParse(_priceCtrl.text.trim());
    if (price == null || price <= 0) return;

    setState(() => _loading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not authenticated');

      await FirebaseFirestore.instance
          .collection('technicians')
          .doc(uid)
          .collection('services')
          .add({
        'name': _nameCtrl.text.trim(),
        'price': price,
        'imageUrl': _imageUrl ?? '',
        'isActive': true,
        'isDeleted': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Service added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
