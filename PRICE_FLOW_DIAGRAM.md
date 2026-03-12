# Price Flow Diagram - No Taxes/Fees

```
┌─────────────────────────────────────────────────────────────────────┐
│                    FIRESTORE (SOURCE OF TRUTH)                      │
│                                                                     │
│  Collection: technician_services                                    │
│  Document: service123                                               │
│  {                                                                  │
│    "id": "service123",                                              │
│    "title": "AC Repair",                                            │
│    "price": 500,           ← SOURCE OF TRUTH                        │
│    "status": "approved"                                             │
│  }                                                                  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 1: ADD TO CART                              │
│                                                                     │
│  File: service_details_screen.dart                                  │
│                                                                     │
│  final itemPrice = service.price;        // ₹500                    │
│  final finalPrice = itemPrice;           // ₹500 (NO TAX)          │
│                                                                     │
│  CartItem(                                                          │
│    price: 500,                                                      │
│    quantity: 1,                                                     │
│    totalPrice: 500,                      // price × quantity        │
│    finalPriceSnapshot: 500               // AUDIT TRAIL            │
│  )                                                                  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 2: CART TOTAL                               │
│                                                                     │
│  File: cart_provider.dart                                           │
│                                                                     │
│  double get totalAmount {                                           │
│    return items.fold(0.0, (sum, item) => sum + item.totalPrice);   │
│  }                                                                  │
│                                                                     │
│  Result: ₹500                                                       │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 3: CHECKOUT CALCULATION                     │
│                                                                     │
│  File: checkout_provider.dart                                       │
│                                                                     │
│  double get subtotal => items.fold(...);  // ₹500                   │
│  double get taxes => 0.0;                 // ₹0 ✅ NO TAX          │
│  double get grandTotal => subtotal;       // ₹500 ✅               │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 4: CHECKOUT UI DISPLAY                      │
│                                                                     │
│  File: checkout_screen.dart                                         │
│                                                                     │
│  ┌─────────────────────────────────────┐                           │
│  │  Price Breakdown                    │                           │
│  │                                     │                           │
│  │  Subtotal              ₹500         │                           │
│  │  ────────────────────────────       │                           │
│  │  Total Amount          ₹500         │                           │
│  └─────────────────────────────────────┘                           │
│                                                                     │
│  ❌ REMOVED: Taxes & Fee (5%)  ₹25                                 │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 5: BOOKING PAYLOAD                          │
│                                                                     │
│  File: checkout_screen.dart → booking_provider.dart                 │
│                                                                     │
│  await bookingProvider.createBookingRequest(                        │
│    serviceId: "service123",                                         │
│    technicianId: "tech456",                                         │
│    price: 500,                          // checkout.grandTotal      │
│    ...                                                              │
│  );                                                                 │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 6: FRONTEND VALIDATION                      │
│                                                                     │
│  File: booking_provider.dart                                        │
│                                                                     │
│  // Re-fetch service from Firestore                                 │
│  final serviceDoc = await db                                        │
│    .collection('technician_services')                               │
│    .doc(serviceId)                                                  │
│    .get();                                                          │
│                                                                     │
│  final storedPrice = serviceDoc.data()['price'];  // ₹500           │
│                                                                     │
│  // Validate price within 5% tolerance                              │
│  if (abs(price - storedPrice) > storedPrice * 0.05) {               │
│    throw Exception('Price mismatch');                               │
│  }                                                                  │
│                                                                     │
│  ✅ Validation passed: 500 == 500                                   │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 7: CLOUD FUNCTION CALL                      │
│                                                                     │
│  File: booking_service.dart                                         │
│                                                                     │
│  final callable = functions.httpsCallable('createBookingRequest');  │
│  final result = await callable.call({                               │
│    'serviceId': 'service123',                                       │
│    'technicianId': 'tech456',                                       │
│    'price': 500,                                                    │
│    ...                                                              │
│  });                                                                │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 8: BACKEND VALIDATION                       │
│                                                                     │
│  File: functions/src/booking/new_booking_flow.ts                    │
│                                                                     │
│  // Re-fetch service from Firestore                                 │
│  const serviceDoc = await db                                        │
│    .collection('technician_services')                               │
│    .doc(serviceId)                                                  │
│    .get();                                                          │
│                                                                     │
│  const expectedPrice = serviceDoc.data().price;  // ₹500            │
│                                                                     │
│  // Validate exact match (±₹1 tolerance)                            │
│  const priceDiff = Math.abs(price - expectedPrice);                 │
│  if (priceDiff > 1) {                                               │
│    throw new HttpsError('Price mismatch');                          │
│  }                                                                  │
│                                                                     │
│  ✅ Validation passed: |500 - 500| = 0 ≤ 1                          │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 9: BOOKING CREATED                          │
│                                                                     │
│  Collection: bookings                                               │
│  Document: booking789                                               │
│  {                                                                  │
│    "bookingId": "booking789",                                       │
│    "serviceId": "service123",                                       │
│    "technicianId": "tech456",                                       │
│    "customerId": "customer101",                                     │
│    "price": 500,                        ← FINAL PRICE               │
│    "finalAmount": 500,                  ← AMOUNT TO CHARGE          │
│    "finalPriceSnapshot": 500,           ← AUDIT TRAIL               │
│    "status": "pending_admin_review",                                │
│    "paymentStatus": "pending",                                      │
│    "createdAt": "2026-03-11T10:00:00Z"                              │
│  }                                                                  │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                    STEP 10: PAYMENT                                 │
│                                                                     │
│  Customer pays: ₹500                                                │
│  Technician receives: ₹500 (minus platform commission)              │
│                                                                     │
│  ✅ NO HIDDEN FEES                                                  │
│  ✅ NO TAXES                                                        │
│  ✅ TRANSPARENT PRICING                                             │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🔒 Security Checkpoints

```
┌─────────────────────────────────────────────────────────────────────┐
│  CHECKPOINT 1: Service Fetch                                        │
│  ✅ Price fetched from Firestore (source of truth)                  │
│  ✅ Service status must be "approved"                               │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  CHECKPOINT 2: Cart Item Creation                                   │
│  ✅ Price = service.price (no markup)                               │
│  ✅ finalPriceSnapshot stored for audit                             │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  CHECKPOINT 3: Frontend Validation                                  │
│  ✅ Re-fetch service before booking                                 │
│  ✅ Validate price within 5% tolerance                              │
│  ✅ Check service still approved                                    │
└─────────────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│  CHECKPOINT 4: Backend Validation                                   │
│  ✅ Re-fetch service from Firestore                                 │
│  ✅ Validate exact price match (±₹1)                                │
│  ✅ Check service status = "approved"                               │
│  ✅ Check technician active & approved                              │
│  ✅ Rate limiting (10 bookings/hour)                                │
│  ✅ Idempotency check                                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 🚫 What Cannot Happen

❌ Client cannot add tax  
❌ Client cannot modify price  
❌ Client cannot bypass validation  
❌ Price cannot be higher than service price  
❌ Price cannot be lower than service price (±₹1)  
❌ Deleted services cannot be booked  
❌ Inactive technicians cannot receive bookings  

---

## ✅ What Is Guaranteed

✅ Price = Service price (no hidden fees)  
✅ Price validated at 4 checkpoints  
✅ Audit trail maintained (finalPriceSnapshot)  
✅ Source of truth: Firestore  
✅ Transparent pricing for customers  
✅ Fair pricing for technicians  

---

**Status:** ✅ PRODUCTION READY
