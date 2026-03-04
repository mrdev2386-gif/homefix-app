# 3-LEVEL SERVICE SELECTION IMPLEMENTATION GUIDE
## Category → Service → SubService Flow

**Status:** ✅ Data Layer Complete | 🔄 UI Layer Pending

---

## ✅ COMPLETED: Data Layer

### 1. SubServiceData Model Added
**File:** `apps/technician_app/lib/core/services/category_data_service.dart`

```dart
class SubServiceData {
  final String id;
  final String name;
  final double? price;
  final String? description;
  final String? imageUrl;
  final bool isActive;
  final int? order;
}
```

### 2. SubService Fetching Method Added
```dart
Future<List<SubServiceData>> getSubServicesByService(String serviceId) async {
  // Fetches from: services/{serviceId}/subServices
  // Filters: isActive == true
  // Orders by: order
}
```

---

## 🔄 REQUIRED: UI Layer Updates

### File to Update:
`apps/technician_app/lib/features/technician/services/add_service_screen.dart`

### Changes Needed:

#### 1. Add State Variables (after line 48)
```dart
// SubService state
String? _selectedSubServiceId;
String? _selectedSubServiceName;
double? _selectedSubServicePrice;
List<SubServiceData> _subServices = [];
bool _isLoadingSubServices = false;
String? _subServiceError;
```

#### 2. Add SubService Loading Method (after _loadServices method)
```dart
Future<void> _loadSubServices(String? serviceId) async {
  if (serviceId == null) {
    setState(() {
      _subServices = [];
      _isLoadingSubServices = false;
      _selectedSubServiceId = null;
      _selectedSubServiceName = null;
      _selectedSubServicePrice = null;
    });
    return;
  }
  
  setState(() {
    _isLoadingSubServices = true;
    _subServiceError = null;
    _selectedSubServiceId = null;
    _selectedSubServiceName = null;
    _selectedSubServicePrice = null;
  });
  
  try {
    final subServices = await _categoryDataService.getSubServicesByService(serviceId);
    
    if (mounted) {
      setState(() {
        _subServices = subServices;
        _isLoadingSubServices = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        _subServiceError = 'Failed to load subservices';
        _isLoadingSubServices = false;
      });
    }
  }
}
```

#### 3. Update _buildServicesDropdown onChanged (around line 1100)
```dart
onChanged: (item) {
  if (item != null) {
    setState(() {
      _selectedServiceId = item.id;
      _selectedServiceName = item.label;
      if (_nameController.text.isEmpty) {
        _nameController.text = item.label;
      }
    });
    
    // Auto-fill price if available
    final serviceIndex = _services.indexWhere((s) => s.id == item.id);
    if (serviceIndex >= 0 && _services[serviceIndex].basePrice != null) {
      _priceController.text = _services[serviceIndex].basePrice!.toStringAsFixed(0);
    }
    
    // NEW: Load subservices when service selected
    _loadSubServices(item.id);
  }
},
```

#### 4. Add SubService Dropdown Widget (after _buildServicesDropdown, around line 1150)
```dart
Widget _buildSubServicesDropdown() {
  if (_selectedServiceId == null || _selectedServiceId == 'custom') {
    return const SizedBox.shrink();
  }

  final dropdownItems = _subServices.map((subService) => DropdownItem(
    id: subService.id,
    label: subService.name,
    subtitle: subService.price != null ? '₹${subService.price!.toStringAsFixed(0)}' : null,
  )).toList();

  DropdownItem? selectedItem;
  if (_selectedSubServiceId != null) {
    final index = _subServices.indexWhere((s) => s.id == _selectedSubServiceId);
    if (index >= 0) {
      selectedItem = DropdownItem(
        id: _subServices[index].id,
        label: _subServices[index].name,
        subtitle: _subServices[index].price != null ? '₹${_subServices[index].price!.toStringAsFixed(0)}' : null,
      );
    }
  }

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SearchableDropdown<DropdownItem>(
        items: dropdownItems,
        selectedItem: selectedItem,
        hint: 'Select subservice',
        searchHint: 'Search subservices...',
        isLoading: _isLoadingSubServices,
        enabled: !_isLoadingSubServices && _subServices.isNotEmpty,
        onChanged: (item) {
          if (item != null) {
            setState(() {
              _selectedSubServiceId = item.id;
              _selectedSubServiceName = item.label;
              
              // Auto-fill price from subservice
              final subServiceIndex = _subServices.indexWhere((s) => s.id == item.id);
              if (subServiceIndex >= 0) {
                final subService = _subServices[subServiceIndex];
                if (subService.price != null) {
                  _selectedSubServicePrice = subService.price;
                  _offerPrice = subService.price;
                  _priceController.text = subService.price!.toStringAsFixed(0);
                }
              }
            });
          }
        },
        selectedColor: AppTheme.primaryColor,
      ),
      if (_subServiceError != null) ...[\n        const SizedBox(height: 8),
        Row(
          children: [
            Flexible(
              fit: FlexFit.loose,
              child: Text(
                _subServiceError!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.red,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: () => _loadSubServices(_selectedServiceId),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
      ],
      if (_isLoadingSubServices)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 8),
              Text(
                'Loading subservices...',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      if (!_isLoadingSubServices && _subServices.isEmpty && _selectedServiceId != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'No subservices available for this service',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ),
    ],
  );
}
```

#### 5. Add SubService Section to build() method (after Services dropdown, around line 850)
```dart
// SubServices Dropdown (when service selected)
if (_selectedServiceId != null && _selectedServiceId != 'custom') ...[\n  _buildSectionTitle('SubService'),
  const SizedBox(height: 12),
  _buildSubServicesDropdown(),
  const SizedBox(height: 16),
],
```

#### 6. Update _saveService Validation (around line 600)
```dart
// Validate subservice (if subservices exist for selected service)
if (_selectedServiceId != null && 
    _selectedServiceId != 'custom' && 
    _subServices.isNotEmpty && 
    _selectedSubServiceId == null) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Please select a subservice'),
      backgroundColor: Colors.orange,
    ),
  );
  return;
}
```

#### 7. Update FunctionsService.addService() call (around line 700)
```dart
await _functionsService.addService(
  name: _nameController.text.trim(),
  price: double.parse(_priceController.text.trim()),
  imageUrl: imageUrl,
  category: _selectedCategoryId!,
  serviceId: _selectedServiceId,  // NEW
  subServiceId: _selectedSubServiceId,  // NEW
  description: _descriptionController.text.trim().isEmpty 
      ? null 
      : _descriptionController.text.trim(),
  originalPrice: _originalPrice,
  offerPrice: _offerPrice,
  discountPercent: _calculateDiscount(),
);
```

---

## 📊 DATA FLOW

```
1. User selects Category
   ↓
2. System loads Services from: collection('services').where('categoryId', '==', categoryId)
   ↓
3. User selects Service
   ↓
4. System loads SubServices from: collection('services/{serviceId}/subServices')
   ↓
5. User selects SubService
   ↓
6. System auto-fills price from SubService
   ↓
7. User submits with all 3 IDs: categoryId, serviceId, subServiceId
```

---

## ✅ VALIDATION RULES

Before submit, ensure:
- ✅ categoryId not null
- ✅ serviceId not null (if not custom)
- ✅ subServiceId not null (if subservices exist for selected service)
- ✅ price > 0
- ✅ image selected (if not custom)

---

## 🎨 UI IMPROVEMENTS

### Step-based Layout
```
┌─────────────────────────────────┐
│ STEP 1: Select Category         │
│ [Dropdown with search]           │
└─────────────────────────────────┘
         ↓ (fade transition)
┌─────────────────────────────────┐
│ STEP 2: Select Service           │
│ [Dropdown with search]           │
│ [Loading indicator if fetching]  │
└─────────────────────────────────┘
         ↓ (fade transition)
┌─────────────────────────────────┐
│ STEP 3: Select SubService        │
│ [Dropdown with search + price]   │
│ [Loading indicator if fetching]  │
└─────────────────────────────────┘
```

### Features:
- ✅ Searchable dropdowns
- ✅ Loading indicators
- ✅ Empty state messages
- ✅ Disabled state until previous selected
- ✅ Auto-fill price from subservice
- ✅ Smooth transitions
- ✅ Error handling with retry

---

## 🔒 SAFETY CHECKS

- ✅ No hardcoded data
- ✅ No duplicate collections
- ✅ No Firestore structure changes
- ✅ Backward compatible with existing technician_services
- ✅ Proper error handling
- ✅ Loading states
- ✅ Validation before submit

---

## 📝 BACKEND PAYLOAD

```json
{
  "categoryId": "ac_repair",
  "serviceId": "ac_service",
  "subServiceId": "ac_gas_refill",
  "serviceName": "AC Gas Refill",
  "subServiceName": "R32 Gas Refill",
  "price": 2500,
  "originalPrice": 3000,
  "offerPrice": 2500,
  "discountPercent": 16.67
}
```

---

## 🚀 DEPLOYMENT STEPS

1. ✅ Update `category_data_service.dart` (DONE)
2. 🔄 Update `add_service_screen.dart` (PENDING - use guide above)
3. 🔄 Update `functions_service.dart` to accept serviceId & subServiceId
4. 🔄 Test Category → Service → SubService flow
5. 🔄 Deploy to production

---

**Status:** Data layer ready. UI implementation pending.
**Estimated Time:** 1-2 hours for UI updates
**Risk Level:** Low (backward compatible)
