# Deploy Cloud Functions

## Prerequisites
1. Firebase CLI installed: `npm install -g firebase-tools`
2. Logged in: `firebase login`
3. Project selected: `firebase use homefix-project-id`

## Install Dependencies
```powershell
cd C:\Users\yash\projects\homefix\backend\functions
npm install
```

## Deploy Functions
```powershell
cd C:\Users\yash\projects\homefix\backend
firebase deploy --only functions
```

## Deploy Specific Functions (Faster)
```powershell
# Deploy only FCM token functions
firebase deploy --only functions:saveFcmToken,functions:removeFcmToken,functions:sendNotificationToUser

# Deploy notification management functions
firebase deploy --only functions:markNotificationRead,functions:markAllNotificationsRead,functions:deleteNotificationCallable,functions:deleteAllNotificationsCallable
```

## Test FCM Token Locally (Emulator)
```powershell
cd C:\Users\yash\projects\homefix\backend
firebase emulators:start --only functions
```

## Verify Deployment
After deployment, check Firebase Console:
1. Go to Firebase Console > Functions
2. Verify these functions are deployed:
   - saveFcmToken
   - removeFcmToken
   - sendNotificationToUser
   - markNotificationRead
   - markAllNotificationsRead
   - deleteNotificationCallable
   - deleteAllNotificationsCallable

## Troubleshooting

### Error: "Cannot find module"
```powershell
cd C:\Users\yash\projects\homefix\backend\functions
npm install
```

### Error: "Not authenticated"
```powershell
firebase login
```

### Error: "No project selected"
```powershell
firebase use --add
# Select your project from the list
```
