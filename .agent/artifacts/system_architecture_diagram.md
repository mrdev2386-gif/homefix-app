# 🏗️ HomeFix Service & Pricing System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         HOMEFIX PLATFORM                                 │
│                   Urban Company-Style Service System                     │
└─────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  CUSTOMER APP    │    │ TECHNICIAN APP   │    │   ADMIN PANEL    │
│   (Flutter)      │    │    (Flutter)     │    │   (Next.js)      │
└────────┬─────────┘    └────────┬─────────┘    └────────┬─────────┘
         │                       │                       │
         │ READ ONLY             │ READ ONLY             │ FULL CONTROL
         │ (Pricing)             │ (Pricing)             │ (All Operations)
         │                       │                       │
         └───────────────────────┴───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   FIRESTORE DATABASE    │
                    │   (Source of Truth)     │
                    └────────────┬────────────┘
                                 │
         ┌───────────────────────┼───────────────────────┐
         │                       │                       │
    ┌────▼─────┐          ┌─────▼──────┐         ┌─────▼──────┐
    │ services │          │ subServices│         │ app_config │
    │  (7)     │          │    (36)    │         │  /pricing  │
    └──────────┘          └────────────┘         └────────────┘
         │                       │                       │
         │ Admin Write Only      │ Admin Write Only      │ Admin Write Only
         │ Public Read           │ Public Read           │ Public Read
         └───────────────────────┴───────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │   CLOUD FUNCTIONS       │
                    │   (Admin Operations)    │
                    └─────────────────────────┘
```

---

## Data Flow Architecture

### 1. Service Creation Flow

```
Admin Panel
    │
    │ createService({ name, slug, category, ... })
    ▼
Cloud Function: createService
    │
    ├─ assertAdmin(context)  ✅ Security Check
    ├─ Validate input
    ├─ Check slug uniqueness
    │
    ▼
Firestore: services/{serviceId}
    │
    ├─ id
    ├─ name, slug, category
    ├─ requiresInspection
    ├─ inspectionCharge
    ├─ metadata { totalSubServices, ... }
    ├─ createdBy, createdAt
    │
    ▼
Audit Log: audit_logs/{logId}
    │
    └─ action: "service_create"
```

### 2. Sub-Service Creation Flow

```
Admin Panel
    │
    │ createSubService({ serviceId, name, fixedPrice, ... })
    ▼
Cloud Function: createSubService
    │
    ├─ assertAdmin(context)  ✅ Security Check
    ├─ Validate input
    ├─ Check parent service exists
    ├─ Check slug uniqueness
    │
    ▼
Firestore: subServices/{subServiceId}
    │
    ├─ id, serviceId, serviceName
    ├─ name, slug, description
    ├─ fixedPrice  ← THE ONLY PRICE
    ├─ currency: "INR"
    ├─ estimatedDuration, warrantyDays
    ├─ requiredTools, skillLevel
    ├─ priceHistory: []
    ├─ metadata { totalBookings, ... }
    ├─ createdBy, createdAt
    │
    ▼
Update Parent Service
    │
    └─ services/{serviceId}.metadata.totalSubServices++
```

### 3. Price Update Flow (with Audit Trail)

```
Admin Panel
    │
    │ updateSubService({ 
    │   subServiceId, 
    │   updates: { fixedPrice: 1599, priceChangeReason: "..." }
    │ })
    ▼
Cloud Function: updateSubService
    │
    ├─ assertAdmin(context)  ✅ Security Check
    ├─ Get current sub-service
    ├─ Detect price change
    │
    ▼
Create Price History Entry
    │
    ├─ oldPrice: 1499
    ├─ newPrice: 1599
    ├─ changedAt: Timestamp
    ├─ changedBy: admin_uid
    ├─ reason: "Market rate adjustment"
    │
    ▼
Update Firestore
    │
    ├─ subServices/{subServiceId}.fixedPrice = 1599
    ├─ subServices/{subServiceId}.priceHistory.push(entry)
    ├─ subServices/{subServiceId}.updatedBy = admin_uid
    │
    ▼
Audit Log
    │
    └─ audit_logs/{logId}
```

---

## Booking Flow with Pricing

### Complete Booking Lifecycle

```
┌─────────────────────────────────────────────────────────────────────┐
│ STEP 1: BOOKING CREATION                                            │
└─────────────────────────────────────────────────────────────────────┘

Customer App
    │
    │ Select Service: "Air Conditioner"
    ▼
Read from Firestore
    │
    ├─ services/ac
    │   ├─ requiresInspection: true
    │   └─ inspectionCharge: 99
    │
    ▼
Create Booking
    │
    └─ bookings/{bookingId}
        ├─ serviceId: "ac"
        ├─ requiresInspection: true
        ├─ inspectionCharge: 99  ← LOCKED
        ├─ pricing: {
        │     inspectionCharge: 99,
        │     subServices: [],
        │     subtotal: 0,
        │     total: 99
        │   }
        └─ status: "pending"

┌─────────────────────────────────────────────────────────────────────┐
│ STEP 2: TECHNICIAN ASSIGNMENT                                       │
└─────────────────────────────────────────────────────────────────────┘

Admin/System
    │
    │ Assign technician
    ▼
Update Booking
    │
    └─ bookings/{bookingId}
        ├─ technicianId: "tech123"
        └─ status: "assigned"

Technician App
    │
    │ Tech accepts
    ▼
Update Booking
    │
    └─ status: "accepted"

┌─────────────────────────────────────────────────────────────────────┐
│ STEP 3: INSPECTION (If Required)                                    │
└─────────────────────────────────────────────────────────────────────┘

Technician App
    │
    │ Start inspection
    ▼
Update Booking
    │
    └─ status: "inspection_in_progress"

Technician inspects appliance
    │
    │ Identifies issues:
    │ - Gas needs refilling
    │ - Capacitor is faulty
    │
    ▼
Read Sub-Services from Firestore (READ ONLY)
    │
    ├─ subServices/gas-refill
    │   └─ fixedPrice: 1499  ← CANNOT MODIFY
    │
    ├─ subServices/capacitor-replacement
    │   └─ fixedPrice: 599   ← CANNOT MODIFY
    │
    ▼
Technician selects sub-services
    │
    └─ Selected: ["gas-refill", "capacitor-replacement"]

Cloud Function: submitInspectionQuote
    │
    ├─ Lock prices from catalog
    ├─ Calculate totals
    │
    ▼
Update Booking
    │
    └─ bookings/{bookingId}
        ├─ inspectionCompleted: true
        ├─ inspectionNotes: "AC not cooling, gas low, capacitor weak"
        ├─ pricing: {
        │     inspectionCharge: 99,
        │     subServices: [
        │       {
        │         subServiceId: "gas-refill",
        │         subServiceName: "Gas Refill",
        │         fixedPrice: 1499,  ← LOCKED FROM CATALOG
        │         quantity: 1,
        │         totalPrice: 1499,
        │         addedBy: "technician",
        │         addedDuringInspection: true
        │       },
        │       {
        │         subServiceId: "capacitor-replacement",
        │         subServiceName: "Capacitor Replacement",
        │         fixedPrice: 599,   ← LOCKED FROM CATALOG
        │         quantity: 1,
        │         totalPrice: 599,
        │         addedBy: "technician",
        │         addedDuringInspection: true
        │       }
        │     ],
        │     subtotal: 2098,  (1499 + 599)
        │     platformFee: 210,  (10% of 2098)
        │     gst: 415,  (18% of 2308)
        │     total: 2723
        │   }
        └─ status: "awaiting_approval"

┌─────────────────────────────────────────────────────────────────────┐
│ STEP 4: CUSTOMER APPROVAL (MANDATORY)                               │
└─────────────────────────────────────────────────────────────────────┘

Customer App
    │
    │ Display itemized quote:
    │
    │ ┌─────────────────────────────────────┐
    │ │ QUOTE BREAKDOWN                     │
    │ ├─────────────────────────────────────┤
    │ │ Inspection Charge        ₹99        │
    │ │ Gas Refill              ₹1,499      │
    │ │ Capacitor Replacement    ₹599       │
    │ ├─────────────────────────────────────┤
    │ │ Subtotal                ₹2,098      │
    │ │ Platform Fee (10%)       ₹210       │
    │ │ GST (18%)                ₹415       │
    │ ├─────────────────────────────────────┤
    │ │ TOTAL                   ₹2,723      │
    │ └─────────────────────────────────────┘
    │
    │ [APPROVE] [REJECT]
    │
    ▼
Customer clicks APPROVE

Cloud Function: approveBookingQuote
    │
    ├─ Validate customer is booking owner
    ├─ Lock pricing (IMMUTABLE)
    │
    ▼
Update Booking
    │
    └─ bookings/{bookingId}
        ├─ customerApproval: {
        │     approved: true,
        │     approvedAt: Timestamp,
        │     approvalMethod: "app"
        │   }
        ├─ pricing: {
        │     ...
        │     pricingLockedAt: Timestamp  ← IMMUTABLE
        │     pricingApprovedBy: "customer_uid"
        │   }
        └─ status: "approved"

┌─────────────────────────────────────────────────────────────────────┐
│ STEP 5: WORK EXECUTION                                              │
└─────────────────────────────────────────────────────────────────────┘

Technician App
    │
    │ Start work
    ▼
Update Booking
    │
    └─ status: "in_progress"

Technician completes each sub-service
    │
    ├─ Mark "Gas Refill" as completed
    ├─ Mark "Capacitor Replacement" as completed
    │
    ▼
Update Booking
    │
    └─ status: "completed"

┌─────────────────────────────────────────────────────────────────────┐
│ STEP 6: PAYMENT                                                     │
└─────────────────────────────────────────────────────────────────────┘

Customer App
    │
    │ Pay ₹2,723  ← LOCKED AMOUNT (cannot be changed)
    ▼
Payment Gateway (Razorpay)
    │
    ▼
Update Booking
    │
    └─ bookings/{bookingId}
        ├─ paymentStatus: "paid"
        ├─ razorpayPaymentId: "pay_xxx"
        └─ completedAt: Timestamp
```

---

## Security Architecture

### Firestore Security Rules

```
┌─────────────────────────────────────────────────────────────────┐
│ FIRESTORE SECURITY RULES                                        │
└─────────────────────────────────────────────────────────────────┘

services/{serviceId}
    │
    ├─ READ:  ✅ Anyone (public catalog)
    └─ WRITE: ✅ Admin only (isAdmin())

subServices/{subServiceId}
    │
    ├─ READ:  ✅ Anyone (public pricing)
    └─ WRITE: ✅ Admin only (isAdmin())

app_config/pricing
    │
    ├─ READ:  ✅ Anyone (public config)
    └─ WRITE: ✅ Admin only (isAdmin())

bookings/{bookingId}
    │
    ├─ READ:  ✅ Customer, Technician, Admin
    └─ WRITE: ❌ NO DIRECT WRITES (Cloud Functions only)
```

### Cloud Functions Security

```
┌─────────────────────────────────────────────────────────────────┐
│ CLOUD FUNCTIONS SECURITY                                        │
└─────────────────────────────────────────────────────────────────┘

Every admin function:
    │
    ├─ Step 1: assertAdmin(context)
    │   └─ Verify context.auth.token.admin === true
    │
    ├─ Step 2: Validate input
    │   └─ Check required fields, types, ranges
    │
    ├─ Step 3: Field whitelisting
    │   └─ Only allow specific fields to be updated
    │
    ├─ Step 4: Perform operation
    │   └─ Create/Update/Delete in Firestore
    │
    └─ Step 5: Log action
        └─ Write to audit_logs collection
```

---

## Price Control Matrix

```
┌──────────────────┬──────────┬──────────────┬──────────┐
│ OPERATION        │ CUSTOMER │ TECHNICIAN   │ ADMIN    │
├──────────────────┼──────────┼──────────────┼──────────┤
│ View Prices      │    ✅    │      ✅      │    ✅    │
│ Create Service   │    ❌    │      ❌      │    ✅    │
│ Update Service   │    ❌    │      ❌      │    ✅    │
│ Delete Service   │    ❌    │      ❌      │    ✅    │
│ Create Sub-Svc   │    ❌    │      ❌      │    ✅    │
│ Update Price     │    ❌    │      ❌      │    ✅    │
│ Delete Sub-Svc   │    ❌    │      ❌      │    ✅    │
│ Bulk Price Adj   │    ❌    │      ❌      │    ✅    │
│ View Price Hist  │    ❌    │      ❌      │    ✅    │
│ Select Sub-Svc   │    ✅    │      ✅      │    ✅    │
│ Approve Quote    │    ✅    │      ❌      │    ✅    │
└──────────────────┴──────────┴──────────────┴──────────┘
```

---

## Audit Trail

```
┌─────────────────────────────────────────────────────────────────┐
│ AUDIT LOGGING                                                   │
└─────────────────────────────────────────────────────────────────┘

Every admin action creates:

audit_logs/{logId}
    │
    ├─ action: "service_create" | "subservice_update" | ...
    ├─ performedBy: admin_uid
    ├─ performedAt: Timestamp
    ├─ targetId: service_id | subservice_id
    ├─ changes: { ... }
    └─ metadata: { ... }

Price changes also create:

subServices/{subServiceId}.priceHistory[]
    │
    ├─ oldPrice: 1499
    ├─ newPrice: 1599
    ├─ changedAt: Timestamp
    ├─ changedBy: admin_uid
    └─ reason: "Market adjustment"
```

---

## System Status

```
┌─────────────────────────────────────────────────────────────────┐
│ ✅ PRODUCTION READY                                             │
├─────────────────────────────────────────────────────────────────┤
│ Services:        7 categories                                   │
│ Sub-Services:    36 with fixed pricing                          │
│ Security:        Admin-only control                             │
│ Inspection:      Configured per service                         │
│ Approval:        Mandatory customer approval                    │
│ Pricing:         Immutable after approval                       │
│ Audit:           Complete history tracking                      │
│ Architecture:    Hack-safe, scalable                            │
└─────────────────────────────────────────────────────────────────┘
```

---

**Architecture Diagram v1.0**
