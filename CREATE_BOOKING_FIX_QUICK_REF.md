# createBookingRequest Fix - Quick Reference

## 🔥 Critical Fix Applied

### Root Cause:
**Wrong Firestore collection name**: `users` → `customers`

---

## ✅ What Was Fixed

1. **Collection Name** (Line 577)
   - ❌ `db.collection('users').doc(uid)`
   - ✅ `db.collection('customers').doc(uid)`

2. **Error Logging**
   - Added 15+ console.log statements
   - Added error stack traces
   - Added input data logging on failure

3. **Input Validation**
   - serviceId: must be string
   - technicianId: must be string
   - price: must be positive number
   - paymentMode: must be 'before_work' or 'after_work'
   - address: must be object

4. **Address Sanitization**
   - Added 7 new fields: fullAddress, landmark, name, phone, district, pincode, label
   - Fallback to copy all primitive values if no keys match

5. **Error Messages**
   - Clear, actionable error messages
   - Context included in errors

---

## 🚀 Deployment

```powershell
cd c:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions:createBookingRequest
```

**Status**: ✅ Deployed successfully to asia-south1

---

## 🧪 Test Now

1. **Login to customer app**
2. **Select a service**
3. **Try to create a booking**
4. **Check logs**:
   ```powershell
   firebase functions:log --only createBookingRequest
   ```

---

## 📊 Expected Logs

You should now see:
```
✅ [createBookingRequest] Auth UID: abc123...
📦 [createBookingRequest] INPUT DATA: {...}
🔍 [createBookingRequest] Validating inputs...
✅ [createBookingRequest] Input validation passed
🔍 [createBookingRequest] Fetching customer profile...
✅ [createBookingRequest] Customer found: John Doe
🔍 [createBookingRequest] Fetching service data...
📦 [createBookingRequest] Service data: {...}
✅ [createBookingRequest] Using price: 500
🔍 [createBookingRequest] Fetching technician data...
✅ [createBookingRequest] Technician verified
🔑 [createBookingRequest] Idempotency key: BK_...
🆔 [createBookingRequest] Generated booking ID: ...
✅ [BOOKING] Created booking: ...
```

---

## ❌ If It Still Fails

Check logs for specific error:

### Error: "Customer profile not found"
**Fix**: User needs to complete profile first

### Error: "Service listing not found"
**Fix**: serviceId is invalid or service doesn't exist

### Error: "Technician not verified"
**Fix**: Select a different technician

### Error: "Invalid paymentMode"
**Fix**: Use 'before_work' or 'after_work'

---

## 📝 Files Modified

- ✅ `functions/src/booking/unified_booking_lifecycle.ts`
- ✅ Deployed to Firebase

---

## 🔍 Debug Commands

```powershell
# View all logs
firebase functions:log --only createBookingRequest

# View errors only
firebase functions:log --only createBookingRequest | findstr "ERROR"

# View specific booking
firebase functions:log --only createBookingRequest | findstr "bookingId"

# Real-time monitoring
firebase functions:log --only createBookingRequest --follow
```

---

## ✅ Success Criteria

Function should now:
- ✅ Return clear error messages
- ✅ Log every step
- ✅ Find customer profile correctly
- ✅ Preserve all address fields
- ✅ Handle payment modes safely
- ✅ Never crash with "unexpected error"
