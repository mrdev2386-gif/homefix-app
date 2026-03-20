@echo off
echo ========================================
echo Firebase Configuration Fix Script
echo ========================================
echo.

echo STEP 1: Package Name Verification
echo applicationId: com.homefix.technician
echo Status: VERIFIED ✓
echo.

echo STEP 2: Current SHA Certificates
echo SHA-1:   93:DD:67:69:CA:54:7B:67:52:1A:7C:66:F1:E1:CA:1C:D2:72:29:97
echo SHA-256: 93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
echo.

echo STEP 3: Firebase Console Actions Required
echo ========================================
echo 1. Go to: https://console.firebase.google.com/project/homefix-aa42d/settings/general
echo 2. Select: Android app (com.homefix.technician)
echo 3. Click: "Add fingerprint"
echo 4. ADD SHA-256: 93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
echo 5. Download NEW google-services.json
echo 6. Replace: apps/technician_app/android/app/google-services.json
echo.

echo STEP 4: Clean Installation
echo ========================================
echo Run these commands after updating google-services.json:
echo.
echo adb uninstall com.homefix.technician
echo cd c:\Users\yash\projects\homefix\apps\technician_app
echo flutter clean
echo flutter pub get
echo flutter run
echo.

echo EXPECTED RESULT:
echo - No DEVELOPER_ERROR
echo - Google Play services verified
echo - Firebase Functions auth context working
echo - No UNAUTHENTICATED errors
echo.

pause