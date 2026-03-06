# HomeFix Admin Panel - Visual Module Overview

## 🏗️ System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                   HOMEFIX ADMIN PANEL                       │
│                  (Next.js + TypeScript)                     │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      │ Firestore SDK
                      ▼
┌─────────────────────────────────────────────────────────────┐
│                  FIRESTORE DATABASE                         │
├─────────────────────────────────────────────────────────────┤
│  bookings  │  customers  │  technicians  │  reviews         │
│  custom_requests  │  technicianApplications  │  disputes    │
│  services (collectionGroup)                                 │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Module Flow Diagram

```
┌──────────────┐
│  DASHBOARD   │ ← Entry Point
└──────┬───────┘
       │
       ├─────────────────────────────────────────────┐
       │                                             │
       ▼                                             ▼
┌──────────────┐                            ┌──────────────┐
│   BOOKINGS   │                            │  TECHNICIANS │
│              │                            │              │
│ • View All   │                            │ • View All   │
│ • Approve    │                            │ • Profiles   │
│ • Reject     │                            │ • Suspend    │
│ • Assign     │                            │ • Activate   │
└──────┬───────┘                            └──────┬───────┘
       │                                           │
       ▼                                           ▼
┌──────────────┐                            ┌──────────────┐
│   CUSTOM     │                            │ APPLICATIONS │
│  REQUESTS    │                            │              │
│              │                            │ • Review     │
│ • Assign     │                            │ • Approve    │
│ • Reject     │                            │ • Reject     │
│ • Resolve    │                            │ • Create     │
└──────┬───────┘                            └──────┬───────┘
       │                                           │
       ▼                                           ▼
┌──────────────┐                            ┌──────────────┐
│  CUSTOMERS   │                            │   SERVICES   │
│              │                            │              │
│ • View All   │                            │ • Moderate   │
│ • Profiles   │                            │ • Approve    │
│ • Suspend    │                            │ • Reject     │
│ • Activate   │                            │ • Disable    │
└──────┬───────┘                            └──────┬───────┘
       │                                           │
       ▼                                           ▼
┌──────────────┐                            ┌──────────────┐
│   REVIEWS    │                            │   DISPUTES   │
│              │                            │              │
│ • View All   │                            │ • Resolve    │
│ • Hide       │                            │ • Refund     │
│ • Flag       │                            │ • Close      │
│ • Delete     │                            │ • Review     │
└──────────────┘                            └──────────────┘
```

---

## 🔄 Booking Workflow

```
Customer Creates Booking
         │
         ▼
┌─────────────────┐
│ pending_admin   │ ← Admin reviews
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│approved│ │ rejected │
└───┬────┘ └──────────┘
    │
    ▼
┌──────────────────┐
│ Assign Technician│
└────────┬─────────┘
         │
         ▼
┌────────────────────┐
│technician_assigned │
└────────┬───────────┘
         │
         ▼
┌─────────────┐
│ in_progress │
└──────┬──────┘
       │
       ▼
┌───────────┐
│ completed │
└───────────┘
```

---

## 🛠️ Service Moderation Flow

```
Technician Creates Service
         │
         ▼
┌─────────────┐
│   pending   │ ← Admin reviews
└──────┬──────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌────────┐ ┌──────────┐
│approved│ │ rejected │
└───┬────┘ └──────────┘
    │
    ▼
┌──────────────────┐
│ Visible to       │
│ Customers        │
└──────────────────┘
    │
    ▼
┌──────────────────┐
│ Can be disabled  │
│ by admin         │
└──────────────────┘
```

---

## 👷 Technician Application Flow

```
Applicant Submits Application
         │
         ▼
┌─────────────────┐
│     pending     │ ← Admin reviews
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌────────┐ ┌──────────┐
│approved│ │ rejected │
└───┬────┘ └──────────┘
    │
    ▼
┌──────────────────────┐
│ Create Technician    │
│ Account              │
│ • Set approved=true  │
│ • Record timestamp   │
│ • Record admin ID    │
└──────────────────────┘
    │
    ▼
┌──────────────────────┐
│ Technician Can Login │
│ & Create Services    │
└──────────────────────┘
```

---

## 📝 Custom Request Flow

```
Customer Creates Request
         │
         ▼
┌─────────────┐
│   pending   │ ← Admin reviews
└──────┬──────┘
       │
   ┌───┴───┐
   │       │
   ▼       ▼
┌────────┐ ┌──────────┐
│assigned│ │ rejected │
└───┬────┘ └──────────┘
    │
    ▼
┌─────────────┐
│ in_progress │
└──────┬──────┘
       │
       ▼
┌──────────┐
│ resolved │
└──────────┘
```

---

## ⚖️ Dispute Resolution Flow

```
Dispute Created
      │
      ▼
┌──────────┐
│   open   │ ← Admin reviews
└─────┬────┘
      │
      ▼
┌────────────────┐
│ under_review   │
└────────┬───────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌──────────┐ ┌────────┐
│ resolved │ │ closed │
└─────┬────┘ └────────┘
      │
      ▼
┌──────────────────┐
│ Optional Refund  │
│ • Credit wallet  │
│ • Create txn     │
│ • Log action     │
└──────────────────┘
```

---

## 🎯 Admin Action Matrix

| Module | View | Approve | Reject | Assign | Suspend | Delete | Other |
|--------|------|---------|--------|--------|---------|--------|-------|
| Bookings | ✅ | ✅ | ✅ | ✅ | - | - | - |
| Custom Requests | ✅ | - | ✅ | ✅ | - | - | Resolve |
| Technicians | ✅ | - | - | - | ✅ | - | Activate |
| Applications | ✅ | ✅ | ✅ | - | - | - | - |
| Customers | ✅ | - | - | - | ✅ | - | Activate |
| Services | ✅ | ✅ | ✅ | - | - | ✅ | Disable |
| Reviews | ✅ | - | - | - | - | ✅ | Hide/Flag |
| Disputes | ✅ | - | - | - | - | - | Resolve/Refund |

---

## 📊 Data Flow Example: Booking Approval

```
┌──────────────┐
│ Admin Panel  │
│ Bookings Page│
└──────┬───────┘
       │
       │ 1. Click "Approve"
       ▼
┌──────────────────┐
│ Confirmation     │
│ Dialog           │
└──────┬───────────┘
       │
       │ 2. Confirm
       ▼
┌──────────────────┐
│ adminApi.        │
│ approveBooking() │
└──────┬───────────┘
       │
       │ 3. Call Cloud Function
       ▼
┌──────────────────┐
│ Cloud Function   │
│ • Verify admin   │
│ • Update status  │
│ • Log action     │
└──────┬───────────┘
       │
       │ 4. Update Firestore
       ▼
┌──────────────────┐
│ bookings/{id}    │
│ status: approved │
│ updatedAt: now() │
└──────┬───────────┘
       │
       │ 5. Refresh UI
       ▼
┌──────────────────┐
│ Admin Panel      │
│ Shows updated    │
│ status           │
└──────────────────┘
```

---

## 🔍 Search & Filter Architecture

```
┌──────────────────────────────────────┐
│         USER INPUT                   │
│  • Search term                       │
│  • Status filter                     │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│    CLIENT-SIDE FILTERING             │
│  • Filter by search term             │
│  • Filter by status                  │
│  • Update results count              │
└──────────┬───────────────────────────┘
           │
           ▼
┌──────────────────────────────────────┐
│    DISPLAY RESULTS                   │
│  • Filtered data                     │
│  • Results count                     │
│  • Empty state if no results         │
└──────────────────────────────────────┘
```

---

## 🎨 UI Component Hierarchy

```
Page Component
├── PageHeader
│   ├── Title
│   └── Description
├── Filters Section
│   ├── Search Input
│   ├── Status Dropdown
│   └── Results Count
├── Data Table
│   ├── Table Header
│   ├── Table Rows
│   │   ├── Data Cells
│   │   └── Action Buttons
│   ├── Loading State
│   └── Empty State
└── Modals
    ├── Details Modal
    ├── Assign Modal
    └── Confirm Dialog
```

---

## 🔒 Security Layers

```
┌─────────────────────────────────────┐
│  Layer 1: Authentication            │
│  • User must be logged in           │
│  • Firebase Auth verification       │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Layer 2: Admin Verification        │
│  • Check admins collection          │
│  • Verify admin role                │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Layer 3: Confirmation Dialogs      │
│  • Confirm destructive actions      │
│  • Require reason for rejections    │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Layer 4: Cloud Functions           │
│  • Server-side validation           │
│  • Secure writes                    │
│  • Audit logging                    │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Layer 5: Firestore Rules           │
│  • Collection-level security        │
│  • Document-level permissions       │
└─────────────────────────────────────┘
```

---

## 📈 Performance Optimization

```
┌─────────────────────────────────────┐
│  Query Optimization                 │
│  • Indexed queries                  │
│  • Limited result sets (100)        │
│  • Proper orderBy usage             │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Client-Side Optimization           │
│  • React state management           │
│  • useEffect cleanup                │
│  • Conditional rendering            │
└──────────┬──────────────────────────┘
           │
           ▼
┌─────────────────────────────────────┐
│  Network Optimization               │
│  • Parallel fetching (Promise.all)  │
│  • Minimal re-fetches               │
│  • Efficient updates                │
└─────────────────────────────────────┘
```

---

## ✅ Module Status Summary

```
┌─────────────────────────────────────────────────────┐
│                MODULE STATUS                        │
├─────────────────────────────────────────────────────┤
│  ✅ Dashboard         - Fully Operational           │
│  ✅ Bookings          - Fully Operational           │
│  ✅ Custom Requests   - Fully Operational           │
│  ✅ Technicians       - Fully Operational           │
│  ✅ Applications      - Fully Operational           │
│  ✅ Customers         - Fully Operational           │
│  ✅ Services          - Fully Operational           │
│  ✅ Reviews           - Fully Operational           │
│  ✅ Disputes          - Fully Operational           │
├─────────────────────────────────────────────────────┤
│  OVERALL STATUS: ✅ PRODUCTION READY                │
└─────────────────────────────────────────────────────┘
```

---

**Status:** ✅ ALL MODULES OPERATIONAL
**Documentation:** Complete
**Ready for:** Production Deployment
