import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/services/functions_service.dart';
import '../../../core/providers/location_provider.dart';
import '../../profile/presentation/saved_addresses_screen.dart';

class ServiceRequestScreen extends StatefulWidget {
  const ServiceRequestScreen({super.key});

  @override
  State<ServiceRequestScreen> createState() => _ServiceRequestScreenState();
}

class _ServiceRequestScreenState extends State<ServiceRequestScreen> {
  final _descriptionController = TextEditingController();
  final _serviceNameController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  bool _isLoading = false;

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF6366F1)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _submitRequest() async {
    if (_descriptionController.text.isEmpty || _serviceNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final locationProvider = Provider.of<LocationProvider>(context, listen: false);
    if (locationProvider.selectedAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a service location')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final functionsService = Provider.of<FunctionsService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;

      if (user == null) throw 'User not logged in';

      final combinedDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      await functionsService.createServiceRequest({
        'title': _serviceNameController.text,
        'description': _descriptionController.text,
        'preferredDateTime': combinedDateTime.toIso8601String(),
        'address': locationProvider.selectedAddress?.toMap(),
      });

      if (mounted) {
        HapticFeedback.heavyImpact();
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: ${e.toString().split(']').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Request Submitted!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Technicians nearby will now be able to send you quotes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Great!', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Custom Service Request', style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Describe your requirement',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Get custom quotes from verified professionals.',
              style: TextStyle(color: Colors.grey[500], fontSize: 15),
            ),
            const SizedBox(height: 32),
            _buildTextField(
              controller: _serviceNameController,
              label: 'What do you need?',
              hint: 'e.g. Garden Landscaping, Table Repair',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _descriptionController,
              label: 'Detailed Description',
              hint: 'Describe the issue or service you need in detail...',
              icon: Icons.description_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            const Text('Preferred Schedule', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildPickerTile(
                  icon: Icons.calendar_today_outlined,
                  label: DateFormat('MMM d, yyyy').format(_selectedDate),
                  onTap: _selectDate,
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildPickerTile(
                  icon: Icons.access_time,
                  label: _selectedTime.format(context),
                  onTap: _selectTime,
                )),
              ],
            ),
            const SizedBox(height: 32),
            _buildLocationSection(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Post Request',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
            prefixIcon: Icon(icon, color: const Color(0xFF6366F1), size: 20),
            filled: true,
            fillColor: const Color(0xFFF8F9FE),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPickerTile({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FE),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF6366F1)),
            const SizedBox(width: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    final locationProvider = Provider.of<LocationProvider>(context);
    final address = locationProvider.selectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: address == null ? Colors.orange.shade200 : Colors.transparent),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Color(0xFF6366F1)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      address?.label ?? 'No Location Selected',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      address?.fullAddress ?? 'Please select where you need the service.',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedAddressesScreen())),
                child: Text(address == null ? 'Select' : 'Change'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
