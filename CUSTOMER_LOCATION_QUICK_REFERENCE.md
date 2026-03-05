# Customer Location System - Quick Reference

## 📁 Files Overview

| File | Purpose | Status |
|------|---------|--------|
| `india_locations.dart` | State/district mapping | ✅ Created |
| `location_service.dart` | SharedPreferences storage | ✅ Created |
| `location_selector.dart` | Reusable dropdown widget | ✅ Created |
| `district_selection_screen.dart` | Signup location screen | ✅ Created |
| `home_screen.dart` | Location display + selector | ✅ Updated |
| `category_service.dart` | District filtering | ✅ Updated |

---

## 🚀 Quick Start

### 1. Save Location
```dart
final locationService = LocationService();
await locationService.saveLocation('Bihar', 'Patna');
```

### 2. Get Location
```dart
final location = await locationService.getLocation();
final state = location['state'];
final district = location['district'];
```

### 3. Filter Services by District
```dart
final district = await locationService.getDistrict();
final services = categoryService.getServicesByCategory(
  categoryId,
  district: district,
);
```

### 4. Show Location Selector
```dart
LocationSelector(
  initialState: 'Bihar',
  initialDistrict: 'Patna',
  onLocationChanged: (state, district) {
    print('$state, $district');
  },
)
```

---

## 🔄 Data Flow

### Signup
```
Login → Google Sign-In → District Selection → Save → Home
```

### Location Change
```
Home Header → Bottom Sheet → Select Location → Save → Refresh
```

### Service Query
```
Get District → Query Services → Filter by District → Display
```

---

## 📊 Firestore Structure

### Customer Document
```json
{
  "uid": "user123",
  "state": "Bihar",
  "district": "Patna",
  "email": "user@example.com"
}
```

### Technician Service Document
```json
{
  "id": "service123",
  "state": "Bihar",
  "district": "Patna",
  "isPublished": true,
  "technicianApproved": true,
  "status": "active"
}
```

---

## 🧪 Testing

### Test Signup
1. Sign in with Google
2. Select state → district
3. Verify SharedPreferences saved
4. Verify Firestore updated
5. Verify home screen shows location

### Test Location Change
1. Tap location header
2. Select new state → district
3. Verify services refresh
4. Verify location persists

### Test Service Filtering
1. Create services in different districts
2. Change customer location
3. Verify only matching services show

---

## 🔑 Key Methods

### LocationService
```dart
saveLocation(String state, String district)
getLocation() → Map<String, String?>
getState() → String?
getDistrict() → String?
clearLocation()
```

### CategoryService (with district)
```dart
getServicesByCategory(categoryId, {district})
getRecentlyAddedServices({district})
getTopServices({district})
getPopularServices({district})
getTrendingServices({district})
getRecommendedServices({district})
```

---

## 🎯 Common Tasks

### Get Customer's District
```dart
final locationService = LocationService();
final district = await locationService.getDistrict();
```

### Load Services for District
```dart
final categoryService = CategoryService();
final district = await locationService.getDistrict();
final services = categoryService.getServicesByCategory(
  categoryId,
  district: district,
);
```

### Update Location
```dart
final locationService = LocationService();
await locationService.saveLocation('Jharkhand', 'Ranchi');
```

### Clear Location
```dart
await locationService.clearLocation();
```

---

## ⚠️ Important Notes

1. **Mandatory Selection**: Users MUST select location during signup
2. **No Manual Typing**: Only dropdowns allowed
3. **District Dependent**: District dropdown only works after state selected
4. **Persistent**: Location saved locally and in Firestore
5. **Filtering**: All service queries should include district parameter
6. **Cloud Function**: Location updates must go through Cloud Function

---

## 🔐 Security Checklist

- [ ] Cloud Function validates user authentication
- [ ] Firestore rules restrict customer data access
- [ ] Services filtered by district on client side
- [ ] Location stored securely in SharedPreferences
- [ ] No hardcoded locations in code

---

## 📱 UI Components

### Location Display
```dart
Text('📍 Bihar • Patna')
```

### Location Selector
```dart
LocationSelector(
  onLocationChanged: (state, district) {},
)
```

### Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => LocationSelector(...),
)
```

---

## 🚨 Troubleshooting

### Location not saving
- Check SharedPreferences is initialized
- Verify Cloud Function is deployed
- Check Firestore rules allow write

### Services not filtering
- Verify district parameter passed to query
- Check technician services have district field
- Verify customer has district set

### Location not persisting
- Check SharedPreferences keys: `customer_state`, `customer_district`
- Verify app doesn't clear SharedPreferences on logout
- Check Firestore customer document

---

## ✅ Implementation Status

**Customer App**: ✅ 100% COMPLETE
- Location dataset: ✅
- Location service: ✅
- Location selector widget: ✅
- District selection screen: ✅
- Home screen integration: ✅
- Service filtering: ✅

**Ready for Testing**: ✅ YES
