# 🔍 PRICE DEBUG TRACE - COMPLETE DATA FLOW TRACKING

## ✅ CHANGES IMPLEMENTED

### 1. **Firestore Service** (Data Fetch Level)
**File:** `apps/customer_app/lib/core/services/firestore_service.dart`

**Added Debug Prints:**
```dart
Stream<List<HomeService>> streamAllTechnicianServices({int limit = 50}) {
  return _db.collection('technician_services')
      .where('status', isEqualTo: 'approved')
      .limit(limit)
      .snapshots()
      .map((snapshot) {
        print('\n🔥 [FIRESTORE RAW] Fetched ${snapshot.docs.length} documents');
        final services = snapshot.docs.map((doc) {
          final data = doc.data();
          print('📄 [FIRESTORE RAW DATA] ${doc.id}:');
          print('   price: ${data['price']}');
          print('   offerPrice: ${data['offerPrice']}');
          print('   basePrice: ${data['basePrice']}');
          return HomeService.fromFirestore(doc);
        })
        // ...
      });
}
```

**What it shows:**
- Raw Firestore document data BEFORE parsing
- Exact values of `price`, `offerPrice`, `basePrice` fields
- Number of documents fetched

---

### 2. **Service Model** (Parsing Level)
**File:** `apps/customer_app/lib/core/models/service.dart`

**Added Debug Prints:**
```dart
// Extract price (main/original price)
price = _parsePrice(data['price']);

// Extract offerPrice (discounted price)
offerPrice = _parsePrice(data['offerPrice']);

// Fallback: if price is 0, try basePrice field (legacy support)
if (price == 0.0) {
  price = _parsePrice(data['basePrice']);
}

// DEBUG: Print parsed values for EVERY service
print('💰 [MODEL PARSE] ${title}:');
print('   Firestore price: ${data['price']} → Parsed: $price');
print('   Firestore offerPrice: ${data['offerPrice']} → Parsed: $offerPrice');
print('   Firestore basePrice: ${data['basePrice']}');
```

**What it shows:**
- Raw Firestore values vs parsed values
- Which field was used (price vs basePrice fallback)
- Parsing success/failure

---

### 3. **StreamBuilder** (UI Data Reception Level)
**File:** `apps/customer_app/lib/features/dashboard/widgets/real_services_sections.dart`

**Added Debug Prints:**
```dart
var services = snapshot.data ?? [];

print('\n📊 [STREAM BUILDER] $title received ${services.length} services');
for (final service in services.take(3)) {
  print('   ${service.title}: price=${service.price}, offer=${service.offerPrice}');
}
```

**What it shows:**
- How many services reached the UI
- Final price values in the model objects
- Which services are being displayed

---

### 4. **UI Cards** (Display Level)
**Files:** 
- `apps/customer_app/lib/features/dashboard/widgets/unified_service_card.dart`
- `apps/customer_app/lib/features/dashboard/widgets/service_card.dart`

**Added Debug Prints:**
```dart
final double price = service.price ?? 0;
final double offerPrice = service.offerPrice ?? 0;

final bool hasOffer = offerPrice > 0 && offerPrice < price;
final double finalPrice = hasOffer ? offerPrice : price;

print("UI PRICE CHECK -> price: $price, offer: $offerPrice, final: $finalPrice");
```

**What it shows:**
- Exact values used for UI rendering
- Whether offer logic is triggered
- Final displayed price

---

### 5. **Firestore Cache Disabled**
**File:** `apps/customer_app/lib/main.dart`

**Added:**
```dart
// CRITICAL: Disable Firestore cache for debugging price issues
print('⚠️ [DEBUG] Disabling Firestore persistence cache...');
FirebaseFirestore.instance.settings = const Settings(
  persistenceEnabled: false,
);
print('✅ Firestore cache disabled - all data will be fetched fresh');
```

**What it does:**
- Forces fresh data fetch from Firestore
- Eliminates cached/stale data issues
- Ensures you see latest Firestore values

---

## 📋 HOW TO USE THIS DEBUG TRACE

### Step 1: Run the App
```bash
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter run
```

### Step 2: Watch Console Output
The console will show a complete trace like this:

```
🔥 [FIRESTORE RAW] Fetched 5 documents
📄 [FIRESTORE RAW DATA] abc123:
   price: 900
   offerPrice: 600
   basePrice: null

💰 [MODEL PARSE] AC Repair:
   Firestore price: 900 → Parsed: 900.0
   Firestore offerPrice: 600 → Parsed: 600.0
   Firestore basePrice: null

📊 [STREAM BUILDER] Recommended For You received 5 services
   AC Repair: price=900.0, offer=600.0

UI PRICE CHECK -> price: 900.0, offer: 600.0, final: 600.0
```

### Step 3: Diagnose the Issue

**Scenario A: Firestore has correct data, but UI shows 0**
```
🔥 [FIRESTORE RAW DATA] price: 900, offerPrice: 600
💰 [MODEL PARSE] Parsed: 0.0
```
→ **ISSUE:** Model parsing is broken

**Scenario B: Firestore has 0, model parses 0**
```
🔥 [FIRESTORE RAW DATA] price: 0, offerPrice: 0
💰 [MODEL PARSE] Parsed: 0.0
```
→ **ISSUE:** Data in Firestore is wrong

**Scenario C: Model has correct data, UI shows 0**
```
💰 [MODEL PARSE] Parsed: 900.0
📊 [STREAM BUILDER] price=900.0
UI PRICE CHECK -> price: 0.0
```
→ **ISSUE:** UI is reading wrong field

---

## 🎯 EXPECTED OUTPUT (Correct Flow)

For a service with price=900, offerPrice=600:

```
🔥 [FIRESTORE RAW] Fetched 1 documents
📄 [FIRESTORE RAW DATA] service_123:
   price: 900
   offerPrice: 600
   basePrice: null

💰 [MODEL PARSE] AC Repair:
   Firestore price: 900 → Parsed: 900.0
   Firestore offerPrice: 600 → Parsed: 600.0
   Firestore basePrice: null

📊 [STREAM BUILDER] Top Rated Services received 1 services
   AC Repair: price=900.0, offer=600.0

UI PRICE CHECK -> price: 900.0, offer: 600.0, final: 600.0
```

**UI Display:**
- Shows: **₹600** (green, bold)
- Shows: **₹900** (grey, strikethrough)
- Discount badge: **33% OFF**

---

## 🔧 TROUBLESHOOTING

### Issue: No debug prints appear
**Solution:** Make sure you're running in debug mode:
```bash
flutter run --debug
```

### Issue: Prints show null values
**Solution:** Check Firestore collection name:
```dart
// Should be:
_db.collection('technician_services')

// NOT:
_db.collection('services')
```

### Issue: Cache still showing old data
**Solution:** Clear app data:
```bash
flutter clean
flutter pub get
flutter run
```

Or uninstall and reinstall the app.

---

## 🚀 NEXT STEPS

1. **Run the app** and collect console output
2. **Find the problematic service** in the logs
3. **Compare values** at each level:
   - Firestore → Model → StreamBuilder → UI
4. **Identify where the data breaks**
5. **Fix the specific issue** based on diagnosis

---

## 📝 IMPORTANT NOTES

- **All debug prints are temporary** - remove them after fixing
- **Cache is disabled** - remember to re-enable for production:
  ```dart
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );
  ```
- **Performance impact** - these prints will slow down the app slightly

---

## ✅ VERIFICATION CHECKLIST

After fixing the issue:

- [ ] Firestore shows correct price values
- [ ] Model parses values correctly
- [ ] StreamBuilder receives correct data
- [ ] UI displays correct prices
- [ ] Discount calculation works
- [ ] Strikethrough shows on original price
- [ ] No console errors

---

**Status:** ✅ DEBUG TRACE COMPLETE  
**Next:** Run app and analyze console output
