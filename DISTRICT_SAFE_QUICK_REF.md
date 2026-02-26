# District-Safe Services - Quick Reference

## 🚀 Deploy (2 minutes)

```powershell
# 1. Deploy Functions
cd C:\Users\yash\projects\homefix\functions
npm run build
firebase deploy --only functions

# 2. Test
cd C:\Users\yash\projects\homefix\apps\technician_app
flutter run
```

---

## ✅ Quick Test

1. Open Technician App → Services tab
2. Click "Add Service"
3. Fill form (image REQUIRED)
4. Submit
5. ✅ Check Firestore: `district` field auto-added
6. ✅ Service card shows district and rating

---

## 🔍 Verify District Injection

### Firestore Console
```
technicians/{techId}/services/{serviceId}
{
  "name": "AC Repair",
  "price": 500,
  "imageUrl": "https://...",
  "district": "Mumbai",        ← AUTO-INJECTED
  "averageRating": 0,          ← DEFAULT
  "totalReviews": 0,           ← DEFAULT
  "isActive": true,
  ...
}
```

---

## 📱 Customer App Query

```dart
// CRITICAL: Filter by district
FirebaseFirestore.instance
  .collectionGroup('services')
  .where('isActive', isEqualTo: true)
  .where('isDeleted', isEqualTo: false)
  .where('district', isEqualTo: customerDistrict)
  .snapshots();
```

---

## 🎯 Key Features

✅ **District Auto-Injected** - From technician profile  
✅ **Image Required** - Cannot submit without image  
✅ **Rating-Ready** - averageRating & totalReviews fields  
✅ **District-Filtered** - Customers see only same district  
✅ **Protected Fields** - Cannot update district/ratings  

---

## 🔒 Security

### Protected (Cannot Update)
- ❌ district
- ❌ technicianId
- ❌ averageRating
- ❌ totalReviews

### Allowed Updates
- ✅ name
- ✅ price
- ✅ imageUrl
- ✅ category
- ✅ description

---

## 🐛 Common Issues

### "Your profile must have a district set"
**Fix:** Update technician profile with district

### Services not showing in customer app
**Check:**
1. Districts match exactly
2. isActive == true
3. isDeleted == false
4. Firestore index created

### Image validation failing
**Check:**
1. URL starts with "http"
2. URL not empty
3. Valid image URL

---

## 📊 Testing Matrix

| Scenario | Expected Result |
|----------|----------------|
| Same district | ✅ Visible |
| Different district | ❌ Hidden |
| No district | ❌ Creation fails |
| Toggle OFF | ❌ Disappears |
| Toggle ON | ✅ Reappears |

---

## 📞 Need Help?

Contact: **9508322397**

Full docs:
- `DISTRICT_SAFE_DEPLOYMENT.md`
- `CUSTOMER_APP_DISTRICT_SERVICES.md`
