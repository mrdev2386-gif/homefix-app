# Price/Offer System - Quick Reference

## 🎯 Quick Summary

**Problem**: Services need to show original price (strikethrough) and offer price (discounted).

**Solution**: Strict validation + correct Firestore structure + proper UI rendering.

---

## 📊 Data Structure

```javascript
// Firestore: technician_services/{serviceId}
{
  price: 700,           // Original price (strikethrough)
  offerPrice: 400,      // Discounted price (display)
  basePrice: 700,       // Same as price (backward compat)
}
```

---

## ✅ Validation Rules

### Client-Side (Technician App)
1. ✅ `originalPrice` is REQUIRED and must be > 0
2. ✅ `offerPrice` is REQUIRED and must be > 0
3. ✅ `offerPrice` must be **strictly less than** `originalPrice`

### Server-Side (Cloud Functions)
1. ✅ `price` is REQUIRED and must be > 0
2. ✅ `offerPrice` is REQUIRED and must be > 0
3. ✅ `offerPrice` must be **strictly less than** `price`

---

## 🎨 UI Display Logic

```dart
// Customer App - Service Card
final originalPrice = service.basePrice;  // 700
final offerPrice = service.offerPrice;    // 400

// Show offer only if offerPrice < originalPrice
final hasOffer = offerPrice > 0 && offerPrice < originalPrice;

// Display:
if (hasOffer) {
  // Show: ₹400 (green) + ~~₹700~~ (strikethrough)
} else {
  // Show: ₹700 (green) only
}
```

---

## 🧪 Test Cases

### ✅ Valid Service
```
Original Price: ₹700
Offer Price: ₹400
Result: ✅ Saves successfully
Display: ₹400 + ~~₹700~~
```

### ❌ Invalid Service (offer >= original)
```
Original Price: ₹500
Offer Price: ₹600
Result: ❌ Blocked with error
Error: "Offer price must be strictly less than original price"
```

### ❌ Missing Price
```
Original Price: (empty)
Offer Price: ₹400
Result: ❌ Blocked with error
Error: "Original price is required and must be greater than 0"
```

---

## 📝 Debug Commands

### Check Firestore Data
```javascript
// Firebase Console → Firestore → technician_services
// Look for: price, offerPrice, basePrice fields
```

### Check Logs (Technician App)
```
[SAVE DEBUG] originalPrice: 700.0, offerPrice: 400.0
[FunctionsService] addService DATA: {...}
[ADD SERVICE] SUCCESS
```

### Check Logs (Cloud Functions)
```powershell
firebase functions:log --only addTechnicianService
```
Look for:
```
[PRICING DEBUG] Service abc123: price=700, offerPrice=400, basePrice=700
```

### Check Logs (Customer App)
```
💰 [MODEL PARSE] AC Repair:
   Firestore price: 700 → Parsed: 700.0
   Firestore offerPrice: 400 → Parsed: 400.0
[UI PRICE] AC Repair: original=700.0, offer=400.0, display=400.0, hasOffer=true
```

---

## 🚀 Quick Deploy

```powershell
# 1. Deploy Cloud Functions
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:addTechnicianService,functions:updateTechnicianService

# 2. Rebuild Technician App
cd c:\Users\yash\projects\homefix\apps\technician_app
flutter clean && flutter pub get && flutter run

# 3. Rebuild Customer App
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter clean && flutter pub get && flutter run
```

---

## 🔍 Troubleshooting

### Issue: Service saves but UI shows wrong price
**Fix**: Check model parsing logs in customer app console

### Issue: Validation not working
**Fix**: Check if both client and server validations are deployed

### Issue: Old services not displaying
**Fix**: Backward compatibility is built-in, check logs for fallback logic

---

## 📞 Support

Contact: **9508322397**

---

## 📄 Modified Files

1. `apps/technician_app/lib/features/technician/services/add_service_screen.dart`
2. `apps/technician_app/lib/core/services/functions_service.dart`
3. `functions/src/technician/services_management.ts`
4. `apps/customer_app/lib/core/models/service.dart`
5. `apps/customer_app/lib/features/dashboard/widgets/service_card.dart`

---

**Status**: ✅ Complete  
**Version**: 1.0
