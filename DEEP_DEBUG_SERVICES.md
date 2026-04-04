# 🔍 DEEP DEBUG TRACE - Services Screen Price Issue

## ✅ CHANGES IMPLEMENTED

### 1. **CategoryService Debug Logging** ✅
**Files:** `category_service.dart`

Added comprehensive logging at data fetch level:

```dart
// In getAllServices() and getServicesByCategory()
.map((snapshot) {
  debugPrint('\n🔥 [CATEGORY_SERVICE] Fetched ${snapshot.docs.length} documents');
  
  final services = snapshot.docs.map((doc) {
    final data = doc.data() as Map<String, dynamic>;
    debugPrint('📄 [CATEGORY_SERVICE RAW] ${doc.id}:');
    debugPrint('   price: ${data['price']}');
    debugPrint('   offerPrice: ${data['offerPrice']}');
    debugPrint('   basePrice: ${data['basePrice']}');
    return HomeService.fromFirestore(doc);
  })
  
  debugPrint('\n✅ [CATEGORY_SERVICE] Returning ${services.length} services');
  for (final service in services.take(3)) {
    debugPrint('   ${service.title}: price=${service.price}, offer=${service.offerPrice}');
  }
})
```

### 2. **UI Widget Debug Logging** ✅
**File:** `service_list_screen.dart` → `_ServiceGridCard`

Added comprehensive logging at UI render level:

```dart
print("\n🎯 [_ServiceGridCard] ACTIVE WIDGET RENDERING:");
print("   Service: ${service.title}");
print("   service.price: ${service.price}");
print("   service.offerPrice: ${service.offerPrice}");
print("   Calculated price: $price");
print("   Calculated offerPrice: $offerPrice");
print("   hasOffer: $hasOffer");
print("   finalPrice: $finalPrice");
```

### 3. **Visibility Test Container** ✅
Added RED test container to verify widget is rendering:

```dart
Container(
  color: Colors.red.withOpacity(0.3),
  padding: const EdgeInsets.all(4),
  child: Text(
    "TEST: ₹$finalPrice",
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 12,
    ),
  ),
),
```

---

## 🚀 HOW TO USE THIS DEBUG SYSTEM

### Step 1: Run the App
```bash
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter run
```

### Step 2: Navigate to Services Screen
- Tap search bar on home screen
- OR tap "View All" on any section
- OR tap a category card

### Step 3: Watch Console Output

You should see a complete trace like this:

```
🔥 [CATEGORY_SERVICE] Fetched 5 documents

📄 [CATEGORY_SERVICE RAW] abc123:
   price: 900
   offerPrice: 600
   basePrice: null

📄 [CATEGORY_SERVICE RAW] def456:
   price: 500
   offerPrice: null
   basePrice: null

💰 [MODEL PARSE] AC Repair:
   Firestore price: 900 → Parsed: 900.0
   Firestore offerPrice: 600 → Parsed: 600.0

✅ [CATEGORY_SERVICE] Returning 5 services
   AC Repair: price=900.0, offer=600.0
   Plumbing: price=500.0, offer=null

🎯 [_ServiceGridCard] ACTIVE WIDGET RENDERING:
   Service: AC Repair
   service.price: 900.0
   service.offerPrice: 600.0
   Calculated price: 900.0
   Calculated offerPrice: 600.0
   hasOffer: true
   finalPrice: 600.0
```

### Step 4: Check UI
Look for:
1. **RED test container** with "TEST: ₹600" (or whatever price)
2. **Green price** below it: ₹600
3. **Grey strikethrough** if offer exists: ₹900

---

## 🔍 DIAGNOSIS GUIDE

### Scenario A: No console output at all
**Issue:** Services screen not loading data  
**Check:**
- Is user logged in?
- Does user have a primary address set?
- Check console for location errors

### Scenario B: CATEGORY_SERVICE shows correct data, but UI shows ₹0
**Console:**
```
📄 [CATEGORY_SERVICE RAW] abc123:
   price: 900
   offerPrice: 600

🎯 [_ServiceGridCard] ACTIVE WIDGET RENDERING:
   service.price: 0.0
   service.offerPrice: 0.0
```

**Issue:** Model parsing is broken  
**Fix:** Check `service.dart` model parsing logic

### Scenario C: Model shows correct data, but UI shows ₹0
**Console:**
```
🎯 [_ServiceGridCard] ACTIVE WIDGET RENDERING:
   service.price: 900.0
   service.offerPrice: 600.0
   finalPrice: 600.0
```

**But UI shows:** ₹0

**Issue:** UI rendering logic is broken  
**Fix:** Check price display code in `_ServiceGridCard`

### Scenario D: RED test container not visible
**Issue:** Wrong widget is being used  
**Action:** Search for other ServiceCard widgets that might be rendering instead

### Scenario E: Firestore shows 0 or null
**Console:**
```
📄 [CATEGORY_SERVICE RAW] abc123:
   price: null
   offerPrice: null
```

**Issue:** Data in Firestore is wrong  
**Fix:** Update Firestore documents with correct price values

---

## 📊 EXPECTED OUTPUT (Correct Flow)

### For service with price=900, offerPrice=600:

**Console:**
```
🔥 [CATEGORY_SERVICE] Fetched 1 documents

📄 [CATEGORY_SERVICE RAW] service_123:
   price: 900
   offerPrice: 600
   basePrice: null

💰 [MODEL PARSE] AC Repair:
   Firestore price: 900 → Parsed: 900.0
   Firestore offerPrice: 600 → Parsed: 600.0

✅ [CATEGORY_SERVICE] Returning 1 services
   AC Repair: price=900.0, offer=600.0

🎯 [_ServiceGridCard] ACTIVE WIDGET RENDERING:
   Service: AC Repair
   service.price: 900.0
   service.offerPrice: 600.0
   Calculated price: 900.0
   Calculated offerPrice: 600.0
   hasOffer: true
   finalPrice: 600.0
```

**UI Display:**
- RED test container: "TEST: ₹600"
- Green price: **₹600**
- Grey strikethrough: **₹900**
- Red badge: **33% OFF**

---

## 🎯 VERIFICATION CHECKLIST

Run through this checklist:

- [ ] Console shows CATEGORY_SERVICE fetching documents
- [ ] Console shows RAW Firestore data with price values
- [ ] Console shows MODEL PARSE with correct values
- [ ] Console shows _ServiceGridCard ACTIVE WIDGET with correct values
- [ ] UI shows RED test container with price
- [ ] UI shows green price (not ₹0)
- [ ] UI shows strikethrough when offer exists
- [ ] Discount badge shows correct percentage

---

## 🔧 TROUBLESHOOTING STEPS

### If prices still show as ₹0:

1. **Check Firestore directly:**
   - Go to Firebase Console
   - Navigate to `technician_services` collection
   - Find a document
   - Verify `price` and `offerPrice` fields exist and have values

2. **Check user location:**
   - Console should show: "✅ [CategoryService] filtering by location: state/district"
   - If not, user needs to set primary address

3. **Check query filters:**
   - Services must have `status: 'approved'`
   - Services must match user's state and district

4. **Force full restart:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```
   Press `R` (capital R) for full restart

---

## 🧹 CLEANUP (After Fix)

Once you've identified and fixed the issue:

1. **Remove RED test container** from `_ServiceGridCard`
2. **Keep debug prints** temporarily for verification
3. **Remove debug prints** after confirming fix works in production

---

## 📝 FILES MODIFIED

| File | Changes | Purpose |
|------|---------|---------|
| `category_service.dart` | Added debug logs | Track Firestore fetch |
| `service_list_screen.dart` | Added debug logs + test container | Track UI rendering |
| `service.dart` | Already has debug logs | Track model parsing |

---

**Status:** ✅ DEEP DEBUG SYSTEM COMPLETE  
**Next:** Run app, navigate to Services screen, analyze console output
