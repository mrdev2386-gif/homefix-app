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
  late TextEditingController _districtController;
  late TextEditingController _stateController;
  late TextEditingController _pincodeController;
  late TextEditingController _field1Controller; // House/Floor/Location
  late TextEditingController _field2Controller; // Area/Building/Address
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
    _districtController = TextEditingController(text: widget.address?.district);
    _stateController = TextEditingController(text: widget.address?.state);
    _pincodeController = TextEditingController(text: widget.address?.pincode);
    _field1Controller = TextEditingController();
    _field2Controller = TextEditingController();
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
    _districtController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _field1Controller.dispose();
    _field2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final firestore = Provider.of<FirestoreService>(context, listen: false);

      // Construct full address based on label type
      String fullAddress = _addressController.text;
      if (_label.toLowerCase() == 'home') {
        final parts = [
          _field1Controller.text, // House/Flat No
          _field2Controller.text, // Area/Street
        ].where((e) => e.isNotEmpty);
        fullAddress = parts.join(', ');
      } else if (_label.toLowerCase() == 'office') {
        final parts = [
          _field2Controller.text, // Floor/Unit
          _addressController.text, // Building Name
        ].where((e) => e.isNotEmpty);
        fullAddress = parts.join(', ');
      }
      
      if (fullAddress.isEmpty) {
        fullAddress = _addressController.text;
      }

      final address = Address(
        id: widget.address?.id ?? '',
        label: _label,
        name: _nameController.text,
        phone: _phoneController.text,
        fullAddress: fullAddress,
        landmark: _landmarkController.text,
        city: _cityController.text,
        district: _districtController.text,
        state: _stateController.text,
        pincode: _pincodeController.text,
        latitude: widget.address?.latitude ?? 0.0,
        longitude: widget.address?.longitude ?? 0.0,
        isDefault: _isDefault,
        createdAt: widget.address?.createdAt ?? DateTime.now(),
      );

      debugPrint('[ADD_EDIT_ADDRESS] Saving address: ${address.displayAddress}');
      await firestore.saveAddress(auth.currentUser!.uid, address);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.address == null ? 'Address saved successfully' : 'Address updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('[ADD_EDIT_ADDRESS] Error saving address: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.address == null ? 'Add New Address' : 'Edit Address',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              ..._buildDynamicFields(),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Set as Primary Address', style: GoogleFonts.outfit(fontWeight: FontWeight.w600)),
                value: _isDefault,
                activeColor: AppTheme.primaryColor,
                onChanged: (val) => setState(() => _isDefault = val),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(widget.address == null ? 'Save Address' : 'Update Address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Address Type', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(
          children: ['Home', 'Office', 'Other'].map((label) {
            final isSelected = _label == label;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _label = label);
                  },
                  selectedColor: AppTheme.primaryColor,
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.black,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  List<Widget> _buildDynamicFields() {
    switch (_label.toLowerCase()) {
      case 'home':
        return [
          _buildField('Full Name', _nameController, Icons.person_outline),
          _buildField('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildField('House / Flat No', _field1Controller, Icons.home_outlined),
          _buildField('Area / Street', _field2Controller, Icons.location_city),
          _buildField('Landmark (Optional)', _landmarkController, Icons.flag_outlined, required: false),
          _buildField('City', _cityController, Icons.location_city_outlined),
          _buildField('District', _districtController, Icons.map_outlined),
          _buildField('State', _stateController, Icons.public_outlined),
          _buildField('Pincode', _pincodeController, Icons.pin_drop_outlined, keyboardType: TextInputType.number),
        ];
      case 'office':
        return [
          _buildField('Office Name', _nameController, Icons.business_outlined),
          _buildField('Contact Person', _field1Controller, Icons.person_outline),
          _buildField('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildField('Floor / Unit Number', _field2Controller, Icons.stairs_outlined),
          _buildField('Building Name', _addressController, Icons.apartment_outlined),
          _buildField('Area / Street', _landmarkController, Icons.location_city),
          _buildField('City', _cityController, Icons.location_city_outlined),
          _buildField('District', _districtController, Icons.map_outlined),
          _buildField('State', _stateController, Icons.public_outlined),
          _buildField('Pincode', _pincodeController, Icons.pin_drop_outlined, keyboardType: TextInputType.number),
        ];
      default: // Other
        return [
          _buildField('Location Name', _nameController, Icons.location_on_outlined),
          _buildField('Contact Name', _field1Controller, Icons.person_outline),
          _buildField('Phone', _phoneController, Icons.phone, keyboardType: TextInputType.phone),
          _buildField('Address Line', _addressController, Icons.home_outlined, maxLines: 2),
          _buildField('Landmark', _landmarkController, Icons.flag_outlined),
          _buildField('City', _cityController, Icons.location_city_outlined),
          _buildField('District', _districtController, Icons.map_outlined),
          _buildField('State', _stateController, Icons.public_outlined),
          _buildField('Pincode', _pincodeController, Icons.pin_drop_outlined, keyboardType: TextInputType.number),
        ];
    }
  }

  Widget _buildField(String label, TextEditingController controller, IconData icon,
      {TextInputType? keyboardType, int maxLines = 1, bool required = true}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, size: 20),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.white,
        ),
        validator: required ? (v) => v!.isEmpty ? 'Required' : null : null,
      ),
    );
  }
}
