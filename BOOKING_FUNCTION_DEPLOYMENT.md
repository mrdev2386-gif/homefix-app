# Booking Function Deployment Guide

## Quick Deploy

```bash
cd functions
npm run build
firebase deploy --only functions:createBookingRequest
```

## Service Lookup - FINAL FIX

**File:** `functions/src/booking/new_booking_flow.ts`

### Service Lookup (ONLY SOURCE)
```typescript
const serviceRef = db.collection('technician_services').doc(serviceId);
const serviceDoc = await serviceRef.get();

if (!serviceDoc.exists) {
    console.error('SERVICE LOOKUP FAILED', serviceId);
    throw new functions.https.HttpsError('not-found', 'Service not found');
}

const serviceData = serviceDoc.data();
console.log('BOOKING DEBUG serviceData:', serviceData);

if (serviceData.status !== 'approved') {
    throw new functions.https.HttpsError('failed-precondition', 'Service is not available');
}
```

### Technician Validation
```typescript
console.log('BOOKING DEBUG technicianId:', technicianId);

const techDoc = await db.collection('technicians').doc(technicianId).get();

if (!techDoc.exists) {
    throw new functions.https.HttpsError('not-found', 'Technician not found');
}

const techData = techDoc.data()!;

if (techData.isActive === false || (techData.status !== 'approved' && techData.status !== 'active')) {
    throw new functions.https.HttpsError('failed-precondition', 'Technician is not available at this time');
}
```

## Debug Logs

When booking is created, check Firebase logs:

```
BOOKING DEBUG serviceId: r4PVcWsFWK2f0JjBDO2r
BOOKING DEBUG serviceData: { status: 'approved', name: 'AC Repair', price: 500 }
BOOKING DEBUG technicianId: eys3wx7tL1chVVCgowbuo7GAZG72
```

## Verification

1. **Service exists in Firestore:**
   - Path: `technician_services/r4PVcWsFWK2f0JjBDO2r`
   - Status: `approved`

2. **Technician exists in Firestore:**
   - Path: `technicians/eys3wx7tL1chVVCgowbuo7GAZG72`
   - Status: `approved` or `active`
   - isActive: `true`

3. **Booking created:**
   - Path: `bookings/{bookingId}`
   - Status: `pending_admin_review`

## Removed Code

All references to these paths have been removed:
- ❌ `technicians/{technicianId}/technician_services/{serviceId}`
- ❌ `categories/{categoryId}/services/{serviceId}`

## Single Source of Truth

✅ **ONLY:** `technician_services/{serviceId}`
