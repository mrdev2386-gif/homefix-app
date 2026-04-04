# 🚨 QUICK DEBUG GUIDE - Price Not Showing

## 🎯 WHAT WAS DONE

### ✅ Added Debug Prints at 4 Critical Points:

1. **Firestore Fetch** → Shows raw data from database
2. **Model Parsing** → Shows how data is converted
3. **StreamBuilder** → Shows what reaches UI layer
4. **UI Cards** → Shows final display values

### ✅ Disabled Firestore Cache
- Forces fresh data fetch
- Eliminates stale data issues

---

## 🏃 RUN THIS NOW

```bash
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```

---

## 👀 WATCH CONSOLE FOR

### Pattern 1: Data is in Firestore
```
🔥 [FIRESTORE RAW DATA] price: 900, offerPrice: 600
💰 [MODEL PARSE] Parsed: 900.0, 600.0
📊 [STREAM BUILDER] price=900.0, offer=600.0
UI PRICE CHECK -> price: 900.0, offer: 600.0, final: 600.0
```
✅ **WORKING CORRECTLY**

### Pattern 2: Data missing in Firestore
```
🔥 [FIRESTORE RAW DATA] price: null, offerPrice: null
💰 [MODEL PARSE] Parsed: 0.0, 0.0
```
❌ **ISSUE:** Update Firestore data

### Pattern 3: Parsing fails
```
🔥 [FIRESTORE RAW DATA] price: 900
💰 [MODEL PARSE] Parsed: 0.0
```
❌ **ISSUE:** Model parsing broken

### Pattern 4: UI reads wrong field
```
💰 [MODEL PARSE] Parsed: 900.0
UI PRICE CHECK -> price: 0.0
```
❌ **ISSUE:** UI accessing wrong property

---

## 🔍 FIND YOUR ISSUE

Copy the console output and look for:

1. **Service name** you're testing
2. **All 4 debug points** for that service
3. **Where the value becomes 0**

---

## 📊 EXAMPLE OUTPUT

```
🔥 [FIRESTORE RAW] Fetched 3 documents

📄 [FIRESTORE RAW DATA] abc123:
   price: 900
   offerPrice: 600
   basePrice: null

💰 [MODEL PARSE] AC Repair:
   Firestore price: 900 → Parsed: 900.0
   Firestore offerPrice: 600 → Parsed: 600.0
   Firestore basePrice: null

📊 [STREAM BUILDER] Top Rated Services received 3 services
   AC Repair: price=900.0, offer=600.0
   Plumbing: price=500.0, offer=400.0
   Cleaning: price=300.0, offer=null

UI PRICE CHECK -> price: 900.0, offer: 600.0, final: 600.0
```

---

## 🎯 WHAT TO SHARE

If issue persists, share:

1. **Service name** having the issue
2. **All 4 debug lines** for that service
3. **Screenshot** of Firestore document

---

## 🔧 QUICK FIXES

### If Firestore has wrong data:
```
Go to Firebase Console → technician_services → Find document
Update:
  price: 900 (original price)
  offerPrice: 600 (discount price)
```

### If cache is the issue:
```bash
flutter clean
# Uninstall app from device
flutter run
```

---

**Files Modified:**
- ✅ `firestore_service.dart` - Added Firestore fetch debug
- ✅ `service.dart` - Added model parsing debug
- ✅ `real_services_sections.dart` - Added StreamBuilder debug
- ✅ `unified_service_card.dart` - Added UI display debug
- ✅ `service_card.dart` - Added UI display debug
- ✅ `main.dart` - Disabled Firestore cache

**Next:** Run app and check console output
