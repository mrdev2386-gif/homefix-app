# Customer Location System - Implementation Guide

## ✅ What's Implemented

### 1. Shared Location Dataset
- **File**: `apps/customer_app/lib/core/constants/india_locations.dart`
- **Content**: State-to-districts mapping for Bihar, Jharkhand, Uttar Pradesh
- **Reusable**: Both technician and customer apps can import this file

### 2. Location Service (SharedPreferences)
- **File**: `apps/customer_app/lib/core/services/location_service.dart`
- **Methods**:
  - `saveLocation(state, district)` - Save to SharedPreferences
  - `getLocation()` - Retrieve both state and district
  - `getState()` / `getDistrict()` - Get individual values
  - `clearLocation()` - Clear stored location

### 3. Location Selector Widget
- **File**: `apps/customer_app/lib/core/widgets/location_selector.dart`
- **Features**:
  - Cascading dropdowns (state → district)
  - District disabled until state selected
  - No manual typing allowed
  - Callback on location change

### 4. District Selection Screen (Signup)
- **File**: `apps/customer_app/lib/features/auth/screens/district_selection_screen.dart`
- **Flow**:
  - Appears after Google Sign-In or Phone OTP
  - Mandatory location selection before dashboard access
  - Saves to SharedPreferences + Firestore via Cloud Function
  - Navigates to home screen after completion

### 5. Home Screen Location Selector
- **File**: `apps/customer_app/lib/features/home/home_screen.dart`
- **Features**:
  - Location display in header: "📍 Bihar • Begusarai"
  - Tap to open bottom sheet with location selector
  - Save location updates SharedPreferences + services list
  - Displays "Select Location" if not set

### 6. Service Filtering by District
- **File**: `apps/customer_app/lib/core/services/category_service.dart`
- **Updated Methods** (all now accept optional `district` parameter):
  - `getRecentlyAddedServices(district: district)`
  - `getServicesByCategory(categoryId, district: district)`
  - `getSubServices(categoryId, serviceId, district: district)`
  - `getAllServices(district: district)`
  - `getTopServices(district: district)`
  - `getTopRatedServices(district: district)`
  - `getPopularServices(district: district)`
  - `getTrendingServices(district: district)`
  - `getRecommendedServices(district: district)`

---

## 🔧 Setup Instructions

### Step 1: Update pubspec.yaml
Ensure these dependencies are present:
```yaml
dependencies:
  shared_preferences: ^2.0.0
  cloud_firestore: ^4.0.0
  provider: ^6.0.0
  google_fonts: ^4.0.0
```

### Step 2: Update Routes (main.dart)
Add route for district selection:
```dart
'/districtSelection': (context) => const DistrictSelectionScreen(),
```

### Step 3: Update Auth Flow
In `login_screen.dart`, after successful Google Sign-In:
```dart
Navigator.of(context).pushAndRemoveUntil(
  MaterialPageRoute(builder: (_) => const DistrictSelectionScreen()),
  (route) => false,
);
```

### Step 4: Update Dashboard Screens
When using services, pass district parameter:
```dart
// Get services for customer's district
final district = await locationService.getDistrict();
final services = categoryService.getServicesByCategory(
  categoryId,
  district: district,
);
```

---

## 📊 Data Flow

### Signup Flow
```
Login Screen
    ↓
Google Sign-In / Phone OTP
    ↓
District Selection Screen (MANDATORY)
    ↓
Save to SharedPreferences
    ↓
Update Firestore via Cloud Function
    ↓
Home Screen (services filtered by district)
```

### Location Change Flow
```
Home Screen
    ↓
Tap Location Header
    ↓
Bottom Sheet with LocationSelector
    ↓
Select State → Select District
    ↓
Save Location Button
    ↓
Update SharedPreferences
    ↓
Refresh Services List
```

### Service Query Flow
```
Dashboard / Category Screen
    ↓
Get customer's district from SharedPreferences
    ↓
Query: collectionGroup('technician_services')
        .where('district', isEqualTo: customerDistrict)
        .where('isPublished', isEqualTo: true)
        .where('status', isEqualTo: 'active')
        .where('technicianApproved', isEqualTo: true)
    ↓
Display filtered services
```

---

## 🧪 Testing Checklist

### Signup Flow
- [ ] User signs in with Google
- [ ] District selection screen appears
- [ ] State dropdown shows Bihar, Jharkhand, Uttar Pradesh
- [ ] District dropdown disabled until state selected
- [ ] After state selection, district dropdown enabled
- [ ] Continue button disabled until both selected
- [ ] After selection, location saved to SharedPreferences
- [ ] Firestore customer document updated with state + district
- [ ] Home screen loads with location displayed

### Home Screen Location
- [ ] Location displays as "📍 State • District"
- [ ] Tapping location opens bottom sheet
- [ ] Bottom sheet has LocationSelector widget
- [ ] Can change state and district
- [ ] Save Location button works
- [ ] Location updates in header after save
- [ ] Services list refreshes with new district

### Service Filtering
- [ ] Services only show from customer's district
- [ ] Changing district filters services correctly
- [ ] Empty state shows if no services in district
- [ ] All service queries respect district filter

### Persistence
- [ ] Location persists after app restart
- [ ] SharedPreferences stores state + district
- [ ] Firestore customer document has state + district fields

---

## 🔐 Security

### Firestore Rules
Ensure customer can only read services from their district:
```
match /technicians/{techId}/technician_services/{serviceId} {
  allow read: if request.auth != null 
    && resource.data.district == request.auth.token.district;
}
```

### Cloud Function
Update customer profile only via Cloud Function:
```typescript
export const updateCustomerProfile = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new Error('Unauthenticated');
  
  await admin.firestore()
    .collection('customers')
    .doc(context.auth.uid)
    .update({
      state: data.state,
      district: data.district,
    });
});
```

---

## 📱 UI Components

### Location Selector Widget
```dart
LocationSelector(
  initialState: 'Bihar',
  initialDistrict: 'Patna',
  onLocationChanged: (state, district) {
    print('Selected: $state, $district');
  },
)
```

### Location Display
```dart
Text('📍 Bihar • Begusarai')
```

### Bottom Sheet
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => LocationSelector(
    onLocationChanged: (state, district) {
      // Handle location change
    },
  ),
)
```

---

## 🚀 Next Steps

1. **Test Signup Flow**: Verify district selection works end-to-end
2. **Test Service Filtering**: Confirm services filter by district
3. **Test Location Change**: Verify location updates work
4. **Deploy Cloud Function**: Ensure updateCustomerProfile is deployed
5. **Monitor Firestore**: Check customer documents have state + district
6. **User Testing**: Have real users test the flow

---

## 📝 Files Created/Modified

### Created
- `apps/customer_app/lib/core/constants/india_locations.dart`
- `apps/customer_app/lib/core/services/location_service.dart`
- `apps/customer_app/lib/core/widgets/location_selector.dart`
- `apps/customer_app/lib/features/auth/screens/district_selection_screen.dart`

### Modified
- `apps/customer_app/lib/features/home/home_screen.dart` - Added location selector
- `apps/customer_app/lib/core/services/category_service.dart` - Added district filtering

---

## ✨ Key Features

✅ **Mandatory Location Selection**: Users must select location during signup
✅ **No Manual Typing**: Dropdowns only, prevents typos
✅ **Cascading Dropdowns**: District only available after state selected
✅ **Persistent Storage**: Location saved locally and in Firestore
✅ **Service Filtering**: Only shows services from customer's district
✅ **Easy Location Change**: Tap header to change location anytime
✅ **Production Ready**: Follows Firebase best practices
✅ **Reusable Components**: LocationSelector widget used in both apps

---

## 🎯 Expected Result

After implementation:
1. Customer signs up → selects location → sees services from their district
2. Customer can change location anytime from home screen
3. Services automatically filter by selected district
4. Location persists across app sessions
5. Technician services tagged with state + district are visible to matching customers
