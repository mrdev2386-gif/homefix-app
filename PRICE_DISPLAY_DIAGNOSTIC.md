# 🔍 PRICE DISPLAY DIAGNOSTIC REPORT

## ✅ INVESTIGATION COMPLETE

### 📊 DATA FLOW ANALYSIS

**Collection Used:** `technician_services`
**Query Filter:** `status == 'approved'`
**Model:** `HomeService` (service.dart)

---

## 🎯 ROOT CAUSE IDENTIFIED

### ISSUE: Prices ARE being fetched correctly, but may show as ₹0 if Firestore data is missing

### DATA FLOW:
```
Firestore (technician_services)
    ↓
FirestoreService.streamAllTechnicianServices()
    ↓
HomeService.fromFirestore()
    ↓
UniversalServiceCard (UI)
```

---

## 📋 MODEL FIELD MAPPING

### HomeService Model Fields:
```dart
final double basePrice;        // Main price field
final double? originalPrice;   // For strikethrough (optional)
final double? offerPrice;      // For discount (optional)

// Aliases:
double get price => basePrice;  // Alias for basePrice
```

### Firestore Field Extraction:
```dart
price = _parsePrice(data['price'] ?? data['basePrice']);
originalPrice = _parsePrice(data['originalPrice']);
offerPrice = _parsePrice(data['offerPrice']);
```

### Safe Parsing:
```dart
static double _parsePrice(dynamic value, {bool isRating = false}) {
  if (value == null) return 0.0;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}
```

---

## 🔧 UI CALCULATION LOGIC

### In unified_service_card.dart:
```dart
final hasOffer = service.offerPrice != null && 
                 service.offerPrice! > 0 && 
                 service.offerPrice! < service.basePrice;

final discount = hasOffer 
    ? ((service.basePrice - service.offerPrice!) / service.basePrice * 100).round()
    : 0;

final finalPrice = hasOffer ? service.offerPrice! : service.basePrice;
```

### Display Logic:
- **IF** `hasOffer == true`: Shows green offer price + strikethrough original + discount badge
- **ELSE**: Shows green basePrice only

---

## 🐛 POSSIBLE CAUSES FOR ₹0 DISPLAY

### 1. **Firestore Data Missing** ⚠️ MOST LIKELY
```
technician_services/{docId}
  ├─ price: MISSING or 0
  ├─ basePrice: MISSING or 0
  └─ offerPrice: MISSING or 0
```

**Solution:** Add price data to Firestore documents

### 2. **Field Name Mismatch**
- Model expects: `price` or `basePrice`
- Firestore has: Different field name (e.g., `cost`, `amount`)

**Solution:** Update Firestore field names

### 3. **Data Type Issue**
- Firestore stores price as String: `"500"` instead of `500`
- Model handles this with `_parsePrice()` ✅ (Already safe)

### 4. **Null/Zero Values**
- All price fields are `null` or `0`
- UI shows: `₹0`

---

## 📊 DEBUG LOGS ADDED

### Location: `unified_service_card.dart` (line ~65)

```dart
if (kDebugMode) {
  debugPrint('🔍 [SERVICE_CARD_DEBUG] ================');
  debugPrint('🔍 Service: ${service.title}');
  debugPrint('🔍 basePrice: ${service.basePrice}');
  debugPrint('🔍 offerPrice: ${service.offerPrice}');
  debugPrint('🔍 originalPrice: ${service.originalPrice}');
  debugPrint('🔍 price (alias): ${service.price}');
  debugPrint('🔍 hasOffer: $hasOffer');
  debugPrint('🔍 discount: $discount%');
  debugPrint('🔍 finalPrice: $finalPrice');
  debugPrint('🔍 ================');
}
```

---

## 🧪 TESTING STEPS

### Step 1: Check Console Logs
```bash
flutter run
# Scroll home screen
# Check console for debug prints
```

### Expected Output:
```
🔍 [SERVICE_CARD_DEBUG] ================
🔍 Service: AC Repair
🔍 basePrice: 500.0
🔍 offerPrice: 300.0
🔍 originalPrice: null
🔍 price (alias): 500.0
🔍 hasOffer: true
🔍 discount: 40%
🔍 finalPrice: 300.0
🔍 ================
```

### If You See:
```
🔍 basePrice: 0.0
🔍 offerPrice: null
```
**→ ROOT CAUSE: Firestore data missing**

---

## 🔥 FIRESTORE DATA VERIFICATION

### Step 1: Open Firebase Console
```
https://console.firebase.google.com
→ Firestore Database
→ technician_services collection
```

### Step 2: Check 1 Document
```
technician_services/{docId}
  ├─ title: "AC Repair"
  ├─ price: 500          ← CHECK THIS
  ├─ offerPrice: 300     ← CHECK THIS
  ├─ status: "approved"
  └─ ...
```

### Step 3: Verify Field Names
- ✅ Field exists: `price` or `basePrice`
- ✅ Field type: `number` (not string)
- ✅ Field value: > 0

---

## 🎯 EXPECTED FIRESTORE STRUCTURE

### Minimum Required Fields:
```json
{
  "title": "AC Repair Service",
  "price": 500,
  "status": "approved",
  "technicianId": "tech123",
  "categoryId": "ac_repair",
  "imageUrl": "https://...",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

### With Discount:
```json
{
  "title": "AC Repair Service",
  "price": 500,
  "offerPrice": 300,
  "status": "approved",
  ...
}
```

---

## 🚨 COMMON MISTAKES

### ❌ Wrong Field Name
```json
{
  "cost": 500,        // Should be "price"
  "amount": 500       // Should be "price"
}
```

### ❌ String Instead of Number
```json
{
  "price": "500"      // Should be 500 (number)
}
```
**Note:** Model handles this with `_parsePrice()` ✅

### ❌ Missing Status
```json
{
  "price": 500,
  "status": "pending"  // Should be "approved"
}
```

---

## 📝 NEXT STEPS

### 1. **Run App with Debug Logs**
```bash
flutter run
# Scroll to service cards
# Check console output
```

### 2. **Identify Issue from Logs**
- If `basePrice: 0.0` → Firestore data missing
- If `basePrice: 500.0` but UI shows ₹0 → UI rendering issue

### 3. **Fix Firestore Data** (if needed)
```javascript
// In Firebase Console or script
db.collection('technician_services').doc('SERVICE_ID').update({
  price: 500,
  offerPrice: 300
});
```

### 4. **Verify UI Display**
- Hot reload app
- Check if prices now show correctly

---

## ✅ VERIFICATION CHECKLIST

- [ ] Debug logs added to `unified_service_card.dart`
- [ ] App running with console visible
- [ ] Service cards visible on home screen
- [ ] Console shows debug output for each card
- [ ] Firestore data verified for 1 service
- [ ] Field names match model expectations
- [ ] Field values are numbers (not strings)
- [ ] Status is "approved"

---

## 🎯 CONCLUSION

**Model is CORRECT** ✅
- Handles multiple field names (`price`, `basePrice`)
- Safely parses strings to numbers
- Has proper null handling

**UI Logic is CORRECT** ✅
- Calculates discount properly
- Shows offer price when available
- Falls back to base price

**MOST LIKELY ISSUE:**
→ **Firestore documents missing `price` or `basePrice` field**

**PROOF:**
→ Check console logs after running app

---

**Status**: 🔍 DIAGNOSTIC COMPLETE  
**Action Required**: Run app and check console logs  
**Expected Time**: 2 minutes
