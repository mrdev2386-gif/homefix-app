import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:customer_app/core/services/firestore_service.dart';
import 'package:customer_app/core/services/auth_service.dart';
import 'package:customer_app/core/models/address.dart';
import 'package:customer_app/core/theme/app_theme.dart';

class AddEditAddressScreen extends StatefulWidget {
  final Address? address;

  const AddEditAddressScreen({super.key, this.address});

  @override
  State<AddEditAddressScreen> createState() => _AddEditAddressScreenState();
}

class _AddEditAddressScreenState extends State<AddEditAddressScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _landmarkController;
  late TextEditingController _cityController;
  late TextEditingController _pincodeController;
  String _label = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.address?.name);
    _phoneController = TextEditingController(text: widget.address?.phone);
    _addressController = TextEditingController(text: widget.address?.fullAddress);
    _landmarkController = TextEditingController(text: widget.address?.landmark);
    _cityController = TextEditingController(text: widget.address?.city);
    _pincodeController = TextEditingController(text: widget.address?.pincode);
    if (widget.address != null) {
      _label = widget.address!.label;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      final address = Address(
        id: widget.address?.id ?? '',
        label: _label,
        name: _nameController.text,
        phone: _phoneController.text,
        fullAddress: _addressController.text,
        landmark: _landmarkController.text,
        city: _cityController.text,
        pincode: _pincodeController.text,
        latitude: widget.address?.latitude ?? 0.0,
        longitude: widget.address?.longitude ?? 0.0,
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
      );

      await firestore.saveAddress(auth.currentUser!.uid, address);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Add New Address' : 'Edit Address',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
        ),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.textColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabelSelector(),
              const SizedBox(height: 32),
              _buildInputField('Receiver Name', _nameController, Icons.person_outline),
              const SizedBox(height: 20),
              _buildInputField('Phone Number', _phoneController, Icons.phone_android_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 20),
              _buildInputField('Full Address', _addressController, Icons.location_on_outlined, maxLines: 3),
              const SizedBox(height: 20),
              _buildInputField('Landmark', _landmarkController, Icons.flag_outlined),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildInputField('City', _cityController, Icons.location_city_outlined)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildInputField('Pincode', _pincodeController, Icons.pin_drop_outlined, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Set as Default Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15)),
                value: _isDefault,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading 
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        widget.address == null ? 'Save Address' : 'Update Address',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('SAVE AS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, color: Colors.grey.shade400, letterSpacing: 1)),
        const SizedBox(height: 16),
        Row(
          children: ['Home', 'Office', 'Other'].map((label) {
            final isSelected = _label == label;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => setState(() => _label = label),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFF8F9FE),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100),
                  ),
                  child: Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: isSelected ? Colors.white : AppTheme.textColor,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, TextEditingController controller, IconData icon, {TextInputType? keyboardType, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey.shade400, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700, fontSize: 15),
          validator: (v) => v!.isEmpty ? 'This field is required' : null,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF8F9FE),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
