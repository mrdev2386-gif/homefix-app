# Custom Request Feature - Quick Fix Reference

## 🔧 CRITICAL FIXES NEEDED

### FIX 1: Customer App - custom_request_screen.dart

**Change**: Replace direct Firestore write with Cloud Function call

**Location**: Line ~130 in `_submitRequest()` method

**Before**:
```dart
await FirestoreService().createCustomRequest(requestData);
```

**After**:
```dart
final callable = FirebaseFunctions.instance.httpsCallable('createCustomRequest');
await callable.call(requestData);
```

**Add Import**:
```dart
import 'package:cloud_functions/cloud_functions.dart';
```

---

### FIX 2: Technician App - custom_requests_screen.dart

**Change**: Query only assigned requests with correct status filter

**Location**: In `StreamBuilder` widget

**Before**:
```dart
.where('technicianId', isEqualTo: technicianId)
```

**After**:
```dart
.where('technicianId', isEqualTo: technicianId)
.where('status', whereIn: ['technician_assigned', 'accepted'])
```

---

### FIX 3: Technician App - Accept Request Handler

**Change**: Call Cloud Function to accept request

**Location**: `_acceptRequest()` method

**Code**:
```dart
Future<void> _acceptRequest(String requestId) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('acceptCustomRequest');
    await callable.call({'requestId': requestId});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted! Booking created.')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
```

---

### FIX 4: Technician App - Decline Request Handler

**Change**: Call Cloud Function to reject request

**Location**: `_declineRequest()` method

**Code**:
```dart
Future<void> _declineRequest(String requestId) async {
  try {
    final callable = FirebaseFunctions.instance.httpsCallable('rejectCustomRequest');
    await callable.call({'requestId': requestId});

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request declined')),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
```

---

### FIX 5: Customer App - Home Screen Entry Point

**Change**: Add custom request card before assistance section

**Location**: In `_buildNeedAssistance()` call in `build()` method

**Add Before**:
```dart
// Custom Request Card
Container(
  margin: const EdgeInsets.fromLTRB(16, 28, 16, 16),
  padding: const EdgeInsets.all(20),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
  ),
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text("Can't find your service?", style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomRequestScreen())),
        child: const Text('Request Custom Service'),
      ),
    ],
  ),
),
```

---

### FIX 6: Customer App - Booking History Detection

**Change**: Detect and display custom request bookings

**Location**: In booking card builder

**Add**:
```dart
if (booking.type == 'custom_request') {
  return _buildCustomRequestBookingCard(booking);
}
```

---

### FIX 7: Cloud Functions Deployment

**File**: `backend/functions/src/customRequests.js`

**Status**: ✅ Already created

**Deploy**:
```bash
cd backend/functions
firebase deploy --only functions
```

---

### FIX 8: Firestore Rules Update

**File**: `firestore.rules`

**Status**: ✅ Already created

**Deploy**:
```bash
firebase deploy --only firestore:rules
```

---

### FIX 9: Firestore Indexes

**Create in Firebase Console**:

1. **Index 1**
   - Collection: custom_requests
   - Fields: status (Asc), createdAt (Desc)

2. **Index 2**
   - Collection: custom_requests
   - Fields: technicianId (Asc), status (Asc)

3. **Index 3**
   - Collection: bookings
   - Fields: customerId (Asc), createdAt (Desc)

---

### FIX 10: Admin Panel Page

**File**: Create `admin/app/custom-requests/page.tsx`

**Status**: ✅ Code provided in CUSTOM_REQUEST_PRODUCTION_READY.md

**Features**:
- List pending requests
- View images
- Assign technician
- Approve/Reject requests
- Real-time updates

---

## 📋 VERIFICATION CHECKLIST

- [ ] Cloud Functions deployed
- [ ] Firestore rules updated
- [ ] Firestore indexes created
- [ ] Customer app calls Cloud Function
- [ ] Technician app queries assigned requests
- [ ] Accept/Decline handlers call Cloud Functions
- [ ] Home screen has custom request card
- [ ] Booking history detects custom request type
- [ ] Admin panel page created
- [ ] All error handling in place
- [ ] Notifications working
- [ ] End-to-end flow tested

---

## 🚀 DEPLOYMENT ORDER

1. Deploy Cloud Functions
2. Update Firestore Rules
3. Create Firestore Indexes
4. Update Customer App
5. Update Technician App
6. Create Admin Panel Page
7. Test end-to-end flow
8. Deploy to production

---

## ✅ PRODUCTION READY

All fixes documented and ready for implementation!
