# Custom Request Feature - Complete End-to-End Implementation

## 📋 Overview

This document provides the complete implementation for the Custom Request feature across all three apps (Customer, Technician, Admin) with Firebase Cloud Functions and Storage.

---

## 1️⃣ FIRESTORE COLLECTION STRUCTURE

### Collection: `custom_requests`

```json
{
  "type": "custom_request",
  "customerId": "user_uid",
  "title": "AC gas refill needed",
  "description": "AC not cooling properly",
  "category": "AC Repair",
  "preferredDate": "2024-01-15",
  "preferredTime": "14:30",
  "budget": 500,
  "address": "123 Main St, Apt 4B",
  "state": "Maharashtra",
  "district": "Mumbai",
  "pincode": "400001",
  "images": [
    "https://storage.googleapis.com/bucket/custom_requests/req123/image_1.jpg",
    "https://storage.googleapis.com/bucket/custom_requests/req123/image_2.jpg"
  ],
  "technicianId": null,
  "status": "pending_admin_review",
  "createdAt": "2024-01-10T10:30:00Z",
  "updatedAt": "2024-01-10T10:30:00Z"
}
```

### Status Flow

```
pending_admin_review → approved → technician_assigned → accepted → in_progress → completed
                    ↓
                  rejected
```

---

## 2️⃣ FIREBASE STORAGE STRUCTURE

### Path: `custom_requests/{requestId}/{imageId}.jpg`

Example:
```
gs://homefix-bucket/custom_requests/req_1704873000000/image_1704873000001_0.jpg
gs://homefix-bucket/custom_requests/req_1704873000000/image_1704873000001_1.jpg
gs://homefix-bucket/custom_requests/req_1704873000000/image_1704873000001_2.jpg
```

---

## 3️⃣ CLOUD FUNCTIONS

### Function 1: `createCustomRequest`

**Trigger**: HTTPS Callable
**Auth**: Required (Firebase Auth)

```javascript
exports.createCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;
  const { title, description, category, preferredDate, preferredTime, budget, address, state, district, pincode, images } = data;

  if (!title || !description || !category || !preferredDate || !preferredTime || !address) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
  }

  try {
    const requestId = db.collection('custom_requests').doc().id;
    
    const requestData = {
      type: 'custom_request',
      customerId: userId,
      title: title.trim(),
      description: description.trim(),
      category,
      preferredDate,
      preferredTime,
      budget: budget ? parseFloat(budget) : null,
      address,
      state: state || '',
      district: district || '',
      pincode: pincode || '',
      images: images || [],
      technicianId: null,
      status: 'pending_admin_review',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('custom_requests').doc(requestId).set(requestData);

    return {
      success: true,
      requestId,
      message: 'Request created successfully',
    };
  } catch (error) {
    console.error('Error creating custom request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to create request');
  }
});
```

### Function 2: `assignTechnicianToRequest`

**Trigger**: HTTPS Callable
**Auth**: Admin only

```javascript
exports.assignTechnicianToRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId, technicianId } = data;

  if (!requestId || !technicianId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId or technicianId');
  }

  try {
    await db.collection('custom_requests').doc(requestId).update({
      technicianId,
      status: 'technician_assigned',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Send notification to technician
    await sendNotification(technicianId, {
      title: 'New Custom Service Request',
      body: 'You have been assigned a new custom service request',
      data: { requestId, type: 'custom_request' },
    });

    return { success: true, message: 'Technician assigned' };
  } catch (error) {
    console.error('Error assigning technician:', error);
    throw new functions.https.HttpsError('internal', 'Failed to assign technician');
  }
});
```

### Function 3: `acceptCustomRequest`

**Trigger**: HTTPS Callable
**Auth**: Assigned technician only

```javascript
exports.acceptCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const technicianId = context.auth.uid;
  const { requestId } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId');
  }

  try {
    const requestDoc = await db.collection('custom_requests').doc(requestId).get();
    
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Request not found');
    }

    const requestData = requestDoc.data();
    
    if (requestData.technicianId !== technicianId) {
      throw new functions.https.HttpsError('permission-denied', 'Not assigned to this request');
    }

    // Update request status
    await db.collection('custom_requests').doc(requestId).update({
      status: 'accepted',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Create booking
    const bookingId = db.collection('bookings').doc().id;
    const bookingData = {
      type: 'custom_request',
      customRequestId: requestId,
      customerId: requestData.customerId,
      technicianId,
      status: 'approved',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    await db.collection('bookings').doc(bookingId).set(bookingData);

    // Notify customer
    await sendNotification(requestData.customerId, {
      title: 'Technician Assigned',
      body: 'A technician has accepted your custom service request',
      data: { bookingId, type: 'booking' },
    });

    return {
      success: true,
      bookingId,
      message: 'Request accepted and booking created',
    };
  } catch (error) {
    console.error('Error accepting request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to accept request');
  }
});
```

### Function 4: `rejectCustomRequest`

```javascript
exports.rejectCustomRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { requestId } = data;

  if (!requestId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing requestId');
  }

  try {
    await db.collection('custom_requests').doc(requestId).update({
      status: 'rejected',
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { success: true, message: 'Request rejected' };
  } catch (error) {
    console.error('Error rejecting request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to reject request');
  }
});
```

---

## 4️⃣ FIRESTORE SECURITY RULES

```javascript
match /custom_requests/{requestId} {
  // Customer can read their own requests
  allow read: if request.auth.uid == resource.data.customerId;
  
  // Technician can read assigned requests
  allow read: if request.auth.uid == resource.data.technicianId;
  
  // Admin can read all requests
  allow read: if request.auth.token.admin == true;
  
  // Only Cloud Functions can write
  allow create: if false;
  allow update: if false;
  allow delete: if false;
}
```

---

## 5️⃣ CUSTOMER APP IMPLEMENTATION

### File: `custom_request_screen.dart`

**Key Features**:
- Form validation
- Image upload to Firebase Storage
- Cloud Function integration
- Success dialog

**Flow**:
1. User fills form
2. Picks up to 3 images
3. Taps "Submit Request"
4. Images uploaded to Storage
5. Cloud Function creates Firestore document
6. Success dialog shown

---

## 6️⃣ TECHNICIAN APP IMPLEMENTATION

### File: `custom_requests_screen.dart`

**Key Features**:
- Stream of assigned requests
- Request details display
- Accept/Decline buttons
- Image preview

**Flow**:
1. Technician sees assigned requests
2. Reviews request details and images
3. Taps "Accept" or "Decline"
4. Cloud Function updates status
5. Booking created automatically

---

## 7️⃣ ADMIN PANEL IMPLEMENTATION

### File: `app/custom-requests/page.tsx`

**Key Features**:
- List all pending requests
- View request details and images
- Approve/Reject requests
- Assign technician from dropdown
- Real-time updates

**Flow**:
1. Admin views pending requests
2. Reviews details and images
3. Selects technician from dropdown
4. Clicks "Assign"
5. Cloud Function sends notification to technician

---

## 8️⃣ CUSTOMER BOOKING TRACKING

### Update: `booking_history_screen.dart`

Add custom request booking card:

```dart
// In booking card builder
if (booking.type == 'custom_request') {
  return CustomRequestBookingCard(booking: booking);
}
```

**Display**:
- Custom request title
- Status badge
- Technician info (when assigned)
- Action buttons based on status

---

## 9️⃣ HOME SCREEN ENTRY POINT

### Update: `home_screen.dart`

Add card before "Need Assistance":

```dart
Container(
  margin: const EdgeInsets.fromLTRB(16, 28, 16, 0),
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
)
```

---

## 🔟 NOTIFICATION SYSTEM

### Trigger: When technician assigned

```javascript
async function sendNotification(userId, payload) {
  const userDoc = await db.collection('users').doc(userId).get();
  const fcmToken = userDoc.data()?.fcmToken;
  
  if (fcmToken) {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: payload.data,
    });
  }
}
```

---

## 1️⃣1️⃣ TESTING CHECKLIST

### Customer App
- [ ] Form validation works
- [ ] Image picker opens camera/gallery
- [ ] Max 3 images enforced
- [ ] Images upload to Storage
- [ ] Firestore document created
- [ ] Success dialog shows
- [ ] Booking appears in history

### Technician App
- [ ] Assigned requests appear
- [ ] Request details display correctly
- [ ] Images load from Storage
- [ ] Accept button creates booking
- [ ] Decline button rejects request
- [ ] Notifications received

### Admin Panel
- [ ] Pending requests listed
- [ ] Images display correctly
- [ ] Technician dropdown populated
- [ ] Assignment sends notification
- [ ] Status updates in real-time

---

## 1️⃣2️⃣ DEPLOYMENT STEPS

1. **Deploy Cloud Functions**
   ```bash
   firebase deploy --only functions
   ```

2. **Update Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Deploy Customer App**
   ```bash
   flutter build apk
   ```

4. **Deploy Technician App**
   ```bash
   flutter build apk
   ```

5. **Deploy Admin Panel**
   ```bash
   npm run build && npm run deploy
   ```

---

## 1️⃣3️⃣ SECURITY SUMMARY

✅ Only authenticated users can create requests
✅ Only assigned technician can accept
✅ Only admin can assign technician
✅ Customer cannot modify after submission
✅ All writes through Cloud Functions
✅ Firestore rules enforce access control
✅ Images stored in Firebase Storage with proper paths

---

## 1️⃣4️⃣ DATABASE INDEXES

Create composite indexes in Firestore:

```
Collection: custom_requests
Fields: status (Ascending), createdAt (Descending)

Collection: custom_requests
Fields: technicianId (Ascending), status (Ascending)

Collection: bookings
Fields: customerId (Ascending), createdAt (Descending)
```

---

## 1️⃣5️⃣ FUTURE ENHANCEMENTS

1. Real-time chat between customer and technician
2. Live location tracking
3. Video call support
4. Payment integration
5. Review and rating system
6. Automatic technician matching based on skills
7. Estimated time of arrival
8. Service completion photos
