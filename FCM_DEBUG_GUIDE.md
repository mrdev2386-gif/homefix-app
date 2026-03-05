# FCM Token Debug Guide

## Issue
The NotificationsService calls `saveFcmToken` Cloud Function, but it doesn't exist yet.

## Solution

### Step 1: Deploy Cloud Functions
```powershell
cd C:\Users\yash\projects\homefix\backend
npm install
firebase deploy --only functions:saveFcmToken,functions:removeFcmToken,functions:sendNotificationToUser
```

### Step 2: Test FCM Token in App

Add debug screen to your app temporarily:

1. Import the debug screen in your profile or settings screen:
```dart
import 'package:customer_app/features/debug/fcm_token_debug_screen.dart';
```

2. Add a button to navigate to debug screen:
```dart
ListTile(
  leading: Icon(Icons.bug_report),
  title: Text('FCM Debug'),
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => FcmTokenDebugScreen()),
  ),
)
```

### Step 3: Test Flow

1. Run the app
2. Navigate to FCM Debug screen
3. Click "Get FCM Token" - should show token
4. Click "Save Token" - should save to Firestore
5. Click "Test Notification" - should receive notification

### Step 4: Verify in Firebase Console

1. Go to Firestore Database
2. Check `customers/{userId}` document
3. Should see fields:
   - `fcmToken`: "your-token-here"
   - `fcmPlatform`: "android"
   - `fcmUpdatedAt`: timestamp

### Troubleshooting

**Error: "Cloud Function not found"**
- Deploy functions first (Step 1)
- Wait 1-2 minutes after deployment

**Error: "Permission denied"**
- Check Firestore rules allow token updates
- Ensure user is authenticated

**Token is null**
- Check `google-services.json` is in place
- Verify FCM is enabled in Firebase Console
- Check Android permissions in manifest

**Notification not received**
- Verify token is saved in Firestore
- Check notification channel is created
- Test with Firebase Console > Cloud Messaging > Send test message

## Quick Commands

```powershell
# Install dependencies
cd C:\Users\yash\projects\homefix\backend
npm install

# Deploy all FCM functions
firebase deploy --only functions:saveFcmToken,functions:removeFcmToken,functions:sendNotificationToUser,functions:markNotificationRead,functions:markAllNotificationsRead

# View function logs
firebase functions:log --only saveFcmToken

# Test locally with emulator
firebase emulators:start --only functions
```

## Expected Logs

When working correctly, you should see:
```
✅ User ID: abc123...
✅ FCM Token: dXYz...
✅ Token saved: {success: true}
✅ Notification sent: {success: true}
```
