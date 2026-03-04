# Services Module - Quick Reference

## 🚀 Quick Start

### Add New Service (3 seconds)
```dart
// User taps "Add New Service" button
// Automatically opens AddServiceScreen in create mode
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => AddServiceScreen()),
);
```

### Edit Existing Service
```dart
// User taps edit icon on service card
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => AddServiceScreen(
      service: serviceData,        // Map<String, dynamic>
      serviceId: serviceId,         // String
      isEdit: true,                 // bool
    ),
  ),
);
```

---

## 📋 AddServiceScreen Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `service` | `Map<String, dynamic>?` | No | Existing service data (for edit mode) |
| `serviceId` | `String?` | No | Service document ID (for edit mode) |
| `isEdit` | `bool` | No | Enable edit mode (default: false) |

---

## 🔧 FunctionsService Methods

### Create Service
```dart
await functionsService.addService(
  name: 'AC Repair',
  price: 700.0,
  imageUrl: 'https://...',
  category: 'ac_service',
  description: 'Complete AC repair',
  originalPrice: 1000.0,
  offerPrice: 700.0,
  discountPercent: 30.0,
);
```

### Update Service
```dart
await functionsService.updateService(
  serviceId: 'service_123',
  name: 'AC Repair & Maintenance',
  price: 650.0,
  imageUrl: 'https://...',
  category: 'ac_service',
  description: 'Updated description',
  originalPrice: 1000.0,
  offerPrice: 650.0,
  discountPercent: 35.0,
  isActive: true,
);
```

### Toggle Service Status
```dart
await functionsService.toggleServiceStatus('service_123');
```

### Delete Service
```dart
await functionsService.deleteService('service_123');
```

---

## 📊 Service Data Structure

### Firestore Document
```
technicians/{technicianId}/services/{serviceId}
```

### Fields
```dart
{
  'name': 'AC Repair',
  'price': 700.0,
  'imageUrl': 'https://...',
  'category': 'ac_service',
  'description': 'Complete AC repair',
  'originalPrice': 1000.0,
  'offerPrice': 700.0,
  'discountPercent': 30.0,
  'isActive': true,
  'isDeleted': false,
  'createdAt': Timestamp,
  'updatedAt': Timestamp,
  'averageRating': 4.5,
  'totalReviews': 10,
}
```

---

## 🎨 UI Components

### Service Card Actions
```dart
Column(
  children: [
    // Edit button
    InkWell(
      onTap: _editService,
      child: Icon(Icons.edit_outlined, color: Color(0xFF6366F1)),
    ),
    
    // Toggle active/inactive
    InkWell(
      onTap: _toggleStatus,
      child: Icon(
        isActive ? Icons.toggle_on : Icons.toggle_off,
        color: isActive ? Color(0xFF16A34A) : Colors.grey,
      ),
    ),
    
    // Delete button
    InkWell(
      onTap: _deleteService,
      child: Icon(Icons.delete_outline, color: Colors.red),
    ),
  ],
)
```

---

## ✅ Validation Rules

### Service Name
- **Required**: Yes
- **Min length**: 3 characters
- **Max length**: 60 characters
- **Trim**: Yes
- **Collapse spaces**: Yes

### Prices
- **Original price**: Must be > 0
- **Offer price**: Must be > 0
- **Offer price**: Cannot exceed original price
- **Discount**: Auto-calculated (0-99%)

### Image
- **Required for new**: Yes
- **Required for edit**: No (existing image preserved)
- **Format**: JPEG, PNG
- **Upload**: Automatic with progress

### Category
- **Required**: Yes
- **Source**: Firestore `services` collection
- **Searchable**: Yes

---

## 🔄 State Management

### Loading States
```dart
bool _isSaving = false;        // Save/update in progress
bool _isUploading = false;     // Image upload in progress
double _uploadProgress = 0.0;  // Upload progress (0.0 - 1.0)
```

### Form State
```dart
final _formKey = GlobalKey<FormState>();
final _nameController = TextEditingController();
final _priceController = TextEditingController();
final _originalPriceController = TextEditingController();
final _offerPriceController = TextEditingController();
final _descriptionController = TextEditingController();
```

### Pricing State
```dart
double? _originalPrice;
double? _offerPrice;

double _calculateDiscount() {
  if (_originalPrice == null || _offerPrice == null ||
      _originalPrice! <= 0 || _offerPrice! >= _originalPrice!) {
    return 0;
  }
  final discount = ((_originalPrice! - _offerPrice!) / _originalPrice!) * 100;
  return discount.clamp(0, 99);
}
```

---

## 🐛 Error Handling

### Common Errors
```dart
try {
  await functionsService.updateService(...);
} on FirebaseFunctionsException catch (e) {
  switch (e.code) {
    case 'permission-denied':
      // User not authorized
      break;
    case 'not-found':
      // Service not found
      break;
    case 'invalid-argument':
      // Invalid data provided
      break;
    default:
      // Generic error
  }
} catch (e) {
  // Network or other errors
}
```

### User Feedback
```dart
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(
    content: Text('Service updated successfully'),
    backgroundColor: Colors.green,
  ),
);
```

---

## 🎯 Best Practices

### 1. Always Check Mounted
```dart
if (!mounted) return;
setState(() => _isSaving = false);
```

### 2. Use Safe Parsing
```dart
final price = FirestoreSafeParser.toSafeDouble(data['price']);
final name = FirestoreSafeParser.toSafeString(data['name']);
```

### 3. Prevent Rapid Taps
```dart
DateTime? _lastSaveTap;
static const _saveDebounceMs = 500;

if (_lastSaveTap != null && 
    now.difference(_lastSaveTap!).inMilliseconds < _saveDebounceMs) {
  return;
}
_lastSaveTap = now;
```

### 4. Return Success Status
```dart
Navigator.pop(context, true);  // Return true on success
```

### 5. Refresh After Changes
```dart
await context.read<TechnicianProvider>().refreshTechnicianData();
```

---

## 📱 Navigation Patterns

### Open Add Screen
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Colors.transparent,
  builder: (_) => AddServiceSheet(),
);
```

### Open Edit Screen
```dart
final result = await Navigator.push<bool>(
  context,
  MaterialPageRoute(
    builder: (_) => AddServiceScreen(
      service: widget.service,
      serviceId: widget.serviceId,
      isEdit: true,
    ),
  ),
);

if (result == true) {
  // Refresh handled by StreamBuilder
}
```

---

## 🔍 Debugging

### Enable Debug Logs
```dart
print("[ADD SERVICE] Submit pressed");
print("categoryId=$_selectedCategoryId");
print("serviceId=$_selectedServiceId");
print("isEdit=${widget.isEdit}");
```

### Check Firestore
```
technicians/{uid}/services/{serviceId}
```

### Verify Cloud Function
```
Cloud Functions > Logs > updateTechnicianServiceNew
```

---

## 📚 Related Files

### Core
- `lib/core/services/functions_service.dart` - Cloud Functions wrapper
- `lib/core/models/service.dart` - Service model
- `lib/core/utils/firestore_safe_parser.dart` - Safe parsing utilities
- `lib/core/utils/image_upload_service.dart` - Image upload

### Features
- `lib/features/technician/services/services_screen.dart` - Services list
- `lib/features/technician/services/add_service_screen.dart` - Add/Edit form
- `lib/features/technician/services/widgets/quick_add_service_dialog.dart` - Quick add

### Providers
- `lib/core/providers/technician_provider.dart` - Technician state

---

## 🎓 Examples

### Example 1: Quick Add with Auto-fill
```dart
// User selects "AC Repair" from catalog
// Auto-fills:
_nameController.text = 'AC Repair';
_selectedCategoryId = 'ac_service';
_uploadedImageUrl = 'https://catalog-image.jpg';
_priceController.text = '500';  // Base price from catalog

// User only enters:
_originalPriceController.text = '1000';
_offerPriceController.text = '700';

// Discount auto-calculates: 30% OFF
```

### Example 2: Edit Existing Service
```dart
// User taps edit on "AC Repair" service
// Prefills all fields:
_nameController.text = 'AC Repair';
_originalPriceController.text = '1000';
_offerPriceController.text = '700';
_descriptionController.text = 'Complete AC repair';
_selectedCategoryId = 'ac_service';
_uploadedImageUrl = 'https://existing-image.jpg';

// User modifies offer price:
_offerPriceController.text = '650';

// Discount updates instantly: 35% OFF

// User taps "Update Service"
// Cloud Function updates Firestore
// StreamBuilder refreshes list automatically
```

---

## 🔗 Cloud Functions

### addTechnicianService
```javascript
exports.addTechnicianService = functions.https.onCall(async (data, context) => {
  // Validate authentication
  // Validate data
  // Create service document
  // Return success
});
```

### updateTechnicianServiceNew
```javascript
exports.updateTechnicianServiceNew = functions.https.onCall(async (data, context) => {
  // Validate authentication
  // Validate ownership
  // Update service document
  // Return success
});
```

### toggleTechnicianServiceStatusNew
```javascript
exports.toggleTechnicianServiceStatusNew = functions.https.onCall(async (data, context) => {
  // Validate authentication
  // Toggle isActive field
  // Return new status
});
```

---

**Last Updated**: 2026-01-XX
**Version**: 1.0.0
**Status**: Production Ready
