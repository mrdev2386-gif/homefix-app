# 🔒 Firestore Security Rules for Location System

## Required Security Rules

Add these rules to your `firestore.rules` file:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Location address rules
    match /users/{userId}/profile/currentAddress {
      // Allow read only if authenticated user matches document owner
      allow read: if request.auth != null && request.auth.uid == userId;
      
      // Allow write only if:
      // 1. Authenticated user matches document owner
      // 2. Required fields are present
      // 3. Coordinates are valid numbers
      allow write: if request.auth != null 
                   && request.auth.uid == userId
                   && request.resource.data.keys().hasAll([
                        'formattedAddress',
                        'fullAddress', 
                        'latitude',
                        'longitude',
                        'updatedAt'
                      ])
                   && request.resource.data.latitude is number
                   && request.resource.data.longitude is number
                   && request.resource.data.latitude >= -90
                   && request.resource.data.latitude <= 90
                   && request.resource.data.longitude >= -180
                   && request.resource.data.longitude <= 180;
    }
    
    // Prevent access to other profile documents
    match /users/{userId}/profile/{document} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Security Features

### ✅ Authentication Required
- All operations require `request.auth != null`
- User can only access their own data (`request.auth.uid == userId`)

### ✅ Data Validation
- Required fields must be present
- Latitude must be between -90 and 90
- Longitude must be between -180 and 180
- Prevents invalid coordinate injection

### ✅ Prevents Unauthorized Access
- Users cannot read/write other users' locations
- Anonymous users cannot access any location data

## Testing Security Rules

### Test 1: Authenticated User (Should PASS)
```javascript
// User can write their own location
match /users/user123/profile/currentAddress {
  allow write: if request.auth.uid == "user123"
}
```

### Test 2: Different User (Should FAIL)
```javascript
// User cannot write another user's location
match /users/user456/profile/currentAddress {
  allow write: if request.auth.uid == "user123" // DENIED
}
```

### Test 3: Invalid Coordinates (Should FAIL)
```javascript
// Invalid latitude
{
  latitude: 100, // > 90, DENIED
  longitude: 50
}
```

### Test 4: Missing Required Fields (Should FAIL)
```javascript
// Missing required fields
{
  latitude: 24.4833,
  // Missing longitude, formattedAddress, etc. - DENIED
}
```

## Deployment

1. Open Firebase Console
2. Go to Firestore Database → Rules
3. Add the rules above
4. Click "Publish"
5. Test with Firebase Emulator Suite

## Monitoring

Monitor security rule violations:
```bash
firebase firestore:rules:test
```

Check logs for unauthorized access attempts:
- Firebase Console → Firestore → Usage tab
- Look for "Permission Denied" errors
