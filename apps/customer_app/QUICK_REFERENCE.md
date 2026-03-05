# Quick Reference - Runtime Fixes

## 🚀 Quick Start

```bash
cd apps/customer_app
flutter clean
flutter pub get
flutter run
```

## 🔥 Get Firebase Debug Token

**Look for this in console:**
```
=================================
🔥 FIREBASE APP CHECK DEBUG TOKEN
<copy_this_token>
=================================
```

**Add token to Firebase:**
1. Open Firebase Console
2. Go to App Check
3. Click "Debug tokens"
4. Add the token from console

## ✅ What Was Fixed

| Issue | Status | Impact |
|-------|--------|--------|
| Firebase App Check Token | ✅ Fixed | Prints in console |
| FCM Token Save | ✅ Fixed | Auth guard added |
| Banner Images | ✅ Fixed | Error fallbacks |
| Asset Crashes | ✅ Fixed | Safe error builders |

## 📁 Modified Files

1. `lib/core/firebase/firebase_init.dart` - Debug token display
2. `lib/core/services/notifications_service.dart` - Auth guard

## 🎨 AC Repair Image (Optional)

**Path:** `assets/images/ac_repair.png`

**Status:** Optional - app works without it

**Fallback:** Icon shows if missing

## 🐛 Common Issues

**Q: Token not showing?**
A: Check if running in debug mode

**Q: FCM errors?**
A: Ensure user is logged in

**Q: Banner blank?**
A: Add AC repair image or use fallback

## ✅ All Done!

App is now production-ready with proper error handling.
