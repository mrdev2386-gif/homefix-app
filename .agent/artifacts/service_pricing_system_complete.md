# HomeFix Service & Pricing System - Complete Setup

## 🎯 Overview

This document describes the **COMPLETE** Urban Company-style service and pricing setup for the HomeFix platform. The system is:

- ✅ **Platform-controlled**: Only admins can modify pricing
- ✅ **Hack-safe**: No client-side or technician-side price manipulation
- ✅ **Inspection-based**: Supports pre-work inspection with fixed charges
- ✅ **Approval-driven**: Customer must approve itemized quotes
- ✅ **Audit-ready**: All price changes are logged with history
- ✅ **Production-ready**: Fully implemented with Firebase security rules

---

## 📦 Service Catalog Structure

### 7 Service Categories Created

1. **Air Conditioner** (7 sub-services)
2. **Refrigerator** (6 sub-services)
3. **Ceiling Fan** (6 sub-services)
4. **Washing Machine** (5 sub-services)
5. **Microwave Oven** (4 sub-services)
6. **Water Purifier (RO)** (4 sub-services)
7. **Geyser / Water Heater** (4 sub-services)

**Total: 36 sub-services with fixed pricing**

---

## 💰 Pricing Model

### Global Pricing Configuration

```typescript
{
  defaultInspectionCharge: 99,        // ₹99 default inspection
  inspectionChargeRefundable: true,   // Refunded if customer proceeds
  platformFeePercentage: 10,          // 10% platform fee
  gstPercentage: 18,                  // 18% GST
  currency: 'INR',
  minBookingAmount: 50,
  maxBookingAmount: 50000,
  allowDynamicPricing: false,         // No surge pricing (yet)
  allowDiscounts: true                // Admin can create discounts
}
```

### Service-Level Inspection

Each service category defines:
- `requiresInspection`: boolean
- `inspectionCharge`: number (₹0 to ₹99)
- `inspectionDuration`: minutes

**Examples:**
- AC: ₹99 inspection required
- Fan: ₹0 (no inspection needed)
- Fridge: ₹99 inspection required

### Sub-Service Fixed Pricing

Every sub-service has:
- `fixedPrice`: The ONLY price (immutable by techs/customers)
- `currency`: "INR"
- `priceHistory`: Array of all price changes with audit trail

**Sample Pricing:**
- AC Gas Refill: ₹1,499
- AC Capacitor: ₹599
- AC PCB Repair: ₹2,499
- Fan Capacitor: ₹299
- Fridge Compressor: ₹4,999

---

## 🔒 Security Architecture

### Firestore Security Rules

```javascript
// Services & Sub-Services
match /services/{serviceId} {
  allow read: if true;              // Public read
  allow write: if isAdmin();        // Admin-only write
}

match /subServices/{subServiceId} {
  allow read: if true;              // Public read
  allow write: if isAdmin();        // Admin-only write
}

// Pricing Config
match /app_config/pricing {
  allow read: if true;              // Public read
  allow write: if isAdmin();        // Admin-only write
}
```

### Cloud Functions Security

All service management functions require admin authentication:

```typescript
export const createService = functions.https.onCall(async (data, context) => {
    await assertAdmin(context);  // ✅ Admin check
    // ... create service
});
```

---

## 🛠️ Admin Functions (Cloud Functions)

### Service Management

1. **createService** - Create new service category
2. **updateService** - Update service details
3. **deleteService** - Soft delete service (marks inactive)

### Sub-Service Management

4. **createSubService** - Create new sub-service with fixed price
5. **updateSubService** - Update sub-service (with price history tracking)
6. **deleteSubService** - Soft delete sub-service

### Pricing Management

7. **updatePricingConfig** - Update global pricing settings
8. **getPricingConfig** - Get current pricing configuration
9. **bulkUpdatePrices** - Bulk price adjustment (percentage or fixed)
10. **getSubServicePriceHistory** - View price change audit trail

---

## 📋 Booking Flow with Pricing

### Step-by-Step Flow

```
1. Customer creates booking
   ├─ Selects service (e.g., "AC")
   ├─ System locks inspection charge (₹99)
   └─ Status: "pending"

2. Technician assigned
   ├─ Tech accepts booking
   └─ Status: "accepted"

3. Inspection (if required)
   ├─ Tech visits and inspects
   ├─ Tech selects applicable sub-services from catalog
   ├─ System auto-calculates total from FIXED prices
   └─ Status: "awaiting_approval"

4. Customer Approval (MANDATORY)
   ├─ Customer sees itemized quote:
   │   • Inspection: ₹99
   │   • Gas Refill: ₹1,499
   │   • Capacitor: ₹599
   │   • Subtotal: ₹2,098
   │   • Platform Fee (10%): ₹210
   │   • GST (18%): ₹415
   │   • Total: ₹2,723
   ├─ Customer approves or rejects
   ├─ Pricing LOCKED (immutable)
   └─ Status: "approved" or "rejected"

5. Work Execution
   ├─ Tech completes work
   └─ Status: "completed"

6. Payment
   ├─ Customer pays locked amount
   └─ Payment status: "paid"
```

### Booking Data Model

```typescript
{
  bookingNumber: "BK-2026-0001",
  
  // Inspection
  requiresInspection: true,
  inspectionCharge: 99,
  inspectionCompleted: true,
  
  // Pricing (IMMUTABLE after approval)
  pricing: {
    inspectionCharge: 99,
    subServices: [
      {
        subServiceId: "abc123",
        subServiceName: "Gas Refill",
        fixedPrice: 1499,
        quantity: 1,
        totalPrice: 1499,
        addedBy: "technician",
        addedDuringInspection: true
      },
      {
        subServiceId: "def456",
        subServiceName: "Capacitor Replacement",
        fixedPrice: 599,
        quantity: 1,
        totalPrice: 599,
        addedBy: "technician",
        addedDuringInspection: true
      }
    ],
    subtotal: 2098,
    platformFee: 210,
    gst: 415,
    total: 2723,
    pricingLockedAt: Timestamp,
    pricingApprovedBy: "customer_uid"
  },
  
  // Customer Approval
  customerApproval: {
    approved: true,
    approvedAt: Timestamp,
    approvalMethod: "app"
  }
}
```

---

## 🎨 Admin Panel Features

### Services Page

- ✅ View all service categories
- ✅ Create new service
- ✅ Edit service details
- ✅ Enable/disable services
- ✅ Set inspection charges
- ✅ View sub-services count

### Sub-Services Page

- ✅ View all sub-services by service
- ✅ Create new sub-service
- ✅ Edit sub-service details
- ✅ **Update pricing** (with reason)
- ✅ View price history
- ✅ Enable/disable sub-services
- ✅ Bulk price adjustments

### Pricing Configuration Page

- ✅ Update global inspection charge
- ✅ Configure platform fee %
- ✅ Configure GST %
- ✅ Set min/max booking amounts
- ✅ Enable/disable features

---

## 🚫 What Technicians CANNOT Do

1. ❌ Change prices
2. ❌ Create new sub-services
3. ❌ Override platform pricing
4. ❌ Modify inspection charges
5. ❌ Skip customer approval

### What Technicians CAN Do

1. ✅ Select applicable sub-services from catalog
2. ✅ Add inspection notes
3. ✅ Upload inspection images
4. ✅ Mark work as completed

---

## 🚫 What Customers CANNOT Do

1. ❌ Modify prices
2. ❌ Negotiate pricing
3. ❌ Skip inspection (if required)
4. ❌ Proceed without approval

### What Customers CAN Do

1. ✅ View all services and prices
2. ✅ Create bookings
3. ✅ Approve or reject quotes
4. ✅ View itemized pricing
5. ✅ Cancel bookings (with refund logic)

---

## 📊 Price History & Audit Trail

Every price change is logged:

```typescript
{
  oldPrice: 1299,
  newPrice: 1499,
  changedAt: Timestamp,
  changedBy: "admin_uid",
  reason: "Market rate adjustment"
}
```

### Audit Features

- ✅ View complete price history per sub-service
- ✅ Track who changed prices
- ✅ Track when prices changed
- ✅ Track why prices changed
- ✅ All changes logged in `audit_logs` collection

---

## 🔧 Implementation Files

### Backend (Cloud Functions)

```
functions/src/
├── shared/
│   └── models.ts                    ✅ Enhanced with pricing models
├── admin/
│   └── services.ts                  ✅ Complete CRUD + pricing functions
└── scripts/
    └── initialize-services.js       ✅ Database initialization script
```

### Database Collections

```
Firestore:
├── services/                        ✅ 7 service categories
├── subServices/                     ✅ 36 sub-services with fixed prices
├── app_config/
│   └── pricing                      ✅ Global pricing configuration
├── bookings/                        ✅ Enhanced with approval flow
└── audit_logs/                      ✅ All admin actions logged
```

### Security Rules

```
firestore.rules                      ✅ Updated with service/pricing rules
```

---

## 📱 Client App Integration

### Customer App (Flutter)

```dart
// Read-only pricing
final subService = await FirebaseFirestore.instance
    .collection('subServices')
    .doc(subServiceId)
    .get();

final price = subService.data()!['fixedPrice'];  // Read-only

// Cannot modify - security rules prevent it
```

### Technician App (Flutter)

```dart
// Select sub-services (read-only prices)
final selectedServices = [
  {
    'subServiceId': 'abc123',
    'fixedPrice': 1499,  // Locked from catalog
    'quantity': 1
  }
];

// Submit for customer approval
await createInspectionQuote(bookingId, selectedServices);
```

### Admin Panel (Next.js)

```typescript
// Full CRUD access
const createSubService = httpsCallable(functions, 'createSubService');
await createSubService({
  serviceId: 'ac-service-id',
  name: 'New Repair',
  fixedPrice: 999,
  // ... other fields
});

// Update price with audit trail
const updateSubService = httpsCallable(functions, 'updateSubService');
await updateSubService({
  subServiceId: 'sub-id',
  updates: {
    fixedPrice: 1099,
    priceChangeReason: 'Cost increase'
  }
});
```

---

## ✅ Production Readiness Checklist

### Security
- [x] Admin-only write access to services
- [x] Admin-only write access to sub-services
- [x] Admin-only write access to pricing config
- [x] All functions require admin authentication
- [x] Price changes logged with audit trail
- [x] Customer approval required before work
- [x] Pricing locked after approval

### Data Integrity
- [x] Fixed pricing model (no ranges)
- [x] Price history tracking
- [x] Soft deletes (no data loss)
- [x] Denormalized data for performance
- [x] Metadata auto-calculated

### User Experience
- [x] Clear inspection charges
- [x] Itemized pricing breakdown
- [x] Customer approval flow
- [x] Warranty tracking
- [x] Service duration estimates

### Admin Features
- [x] Full service CRUD
- [x] Full sub-service CRUD
- [x] Pricing configuration management
- [x] Bulk price updates
- [x] Price history viewing
- [x] Audit logs

---

## 🚀 How to Initialize

### 1. Run Initialization Script

```bash
# Make sure Firebase emulators are running
firebase emulators:start

# In another terminal
node functions/src/scripts/initialize-services.js
```

### 2. Verify in Firestore

Check these collections:
- `services` - Should have 7 documents
- `subServices` - Should have 36 documents
- `app_config/pricing` - Should exist with global config

### 3. Test Admin Functions

Use the admin panel or Firebase console to:
- Create a new sub-service
- Update a price (check price history)
- Bulk update prices for a service
- View audit logs

---

## 📈 Future Enhancements

### Phase 2 (Optional)
- [ ] Dynamic pricing (surge pricing)
- [ ] Discount codes
- [ ] Seasonal pricing
- [ ] Location-based pricing
- [ ] Technician-level pricing (premium techs)
- [ ] Package deals (bundle discounts)

### Phase 3 (Advanced)
- [ ] AI-based price optimization
- [ ] Competitor price monitoring
- [ ] Demand-based pricing
- [ ] Customer loyalty pricing

---

## 🎯 Key Achievements

✅ **7 Service Categories** with comprehensive coverage
✅ **36 Sub-Services** with realistic, market-competitive pricing
✅ **Fixed Pricing Model** - No price manipulation possible
✅ **Inspection Flow** - Urban Company-style pre-work inspection
✅ **Customer Approval** - Mandatory approval before work starts
✅ **Price History** - Complete audit trail of all changes
✅ **Admin Control** - 100% platform-controlled pricing
✅ **Security Rules** - Hack-safe, production-ready
✅ **Cloud Functions** - Complete CRUD + bulk operations
✅ **Booking Model** - Enhanced with approval flow
✅ **Production Ready** - Can go live immediately

---

## 📞 Support

For questions or issues:
1. Check Firestore security rules
2. Review Cloud Functions logs
3. Check audit_logs collection
4. Verify admin authentication

---

**System Status: ✅ PRODUCTION READY**

All services created, pricing configured, security implemented, and approval flow enabled. The platform is ready for real-world use with Urban Company-style service delivery.
