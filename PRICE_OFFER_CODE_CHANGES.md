# Price/Offer System - Code Changes Reference

## 📝 Exact Code Changes

### 1. Technician App - Validation (add_service_screen.dart)

**Location**: Line ~700 in `_saveService()` method

**BEFORE**:
```dart
// Strict price validation
if (_offerPrice != null && _originalPrice != null) {
  if (_offerPrice! >= _originalPrice!) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer price must be less than original price'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
}
```

**AFTER**:
```dart
// CRITICAL PRICE VALIDATION
// 1. Both prices are required (not for custom category)
if (_selectedCategoryId != 'custom') {
  if (_originalPrice == null || _originalPrice! <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Original price is required and must be greater than 0'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  if (_offerPrice == null || _offerPrice! <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer price is required and must be greater than 0'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }

  // 2. Offer price MUST be strictly less than original price
  if (_offerPrice! >= _originalPrice!) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Offer price must be strictly less than original price'),
        backgroundColor: Colors.orange,
      ),
    );
    return;
  }
}
```

---

### 2. Technician App - Service Creation (add_service_screen.dart)

**Location**: Line ~850 in `_saveService()` method

**BEFORE**:
```dart
// CREATE new service
await _functionsService.addService(
  name: _nameController.text.trim(),
  price: _offerPrice ?? double.parse(_priceController.text.trim()),
  imageUrl: imageUrl,
  category: _selectedCategoryId!,
  description: _descriptionController.text.trim().isEmpty 
      ? null 
      : _descriptionController.text.trim(),
  originalPrice: _originalPrice,
  offerPrice: _offerPrice,
  discountPercent: _calculateDiscount(),
  // ...
);
```

**AFTER**:
```dart
// CREATE new service
// CRITICAL: Send originalPrice as 'price', offerPrice as 'offerPrice'
print('[SAVE DEBUG] originalPrice: $_originalPrice, offerPrice: $_offerPrice');
await _functionsService.addService(
  name: _nameController.text.trim(),
  price: _originalPrice!,  // Main price (before discount)
  offerPrice: _offerPrice!, // Discounted price
  imageUrl: imageUrl,
  category: _selectedCategoryId!,
  description: _descriptionController.text.trim().isEmpty 
      ? null 
      : _descriptionController.text.trim(),
  // ...
);
```

---

### 3. Technician App - Functions Service (functions_service.dart)

**Location**: `addService()` method

**BEFORE**:
```dart
Future<Map<String, dynamic>> addService({
  required String name,
  required double price,
  required String imageUrl,
  required String category,
  String? description,
  double? originalPrice,
  double? offerPrice,
  double? discountPercent,
  // ...
}) async {
  // ...
  final Map<String, dynamic> data = {
    'name': name,
    'category': category,
    'categoryId': category,
    'price': originalPrice ?? price,
    'offerPrice': offerPrice,
    'imageUrl': imageUrl,
    'description': description ?? 'Professional service...',
  };
  // ...
}
```

**AFTER**:
```dart
Future<Map<String, dynamic>> addService({
  required String name,
  required double price,        // Original price
  required double offerPrice,   // Discounted price
  required String imageUrl,
  required String category,
  String? description,
  // ...
}) async {
  // ...
  final Map<String, dynamic> data = {
    'name': name,
    'category': category,
    'categoryId': category,
    'price': price,           // Original price (before discount)
    'offerPrice': offerPrice, // Discounted price
    'imageUrl': imageUrl,
    'description': description ?? 'Professional service...',
  };
  
  debugPrint('[FunctionsService] addService DATA: $data');
  // ...
}
```

---

### 4. Cloud Functions - Validation (services_management.ts)

**Location**: `addTechnicianService` function

**BEFORE**:
```typescript
const { name, price, basePrice, offerPrice, imageUrl, category, description } = data;

// Validation
if (!sanitizedName || sanitizedName.length < 3) {
  throw new functions.https.HttpsError("invalid-argument", "Service name must be at least 3 characters");
}
if (!price || price <= 0) {
  throw new functions.https.HttpsError("invalid-argument", "Price must be greater than 0");
}
```

**AFTER**:
```typescript
const { name, price, offerPrice, imageUrl, category, description } = data;

// CRITICAL VALIDATION: Price and offerPrice are REQUIRED
if (!sanitizedName || sanitizedName.length < 3) {
  throw new functions.https.HttpsError("invalid-argument", "Service name must be at least 3 characters");
}
if (!price || price <= 0) {
  throw new functions.https.HttpsError("invalid-argument", "Original price is required and must be greater than 0");
}
if (!offerPrice || offerPrice <= 0) {
  throw new functions.https.HttpsError("invalid-argument", "Offer price is required and must be greater than 0");
}
// CRITICAL: offerPrice MUST be strictly less than price
if (offerPrice >= price) {
  throw new functions.https.HttpsError("invalid-argument", "Offer price must be strictly less than original price");
}
```

---

### 5. Cloud Functions - Save Structure (services_management.ts)

**Location**: `addTechnicianService` function

**BEFORE**:
```typescript
const serviceData: any = {
  id: serviceId,
  name: sanitizedName,
  price,
  basePrice: basePrice ?? price,
  offerPrice: offerPrice ?? price,
  // ...
};
```

**AFTER**:
```typescript
// PRICING STRUCTURE:
// - price: Original price (before discount) - used for strikethrough display
// - offerPrice: Discounted price - the actual selling price
// - basePrice: Same as price (for backward compatibility)
const serviceData: any = {
  id: serviceId,
  name: sanitizedName,
  price,              // Original price (before discount)
  offerPrice,         // Discounted price (actual selling price)
  basePrice: price,   // Same as price (for backward compatibility)
  // ...
};

console.log(`[PRICING DEBUG] Service ${serviceId}: price=${price}, offerPrice=${offerPrice}, basePrice=${price}`);
```

---

### 6. Customer App - Model Parsing (service.dart)

**Location**: `fromFirestore()` method

**BEFORE**:
```dart
double price = 0.0;
double? originalPrice;
double? offerPrice;

// Extract price (main/original price)
price = _parsePrice(data['price']);

// Extract offerPrice (discounted price)
offerPrice = _parsePrice(data['offerPrice']);

// Fallback: if price is 0, try basePrice field
if (price == 0.0) {
  price = _parsePrice(data['basePrice']);
}
```

**AFTER**:
```dart
// PRICING STRUCTURE:
// - price: Original price (before discount) - used for strikethrough
// - offerPrice: Discounted price - the actual selling price
// - basePrice: Legacy field, same as price

double price = 0.0;  // Original price (before discount)
double? offerPrice;  // Discounted price (actual selling price)

// Extract price (original price before discount)
price = _parsePrice(data['price']);

// Extract offerPrice (discounted price - actual selling price)
offerPrice = _parsePrice(data['offerPrice']);

// Fallback: if price is 0, try basePrice field (legacy support)
if (price == 0.0) {
  price = _parsePrice(data['basePrice']);
}

// Backward compatibility: If offerPrice is 0 or null, use price as offerPrice
if (offerPrice == null || offerPrice == 0.0) {
  offerPrice = price;
}

// DEBUG: Print parsed values
print('💰 [MODEL PARSE] ${data['name'] ?? 'Unknown'}:');
print('   Firestore price: ${data['price']} → Parsed: $price');
print('   Firestore offerPrice: ${data['offerPrice']} → Parsed: $offerPrice');
print('   Final: price=$price (strikethrough), offerPrice=$offerPrice (display)');
```

---

### 7. Customer App - UI Rendering (service_card.dart)

**Location**: Price display section in `build()` method

**BEFORE**:
```dart
Builder(
  builder: (context) {
    final double price = service.price ?? 0;
    final double offerPrice = service.offerPrice ?? 0;
    
    final bool hasOffer = offerPrice > 0 && offerPrice < price;
    final double finalPrice = hasOffer ? offerPrice : price;
    
    return Row(
      children: [
        Text("₹${finalPrice.toStringAsFixed(0)}", ...),
        if (hasOffer)
          Text("₹${price.toStringAsFixed(0)}", 
            style: TextStyle(decoration: TextDecoration.lineThrough)),
      ],
    );
  },
)
```

**AFTER**:
```dart
// PRICING LOGIC:
// - basePrice/originalPrice: Original price (for strikethrough)
// - offerPrice: Discounted price (actual selling price)
// - Display offerPrice as main price
// - Show basePrice with strikethrough if offerPrice < basePrice
Builder(
  builder: (context) {
    final double originalPrice = service.basePrice ?? 0;
    final double offerPrice = service.offerPrice ?? originalPrice;
    
    // Show offer only if offerPrice is less than originalPrice
    final bool hasOffer = offerPrice > 0 && offerPrice < originalPrice;
    final double displayPrice = offerPrice > 0 ? offerPrice : originalPrice;
    
    print("[UI PRICE] ${service.title}: original=$originalPrice, offer=$offerPrice, display=$displayPrice, hasOffer=$hasOffer");
    
    return Row(
      children: [
        // Main price (offerPrice or originalPrice)
        Text("₹${displayPrice.toStringAsFixed(0)}", 
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
        const SizedBox(width: 8),
        // Strikethrough original price (only if offer exists)
        if (hasOffer)
          Text("₹${originalPrice.toStringAsFixed(0)}", 
            style: TextStyle(fontSize: 13, color: Colors.grey, decoration: TextDecoration.lineThrough)),
      ],
    );
  },
)
```

---

## 🎯 Key Changes Summary

1. ✅ **Validation**: Both prices required, offerPrice < price (client + server)
2. ✅ **Data Flow**: `originalPrice` → `price`, `offerPrice` → `offerPrice`
3. ✅ **Firestore**: Saves `price`, `offerPrice`, `basePrice`
4. ✅ **Model**: Parses correctly with backward compatibility
5. ✅ **UI**: Displays offerPrice as main, price as strikethrough
6. ✅ **Logs**: Debug logs at every step

---

## 📞 Support

Contact: **9508322397**

---

**Status**: ✅ Complete  
**Version**: 1.0
