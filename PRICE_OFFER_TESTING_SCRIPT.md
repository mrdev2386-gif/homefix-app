# Price/Offer System - Testing Script

## 🧪 Complete Testing Guide

Follow this script step-by-step to verify the implementation.

---

## 📋 Pre-Testing Setup

### 1. Deploy Cloud Functions
```powershell
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:addTechnicianService,functions:updateTechnicianService
```

**Expected Output**:
```
✔  functions[addTechnicianService(asia-south1)] Successful update operation.
✔  functions[updateTechnicianService(asia-south1)] Successful update operation.
```

### 2. Rebuild Technician App
```powershell
cd c:\Users\yash\projects\homefix\apps\technician_app
flutter clean
flutter pub get
flutter run
```

### 3. Rebuild Customer App
```powershell
cd c:\Users\yash\projects\homefix\apps\customer_app
flutter clean
flutter pub get
flutter run
```

---

## 🎯 Test Case 1: Valid Service with Offer

### Steps:
1. Open Technician App
2. Navigate to "Add Service" screen
3. Fill in:
   - Service Name: "AC Repair Test"
   - Category: "AC"
   - Original Price: 700
   - Offer Price: 400
   - Upload image
   - Description: "Test service"
4. Click "Add Service"

### Expected Results:
✅ **Technician App Console**:
```
[SAVE DEBUG] originalPrice: 700.0, offerPrice: 400.0
[FunctionsService] addService DATA: {name: AC Repair Test, category: ac, price: 700.0, offerPrice: 400.0, ...}
[ADD SERVICE] SUCCESS
```

✅ **Cloud Functions Logs**:
```powershell
firebase functions:log --only addTechnicianService
```
Look for:
```
[PRICING DEBUG] Service abc123: price=700, offerPrice=400, basePrice=700
[SERVICE_ADD] ✅ Service abc123 created for technician xyz789
```

✅ **Firestore Console**:
- Navigate to: `technician_services/{serviceId}`
- Verify fields:
  ```javascript
  {
    price: 700,
    offerPrice: 400,
    basePrice: 700,
    name: "AC Repair Test",
    status: "pending",
    isActive: false
  }
  ```

✅ **Customer App** (after admin approval):
- Service card shows:
  - **₹400** (green, bold)
  - **~~₹700~~** (strikethrough)

✅ **Customer App Console**:
```
💰 [MODEL PARSE] AC Repair Test:
   Firestore price: 700 → Parsed: 700.0
   Firestore offerPrice: 400 → Parsed: 400.0
   Final: price=700.0 (strikethrough), offerPrice=400.0 (display)
[UI PRICE] AC Repair Test: original=700.0, offer=400.0, display=400.0, hasOffer=true
```

---

## 🎯 Test Case 2: Invalid Service (Offer >= Original)

### Steps:
1. Open Technician App
2. Navigate to "Add Service" screen
3. Fill in:
   - Service Name: "Invalid Service"
   - Category: "Plumbing"
   - Original Price: 500
   - Offer Price: 600 (INVALID)
   - Upload image
4. Click "Add Service"

### Expected Results:
❌ **Technician App**:
- Shows error snackbar: "Offer price must be strictly less than original price"
- Service is NOT created
- Form remains open

❌ **Firestore**:
- No new document created

---

## 🎯 Test Case 3: Missing Original Price

### Steps:
1. Open Technician App
2. Navigate to "Add Service" screen
3. Fill in:
   - Service Name: "Missing Price Service"
   - Category: "Electrical"
   - Original Price: (leave empty)
   - Offer Price: 400
   - Upload image
4. Click "Add Service"

### Expected Results:
❌ **Technician App**:
- Shows error snackbar: "Original price is required and must be greater than 0"
- Service is NOT created
- Form remains open

---

## 🎯 Test Case 4: Missing Offer Price

### Steps:
1. Open Technician App
2. Navigate to "Add Service" screen
3. Fill in:
   - Service Name: "Missing Offer Service"
   - Category: "Cleaning"
   - Original Price: 700
   - Offer Price: (leave empty)
   - Upload image
4. Click "Add Service"

### Expected Results:
❌ **Technician App**:
- Shows error snackbar: "Offer price is required and must be greater than 0"
- Service is NOT created
- Form remains open

---

## 🎯 Test Case 5: Update Existing Service

### Steps:
1. Open Technician App
2. Navigate to "My Services"
3. Select an existing service
4. Click "Edit"
5. Update:
   - Original Price: 800
   - Offer Price: 500
6. Click "Update Service"

### Expected Results:
✅ **Technician App Console**:
```
[UPDATE DEBUG] originalPrice: 800.0, offerPrice: 500.0
[FunctionsService] updateService DATA: {serviceId: abc123, price: 800.0, offerPrice: 500.0, ...}
[UPDATE SERVICE] SUCCESS
```

✅ **Firestore**:
- Document updated with new prices
- `updatedAt` timestamp updated

✅ **Customer App**:
- Service card shows updated prices: ₹500 + ~~₹800~~

---

## 🎯 Test Case 6: Backward Compatibility (Old Service)

### Setup:
Manually create a service in Firestore with old structure:
```javascript
{
  name: "Old Service",
  price: 500,
  // No offerPrice field
  category: "plumbing",
  status: "approved",
  isActive: true
}
```

### Expected Results:
✅ **Customer App Console**:
```
💰 [MODEL PARSE] Old Service:
   Firestore price: 500 → Parsed: 500.0
   Firestore offerPrice: null → Parsed: 500.0 (fallback)
   Final: price=500.0 (strikethrough), offerPrice=500.0 (display)
[UI PRICE] Old Service: original=500.0, offer=500.0, display=500.0, hasOffer=false
```

✅ **Customer App UI**:
- Service card shows: **₹500** (green, bold)
- NO strikethrough (because offerPrice == price)

---

## 🎯 Test Case 7: Service Without Discount

### Setup:
Create a service where offerPrice == price:
```javascript
{
  name: "No Discount Service",
  price: 600,
  offerPrice: 600,
  basePrice: 600,
  category: "electrical",
  status: "approved",
  isActive: true
}
```

### Expected Results:
✅ **Customer App UI**:
- Service card shows: **₹600** (green, bold)
- NO strikethrough (because offerPrice == price)

---

## 🎯 Test Case 8: Server-Side Validation Bypass Attempt

### Steps:
1. Try to bypass client validation by directly calling Cloud Function
2. Use Firebase Console or Postman to call `addTechnicianService`
3. Send data:
   ```json
   {
     "name": "Bypass Test",
     "price": 500,
     "offerPrice": 600,
     "category": "ac",
     "imageUrl": "https://example.com/image.jpg"
   }
   ```

### Expected Results:
❌ **Cloud Functions**:
- Returns error: "Offer price must be strictly less than original price"
- HTTP Status: 400 (invalid-argument)
- Service is NOT created

---

## 📊 Testing Checklist

### Technician App
- [ ] ✅ Valid service with offer saves successfully
- [ ] ❌ Invalid service (offer >= original) is blocked
- [ ] ❌ Missing original price is blocked
- [ ] ❌ Missing offer price is blocked
- [ ] ✅ Update service works correctly
- [ ] ✅ Debug logs appear in console

### Cloud Functions
- [ ] ✅ Server-side validation works
- [ ] ❌ Bypass attempts are blocked
- [ ] ✅ Correct data structure saved to Firestore
- [ ] ✅ Debug logs appear in Firebase logs

### Customer App
- [ ] ✅ Service with offer displays correctly (₹400 + ~~₹700~~)
- [ ] ✅ Service without offer displays correctly (₹500 only)
- [ ] ✅ Old services display correctly (backward compatibility)
- [ ] ✅ Debug logs appear in console

### Firestore
- [ ] ✅ `price` field contains original price
- [ ] ✅ `offerPrice` field contains discounted price
- [ ] ✅ `basePrice` field contains original price
- [ ] ✅ All required fields are present

---

## 🐛 Troubleshooting

### Issue: Validation not working
**Check**:
1. Cloud Functions deployed? `firebase functions:list`
2. Technician app rebuilt? `flutter clean && flutter pub get`
3. Check console for error logs

### Issue: UI shows wrong price
**Check**:
1. Customer app rebuilt?
2. Check console for `[MODEL PARSE]` logs
3. Verify Firestore data structure

### Issue: Old services not displaying
**Check**:
1. Check console for fallback logic logs
2. Verify backward compatibility code is present

---

## 📞 Support

For issues or questions, contact: **9508322397**

---

## ✅ Sign-Off

After completing all test cases:

- [ ] All validation tests passed
- [ ] All UI rendering tests passed
- [ ] Backward compatibility verified
- [ ] Debug logs verified at all levels
- [ ] Firestore data structure verified
- [ ] Server-side validation verified

**Tested By**: _______________  
**Date**: _______________  
**Status**: ✅ PASS / ❌ FAIL

---

**Version**: 1.0  
**Last Updated**: 2025-01-XX
