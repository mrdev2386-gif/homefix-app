# Technician Services - Quick Deployment Guide

## 🚀 Deploy in 3 Steps

### Step 1: Deploy Cloud Functions (2 minutes)
```powershell
cd C:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions
```

### Step 2: Deploy Firestore Rules (30 seconds)
```powershell
cd C:\Users\yash\projects\homefix
firebase deploy --only firestore:rules
```

### Step 3: Test Technician App (1 minute)
```powershell
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter run
```

---

## ✅ Quick Test

1. Open Technician App
2. Navigate to **Services** tab (bottom nav)
3. Click **"Add Service"** button
4. Fill form:
   - Name: "AC Repair"
   - Category: "AC Repair"
   - Price: 500
   - Image URL: https://images.unsplash.com/photo-1581092160562-40aa08e78837
   - Description: "Professional AC repair service"
5. Click **"Add Service"**
6. ✅ Service appears in list
7. Toggle status (green ↔ gray)
8. Delete service (with confirmation)

---

## 🔍 Verify Customer App Integration

### Query Services (Customer App)
```dart
// Get all active services from all technicians
FirebaseFirestore.instance
  .collectionGroup('services')
  .where('isActive', isEqualTo: true)
  .where('isDeleted', isEqualTo: false)
  .snapshots();
```

---

## 🐛 Troubleshooting

### Issue: "Permission denied"
**Solution:** Deploy Firestore rules (Step 2)

### Issue: "Function not found"
**Solution:** Deploy Cloud Functions (Step 1)

### Issue: Services not appearing
**Solution:** Check isActive == true && isDeleted == false

### Issue: Direct write fails
**Solution:** ✅ This is correct! Use Cloud Functions only

---

## 📊 Architecture Summary

```
┌─────────────────────────────────────────────┐
│         Technician App (Flutter)            │
│  ┌───────────────────────────────────────┐  │
│  │  Services Screen                      │  │
│  │  - Add Service Button                 │  │
│  │  - Service List (Real-time Stream)    │  │
│  │  - Toggle Status                      │  │
│  │  - Delete Service                     │  │
│  └───────────────────────────────────────┘  │
│                    ↓                         │
│  ┌───────────────────────────────────────┐  │
│  │  FunctionsService                     │  │
│  │  - addService()                       │  │
│  │  - updateService()                    │  │
│  │  - toggleServiceStatus()              │  │
│  │  - deleteService()                    │  │
│  └───────────────────────────────────────┘  │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│      Firebase Callable Functions            │
│  ┌───────────────────────────────────────┐  │
│  │  addTechnicianService                 │  │
│  │  updateTechnicianServiceNew           │  │
│  │  toggleTechnicianServiceStatusNew     │  │
│  │  deleteTechnicianServiceNew           │  │
│  └───────────────────────────────────────┘  │
│         ↓ (Server-side validation)          │
└─────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────┐
│           Firestore Database                │
│  technicians/{technicianId}/                │
│    services/{serviceId}                     │
│      - id, name, price, imageUrl            │
│      - category, description                │
│      - isActive, isDeleted                  │
│      - technicianId                         │
│      - createdAt, updatedAt                 │
└─────────────────────────────────────────────┘
                    ↑
┌─────────────────────────────────────────────┐
│         Customer App (Flutter)              │
│  collectionGroup('services')                │
│    .where('isActive', isEqualTo: true)      │
│    .where('isDeleted', isEqualTo: false)    │
└─────────────────────────────────────────────┘
```

---

## 🎯 Key Features

✅ **Single Source of Truth** - technicians/{technicianId}/services/{serviceId}  
✅ **No Direct Writes** - All via Cloud Functions  
✅ **Real-time Updates** - Firestore streams  
✅ **Secure** - Server-side validation  
✅ **Production-Ready** - Error handling, loading states  
✅ **Customer Visible** - Collection group query  
✅ **Soft Delete** - isDeleted flag  
✅ **Theme Consistent** - HomeFix design  

---

## 📞 Need Help?

Contact: **9508322397**

Full documentation: `TECHNICIAN_SERVICES_PRODUCTION_READY.md`
