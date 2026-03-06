# Firestore CollectionGroup Query Architecture

## 📊 Collection Structure

```
firestore/
└── technicians/
    ├── {technicianId1}/
    │   └── services/
    │       ├── {serviceId1}
    │       ├── {serviceId2}
    │       └── {serviceId3}
    ├── {technicianId2}/
    │   └── services/
    │       ├── {serviceId4}
    │       └── {serviceId5}
    └── {technicianId3}/
        └── services/
            └── {serviceId6}
```

---

## 🔍 Query Flow

### Admin Panel Query

```
┌─────────────────────────────────────────────────────────┐
│                    ADMIN PANEL                          │
│                  /services page                         │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ 1. Execute Query
                      ▼
┌─────────────────────────────────────────────────────────┐
│  query(                                                 │
│    collectionGroup(db, 'services'),                     │
│    orderBy('createdAt', 'desc')                         │
│  )                                                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ 2. Firestore Index Lookup
                      ▼
┌─────────────────────────────────────────────────────────┐
│              FIRESTORE INDEX                            │
│  services (COLLECTION_GROUP)                            │
│  - createdAt DESC                                       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ 3. Return Results
                      ▼
┌─────────────────────────────────────────────────────────┐
│  [                                                      │
│    {id: 'svc6', technicianId: 'tech3', ...},           │
│    {id: 'svc5', technicianId: 'tech2', ...},           │
│    {id: 'svc4', technicianId: 'tech2', ...},           │
│    {id: 'svc3', technicianId: 'tech1', ...},           │
│    {id: 'svc2', technicianId: 'tech1', ...},           │
│    {id: 'svc1', technicianId: 'tech1', ...}            │
│  ]                                                      │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ 4. Client-Side Filtering
                      ▼
┌─────────────────────────────────────────────────────────┐
│  Filter by:                                             │
│  - Status (pending/approved/rejected/disabled)          │
│  - Category                                             │
│  - Search (title/technician name)                       │
└─────────────────────┬───────────────────────────────────┘
                      │
                      │ 5. Display
                      ▼
┌─────────────────────────────────────────────────────────┐
│              SERVICES TABLE                             │
│  [Approve] [Reject] [Disable] [Delete]                 │
└─────────────────────────────────────────────────────────┘
```

---

## 🔧 TechnicianId Extraction

### Document Path Structure
```
technicians/{technicianId}/services/{serviceId}
```

### Extraction Logic
```typescript
const pathParts = doc.ref.path.split('/');
// pathParts = ['technicians', 'tech123', 'services', 'svc456']

const technicianId = pathParts[1];
// technicianId = 'tech123'
```

### Result
```typescript
{
  id: 'svc456',
  technicianId: 'tech123',  // ✅ Extracted from path
  title: 'AC Repair Service',
  status: 'pending',
  ...
}
```

---

## 📋 Index Configuration

### Index 1: Basic Ordering
```json
{
  "collectionGroup": "services",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```
**Used by:** Admin panel main query

---

### Index 2: Status + Ordering
```json
{
  "collectionGroup": "services",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {"fieldPath": "status", "order": "ASCENDING"},
    {"fieldPath": "createdAt", "order": "DESCENDING"}
  ]
}
```
**Used by:** Customer app (future) - approved services only

---

### Index 3: Category + Status
```json
{
  "collectionGroup": "services",
  "queryScope": "COLLECTION_GROUP",
  "fields": [
    {"fieldPath": "categoryId", "order": "ASCENDING"},
    {"fieldPath": "status", "order": "ASCENDING"}
  ]
}
```
**Used by:** Category-filtered services (future)

---

## 🎯 Query Patterns

### Pattern 1: All Services (Admin)
```typescript
query(
  collectionGroup(db, 'services'),
  orderBy('createdAt', 'desc')
)
```
**Returns:** All services from all technicians, newest first

---

### Pattern 2: Approved Services (Customer - Future)
```typescript
query(
  collectionGroup(db, 'services'),
  where('status', '==', 'approved'),
  orderBy('createdAt', 'desc')
)
```
**Returns:** Only approved services, newest first

---

### Pattern 3: Category Services (Customer - Future)
```typescript
query(
  collectionGroup(db, 'services'),
  where('categoryId', '==', 'plumbing'),
  where('status', '==', 'approved')
)
```
**Returns:** Approved plumbing services only

---

## 🔄 Data Flow Diagram

```
┌──────────────┐
│ Technician 1 │
│ Creates      │
│ Service A    │
└──────┬───────┘
       │
       ▼
┌─────────────────────────────────────┐
│ technicians/tech1/services/svcA     │
│ {                                   │
│   title: "AC Repair",               │
│   status: "pending",                │
│   createdAt: 2024-01-15             │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ collectionGroup query
       ▼
┌─────────────────────────────────────┐
│        ADMIN PANEL                  │
│  Reviews all services from          │
│  all technicians                    │
└──────┬──────────────────────────────┘
       │
       │ Admin approves
       ▼
┌─────────────────────────────────────┐
│ technicians/tech1/services/svcA     │
│ {                                   │
│   title: "AC Repair",               │
│   status: "approved", ✅            │
│   createdAt: 2024-01-15             │
│ }                                   │
└──────┬──────────────────────────────┘
       │
       │ Future: Customer app query
       ▼
┌─────────────────────────────────────┐
│      CUSTOMER APP                   │
│  Shows only approved services       │
│  where status == 'approved'         │
└─────────────────────────────────────┘
```

---

## 🚀 Performance Comparison

### Without Index
```
Query Time: ❌ FAILS
Error: "Missing index for collectionGroup query"
```

### With Index
```
Query Time: ✅ <500ms
Index Lookup: O(log n)
Result Set: O(k)
Total: O(log n + k)
```

---

## 🔒 Security Flow

```
┌─────────────────────────────────────┐
│         USER REQUEST                │
└──────┬──────────────────────────────┘
       │
       ▼
┌─────────────────────────────────────┐
│    FIREBASE AUTHENTICATION          │
│    Check: Is user admin?            │
└──────┬──────────────────────────────┘
       │
       ├─ YES ──────────────────────┐
       │                            │
       ▼                            ▼
┌──────────────────┐    ┌──────────────────┐
│  ADMIN PANEL     │    │  FIRESTORE       │
│  Full access     │───▶│  Read all        │
│  Can moderate    │    │  services        │
└──────────────────┘    └──────────────────┘
       │
       └─ NO ───────────────────────┐
                                    │
                                    ▼
                        ┌──────────────────┐
                        │  CUSTOMER APP    │
                        │  Limited access  │
                        │  Only approved   │
                        └──────────────────┘
```

---

## 📊 Index Build Process

```
1. Deploy Command
   firebase deploy --only firestore:indexes
   │
   ▼
2. Firebase Receives Config
   ✓ Parsing firestore.indexes.json
   │
   ▼
3. Index Creation Started
   ⏳ Building index: services (createdAt DESC)
   │
   ▼
4. Index Building (1-5 minutes)
   ⏳ Processing existing documents
   │
   ▼
5. Index Complete
   ✅ Index enabled and ready
   │
   ▼
6. Queries Work
   ✅ collectionGroup queries execute successfully
```

---

## ✅ Verification Steps

```
Step 1: Deploy
┌─────────────────────────────────────┐
│ firebase deploy --only              │
│ firestore:indexes                   │
└─────────────────────────────────────┘
       │
       ▼
Step 2: Check Console
┌─────────────────────────────────────┐
│ Firebase Console → Firestore        │
│ → Indexes → Verify "Enabled"        │
└─────────────────────────────────────┘
       │
       ▼
Step 3: Test Query
┌─────────────────────────────────────┐
│ Admin Panel → /services             │
│ Verify: Services load, no errors    │
└─────────────────────────────────────┘
       │
       ▼
Step 4: Confirm
┌─────────────────────────────────────┐
│ ✅ All services displayed           │
│ ✅ Ordered by date (newest first)   │
│ ✅ No console errors                │
└─────────────────────────────────────┘
```

---

**Status:** ✅ Architecture Complete
**Ready for:** Deployment
**Command:** `firebase deploy --only firestore:indexes`
