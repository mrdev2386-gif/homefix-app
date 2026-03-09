# 🏗️ LOCATION SYSTEM ARCHITECTURE

## 📊 DATA FLOW DIAGRAM

```
┌─────────────────────────────────────────────────────────────────┐
│                        CUSTOMER APP                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    MainWrapperScreen                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  1. Check if user document exists                          │ │
│  │  2. Check if primaryAddressId is set                       │ │
│  │  3. Fetch address from subcollection                       │ │
│  │  4. Verify address has state + district                    │ │
│  │  5. If ANY check fails → CompleteLocationScreen            │ │
│  │  6. If ALL checks pass → Allow app access                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    │                   │
                    ▼                   ▼
        ┌───────────────────┐   ┌──────────────────┐
        │ Location Missing  │   │ Location Present │
        └───────────────────┘   └──────────────────┘
                    │                   │
                    ▼                   ▼
    ┌──────────────────────────┐   ┌─────────────────┐
    │ CompleteLocationScreen   │   │   Home Screen   │
    │  - Force location select │   │  - Load services│
    │  - Call Cloud Function   │   │  - Show content │
    │  - Clear cache           │   └─────────────────┘
    │  - Redirect to home      │
    └──────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUD FUNCTION                                │
│                  updateUserProfile()                             │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  1. Validate state + district provided                     │ │
│  │  2. Check if addresses subcollection is empty              │ │
│  │  3. If empty: Create first address with location           │ │
│  │  4. If exists: Update addresses with location              │ │
│  │  5. Set primaryAddressId on customer document              │ │
│  │  6. Set profileCompleted = true                            │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                        FIRESTORE                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  customers/{uid}                                            │ │
│  │    ├─ primaryAddressId: "abc123"  ✅ CRITICAL              │ │
│  │    └─ profileCompleted: true      ✅ REQUIRED              │ │
│  │                                                              │ │
│  │  customers/{uid}/addresses/abc123                           │ │
│  │    ├─ state: "Karnataka"          ✅ CRITICAL              │ │
│  │    ├─ district: "Bangalore Urban" ✅ CRITICAL              │ │
│  │    └─ isDefault: true             ✅ CRITICAL              │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CategoryService                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  getUserLocationCached()                                    │ │
│  │    1. Get customers/{uid}.primaryAddressId                  │ │
│  │    2. Fetch customers/{uid}/addresses/{primaryAddressId}    │ │
│  │    3. Extract state + district from address                 │ │
│  │    4. Cache location to prevent repeated reads              │ │
│  │    5. Return { 'state': state, 'district': district }       │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE QUERY                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  Query: technician_services                                 │ │
│  │    .where('status', isEqualTo: 'approved')                  │ │
│  │    .where('state', isEqualTo: location['state'])            │ │
│  │    .where('district', isEqualTo: location['district'])      │ │
│  │    .orderBy('createdAt', descending: true)                  │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ SERVICES APPEAR │
                    └─────────────────┘
```

---

## 🔄 LOCATION UPDATE FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                    PROFILE SCREEN                                │
│  User clicks "Edit Location"                                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  EditLocationScreen                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  1. Display current location                                │ │
│  │  2. User selects new state + district                       │ │
│  │  3. Call Cloud Function updateUserProfile                   │ │
│  │  4. Clear CategoryService location cache                    │ │
│  │  5. Show success message                                    │ │
│  │  6. Return to profile                                       │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUD FUNCTION                                │
│                  updateUserProfile()                             │
│  Updates address document with new state + district              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                  CategoryService.clearLocationCache()            │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  1. Set _cachedLocation = null                              │ │
│  │  2. Set _locationFetched = false                            │ │
│  │  3. Call notifyListeners()                                  │ │
│  │  4. Trigger service query refresh                           │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │ SERVICES REFRESH    │
                    │ WITH NEW LOCATION   │
                    └─────────────────────┘
```

---

## 🛡️ TECHNICIAN SERVICE CREATION FLOW

```
┌─────────────────────────────────────────────────────────────────┐
│                    TECHNICIAN APP                                │
│  Technician clicks "Create Service"                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUD FUNCTION                                │
│                  addTechnicianService()                          │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  VALIDATION CHECKS:                                         │ │
│  │  1. ✅ Technician authenticated                             │ │
│  │  2. ✅ Service name valid (min 3 chars)                     │ │
│  │  3. ✅ Price > 0                                            │ │
│  │  4. ✅ Image URL provided                                   │ │
│  │  5. ✅ Category provided                                    │ │
│  │  6. ✅ Technician profile exists                            │ │
│  │  7. ✅ Profile completion = 100%                            │ │
│  │  8. ✅ Technician status = 'approved'                       │ │
│  │  9. ✅ Technician has state                                 │ │
│  │  10. ✅ Technician has district                             │ │
│  │                                                              │ │
│  │  IF ANY CHECK FAILS → Reject with error message             │ │
│  │  IF ALL CHECKS PASS → Create service                        │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    SERVICE DOCUMENT                              │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  technician_services/{serviceId}                            │ │
│  │    ├─ name: "AC Repair"                                     │ │
│  │    ├─ price: 500                                            │ │
│  │    ├─ category: "Home Appliances"                           │ │
│  │    ├─ state: "Karnataka"        ✅ SERVER-INJECTED          │ │
│  │    ├─ district: "Bangalore"     ✅ SERVER-INJECTED          │ │
│  │    ├─ technicianId: "xyz123"                                │ │
│  │    ├─ status: "pending"         ✅ AWAITS ADMIN APPROVAL    │ │
│  │    └─ isActive: false            ✅ INACTIVE UNTIL APPROVED │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  ADMIN APPROVAL     │
                    │  status: 'approved' │
                    │  isActive: true     │
                    └─────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │ VISIBLE TO          │
                    │ CUSTOMERS IN        │
                    │ SAME LOCATION       │
                    └─────────────────────┘
```

---

## 🔍 VALIDATION LAYERS

```
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 1: CLIENT-SIDE                          │
│  MainWrapperScreen checks on every app launch                    │
│  - Validates primaryAddressId exists                             │
│  - Validates address document exists                             │
│  - Validates address has state + district                        │
│  - Redirects to CompleteLocationScreen if validation fails       │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 2: SERVER-SIDE                          │
│  Cloud Functions validate before writes                          │
│  - updateUserProfile creates address with location               │
│  - addTechnicianService validates technician location            │
│  - Server-injects state/district into service documents          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 3: QUERY-LEVEL                          │
│  CategoryService requires location for queries                   │
│  - Returns empty array if location is null                       │
│  - Filters services by state + district                          │
│  - Caches location to prevent repeated reads                     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    LAYER 4: CACHE-LEVEL                          │
│  Location cache cleared on all updates                           │
│  - After signup location selection                               │
│  - After profile location edit                                   │
│  - After address creation/update                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 🎯 COMPLETE SYSTEM ARCHITECTURE

```
┌─────────────────────────────────────────────────────────────────┐
│                        CUSTOMER APP                              │
│  ┌────────────────┐  ┌────────────────┐  ┌──────────────────┐  │
│  │ MainWrapper    │  │ Complete       │  │ EditLocation     │  │
│  │ Screen         │→ │ Location       │  │ Screen           │  │
│  │ (Validation)   │  │ Screen         │  │ (Update)         │  │
│  └────────────────┘  └────────────────┘  └──────────────────┘  │
│           │                  │                     │             │
│           └──────────────────┴─────────────────────┘             │
│                              │                                   │
└──────────────────────────────┼───────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CLOUD FUNCTIONS                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  updateUserProfile()                                        │ │
│  │  - Creates address with state/district                      │ │
│  │  - Sets primaryAddressId                                    │ │
│  │  - Normalizes location data                                 │ │
│  └────────────────────────────────────────────────────────────┘ │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  addTechnicianService()                                     │ │
│  │  - Validates technician location                            │ │
│  │  - Server-injects state/district                            │ │
│  │  - Validates profile completion                             │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                        FIRESTORE                                 │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  customers/{uid}                                            │ │
│  │    ├─ primaryAddressId ✅                                   │ │
│  │    └─ profileCompleted ✅                                   │ │
│  │                                                              │ │
│  │  customers/{uid}/addresses/{id}                             │ │
│  │    ├─ state ✅                                              │ │
│  │    ├─ district ✅                                           │ │
│  │    └─ isDefault ✅                                          │ │
│  │                                                              │ │
│  │  technician_services/{id}                                   │ │
│  │    ├─ state ✅                                              │ │
│  │    ├─ district ✅                                           │ │
│  │    ├─ status ✅                                             │ │
│  │    └─ isActive ✅                                           │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
┌─────────────────────────────────────────────────────────────────┐
│                    CategoryService                               │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │  1. Get location from address subcollection                 │ │
│  │  2. Cache location to prevent repeated reads                │ │
│  │  3. Query services filtered by location                     │ │
│  │  4. Return services to UI                                   │ │
│  └────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────┘
                               │
                               ▼
                    ┌─────────────────────┐
                    │   SERVICES APPEAR   │
                    │   IN CUSTOMER APP   │
                    └─────────────────────┘
```

---

## ✅ SYSTEM GUARANTEES

1. **No customer can access app without location** ✅
2. **No technician can create service without location** ✅
3. **All services have state/district fields** ✅
4. **All addresses have state/district fields** ✅
5. **Location cache cleared on all updates** ✅
6. **Services refresh immediately without app restart** ✅
7. **Future users cannot bypass location selection** ✅
8. **System is production-ready and maintainable** ✅
