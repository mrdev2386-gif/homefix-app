# FCM Token Debugging - Complete Setup

## What Was Done

### 1. Added Missing Cloud Functions (backend/functions/src/index.ts)
- ✅ `saveFcmToken` - Saves FCM token to user document
- ✅ `removeFcmToken` - Removes token on logout
- ✅ `sendNotificationToUser` - Sends push notification
- ✅ `markNotificationRead` - Marks notification as read
- ✅ `markAllNotificationsRead` - Marks all as read
- ✅ `deleteNotificationCallable` - Deletes notification
- ✅ `deleteAllNotificationsCallable` - Deletes all notifications

### 2. Created Debug Screen (apps/customer_app/lib/features/debug/fcm_token_debug_screen.dart)
- View current FCM token
- Test token save functionality
- Send test notifications
- Real-time logs

### 3. Created Documentation
- `FCM_DEBUG_GUIDE.md` - Step-by-step debugging guide
- `backend/DEPLOY_FUNCTIONS.md` - Deployment instructions

## Next Steps

### Deploy Functions (Required)
```powershell
cd C:\Users\yash\projects\homefix\backend
npm install
firebase deploy --only functions
```

### Test in App
1. Add debug screen to profile/settings
2. Navigate to FCM Debug screen
3. Test token save and notifications

### Verify
- Check Firestore for `fcmToken` field in user document
- Test receiving notifications
- Check function logs: `firebase functions:log`

## Files Modified/Created

### Modified
- `backend/functions/src/index.ts` - Added FCM functions

### Created
- `apps/customer_app/lib/features/debug/fcm_token_debug_screen.dart`
- `FCM_DEBUG_GUIDE.md`
- `backend/DEPLOY_FUNCTIONS.md`
- `FCM_TOKEN_SETUP_SUMMARY.md` (this file)

## How It Works

1. **App starts** → NotificationsService.initialize()
2. **User logs in** → Gets FCM token
3. **Token received** → Calls saveFcmToken Cloud Function
4. **Function saves** → Token stored in Firestore (customers/{uid})
5. **Notifications** → Sent using stored token

## Debugging Flow

```
App → Get Token → Save to Firestore → Test Notification
 ↓         ↓              ↓                    ↓
FCM    Firebase    Cloud Function      Push Received
```

## Common Issues & Fixes

| Issue | Fix |
|-------|-----|
| Function not found | Deploy functions first |
| Token is null | Check google-services.json |
| Permission denied | Check Firestore rules |
| No notification | Verify token saved in Firestore |

## Quick Test Commands

```powershell
# Deploy
cd C:\Users\yash\projects\homefix\backend
firebase deploy --only functions:saveFcmToken,functions:sendNotificationToUser

# View logs
firebase functions:log --only saveFcmToken

# Run app
cd C:\Users\yash\projects\homefix\apps\customer_app
flutter run
```
