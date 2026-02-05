import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/services/auth_service.dart';

class HelpRequestForm extends StatefulWidget {
  const HelpRequestForm({super.key});

  @override
  State<HelpRequestForm> createState() => _HelpRequestFormState();
}

class _HelpRequestFormState extends State<HelpRequestForm> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  String _selectedCategory = 'General';
  bool _isSubmitting = false;

  final List<String> _categories = [
    'General',
    'Booking Issue',
    'Payment Issue',
    'Technician Issue',
    'App Issue',
    'Other',
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Describe your issue',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Category Dropdown
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Category',
                labelStyle: GoogleFonts.outfit(),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, style: GoogleFonts.outfit()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value!;
                });
              },
            ),
            const SizedBox(height: 16),

            // Subject Field
            TextFormField(
              controller: _subjectController,
              decoration: InputDecoration(
                labelText: 'Subject',
                labelStyle: GoogleFonts.outfit(),
                hintText: 'Brief description of your issue',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a subject';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Message Field
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Message',
                labelStyle: GoogleFonts.outfit(),
                hintText: 'Describe your issue in detail...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.all(16),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please describe your issue';
                }
                if (value.length < 10) {
                  return 'Please provide more details (at least 10 characters)';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Submit Request',
                        style: GoogleFonts.outfit(
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
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      // TODO: Submit to Firestore or Cloud Function
      // For now, just show success message
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Request submitted successfully! We\'ll get back to you soon.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Clear form
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _selectedCategory = 'General';
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting request: $e', style: GoogleFonts.outfit()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }
}
