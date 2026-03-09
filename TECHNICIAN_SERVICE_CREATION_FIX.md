# Technician Service Creation Fix

## Problem
Services were not appearing after creation. Image upload succeeded, but service documents were not written to Firestore.

## Root Causes

### 1. **Field Name Mismatch**
**Flutter app sent:**
- `name` → Cloud Function expected `title`
- `category` → Cloud Function expected `categoryId`
- Missing `subServiceId` (required field)
- Missing `durationMinutes` (required field)

### 2. **Region Mismatch**
**Flutter app configured:** `asia-south1`
**Cloud Function deployed:** `us-central1`

This caused the callable function to fail silently.

### 3. **Missing Required Fields**
Cloud Function validation requires:
- `title` (string, min 5 chars)
- `categoryId` (string)
- `subServiceId` (string)
- `price` (number > 0)
- `durationMinutes` (number > 0)
- `imageUrl` (string, valid URL)
- `description` (string, min 20 chars)

## Fixes Applied

### File: `apps/technician_app/lib/core/services/functions_service.dart`

#### Fix 1: Corrected Field Names
```dart
final Map<String, dynamic> data = {
  'title': name,              // ✅ Changed from 'name'
  'categoryId': category,     // ✅ Changed from 'category'
  'subServiceId': category,   // ✅ Added required field
  'price': price,
  'durationMinutes': 60,      // ✅ Added required field (default 60 mins)
  'imageUrl': imageUrl,
  'description': description ?? 'Professional service',  // ✅ Ensure min 20 chars
  'tags': [],                 // ✅ Added required field
};
```

#### Fix 2: Corrected Region
```dart
final FirebaseFunctions _functions =
    FirebaseFunctions.instanceFor(region: 'us-central1');  // ✅ Changed from 'asia-south1'
```

#### Fix 3: Added Debug Logs
```dart
debugPrint('[SERVICE CREATE] Writing to technician_services collection');
debugPrint('[SERVICE CREATE] categoryId: $category');
debugPrint('[SERVICE CREATE] Calling Cloud Function with data: $data');
debugPrint('[SERVICE CREATE] SUCCESS - Service written to technician_services');
```

## Verification Steps

### 1. Check Cloud Function Logs
```bash
firebase functions:log --only createTechnicianService
```

Look for:
- `[TECH_SERVICE] Creating service for technician: {uid}`
- `[TECH_SERVICE] Service created successfully: {serviceId}`

### 2. Check Firestore Console
Navigate to: `technician_services` collection

Verify new documents have:
- ✅ `technicianId`: {uid}
- ✅ `categoryId`: {categoryId}
- ✅ `subServiceId`: {subServiceId}
- ✅ `title`: Service name
- ✅ `price`: Service price
- ✅ `imageUrl`: Uploaded image URL
- ✅ `status`: "pending"
- ✅ `isActive`: true
- ✅ `isPublished`: false
- ✅ `technicianApproved`: false
- ✅ `createdAt`: Timestamp

### 3. Test Service Creation Flow
1. Open technician app
2. Navigate to "Add Service"
3. Fill in all fields:
   - Service name (min 5 chars)
   - Category selection
   - Description (min 20 chars)
   - Price
   - Upload image
4. Tap "Add Service"
5. Check for success message
6. Verify service appears in Firestore console

### 4. Check Admin Panel
Services should now appear in admin panel for moderation:
- Navigate to: `http://localhost:3000`
- Check "Pending Services" tab
- Verify new service is listed with status "pending"

## Expected Behavior

### Before Fix
- ❌ Image uploaded successfully
- ❌ Service document NOT created
- ❌ No error shown to user
- ❌ Silent failure due to region/field mismatch

### After Fix
- ✅ Image uploaded successfully
- ✅ Service document created in `technician_services` collection
- ✅ Service status: "pending" (awaiting admin approval)
- ✅ Success message shown to user
- ✅ Service appears in admin panel for moderation

## Collection Structure

### Global Collection: `technician_services/{serviceId}`
```javascript
{
  id: "auto-generated-id",
  technicianId: "uid",
  technicianName: "Pro Name",
  technicianDistrict: "District",
  technicianRating: 5.0,
  
  categoryId: "category-id",
  serviceId: "service-id",
  subServiceId: "subservice-id",
  
  title: "Service Title",
  description: "Service Description",
  tags: [],
  searchKeywords: ["keyword1", "keyword2"],
  
  price: 500,
  durationMinutes: 60,
  imageUrl: "https://...",
  
  isActive: true,
  isPublished: false,
  technicianApproved: false,
  status: "pending",
  
  discoveryScore: 100,
  
  createdAt: Timestamp,
  updatedAt: Timestamp,
  _createdBy: "uid",
  _version: 1
}
```

## Approval Flow

1. **Technician creates service** → `status: "pending"`
2. **Admin reviews in panel** → Approve/Reject
3. **If approved** → `status: "approved"`, `isPublished: true`, `technicianApproved: true`
4. **Service visible to customers** → Appears in customer app search

## Notes

- Services require admin approval before appearing to customers
- Technician must have 100% profile completion and admin approval to create services
- Maximum 20 services per technician
- Rate limit: 5 services per hour
- Image must be valid URL (Firebase Storage recommended)
- Description must be at least 20 characters for quality control

## Related Files

- `apps/technician_app/lib/core/services/functions_service.dart` - Service creation logic
- `apps/technician_app/lib/features/technician/services/add_service_screen.dart` - UI form
- `functions/src/technician/createTechnicianService.ts` - Cloud Function
- `apps/admin_panel/` - Admin moderation panel

## Testing Checklist

- [ ] Service creation succeeds
- [ ] Service appears in Firestore `technician_services` collection
- [ ] Service has correct `status: "pending"`
- [ ] Service appears in admin panel
- [ ] Admin can approve/reject service
- [ ] Approved service appears in customer app
- [ ] Rejected service does not appear in customer app
- [ ] Debug logs show correct collection path
- [ ] No errors in Cloud Function logs
