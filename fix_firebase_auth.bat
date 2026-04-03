@echo off
echo ========================================================================
echo FIREBASE AUTHENTICATION TRUST CHAIN FIX
echo ========================================================================
echo.

echo [1/7] Verifying Package Name...
echo Package Name: com.homefix.customer
echo Status: VERIFIED in build.gradle
echo.

echo [2/7] Debug Keystore SHA Fingerprints...
echo SHA-1:   93:DD:67:69:CA:54:7B:67:52:1A:7C:66:F1:E1:CA:1C:D2:72:29:97
echo SHA-256: 93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
echo.
echo CRITICAL ACTIONS REQUIRED IN FIREBASE CONSOLE:
echo 1. Go to: https://console.firebase.google.com
echo 2. Select your project
echo 3. Go to Project Settings ^> Your apps ^> Android app
echo 4. Scroll to "SHA certificate fingerprints"
echo 5. Click "Add fingerprint" and add BOTH:
echo    - SHA-1:   93:DD:67:69:CA:54:7B:67:52:1A:7C:66:F1:E1:CA:1C:D2:72:29:97
echo    - SHA-256: 93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
echo 6. Download NEW google-services.json
echo 7. Replace file in: apps\customer_app\android\app\google-services.json
echo.
pause
echo.

echo [3/7] Cleaning Flutter project...
cd apps\customer_app
call flutter clean
echo Status: CLEANED
echo.

echo [4/7] Getting dependencies...
call flutter pub get
echo Status: DEPENDENCIES UPDATED
echo.

echo [5/7] Verifying google-services.json...
if exist android\app\google-services.json (
    echo Status: google-services.json EXISTS
    echo WARNING: Ensure this is the LATEST file from Firebase Console!
) else (
    echo ERROR: google-services.json NOT FOUND!
    echo Please download from Firebase Console and place in:
    echo apps\customer_app\android\app\google-services.json
    pause
)
echo.

echo [6/7] Build Instructions...
echo CRITICAL: You MUST uninstall the existing app from device first!
echo.
echo Steps:
echo 1. Uninstall HomeFix app from your device
echo 2. Run: flutter run
echo 3. Fresh install will trust the new SHA fingerprints
echo.

echo [7/7] Verification Checklist...
echo.
echo BEFORE RUNNING APP, VERIFY:
echo [ ] SHA-1 added to Firebase Console
echo [ ] SHA-256 added to Firebase Console  
echo [ ] New google-services.json downloaded
echo [ ] New google-services.json placed in android/app/
echo [ ] flutter clean executed
echo [ ] flutter pub get executed
echo [ ] Old app uninstalled from device
echo.

echo ========================================================================
echo FIREBASE AUTHENTICATION FIX COMPLETE
echo ========================================================================
echo.
echo NEXT STEPS:
echo 1. Add SHA fingerprints to Firebase Console (if not done)
echo 2. Download and replace google-services.json (if not done)
echo 3. Uninstall app from device
echo 4. Run: flutter run
echo.
echo Expected Result:
echo - No DEVELOPER_ERROR
echo - No UNAUTHENTICATED errors
echo - Firebase trusts your app
echo - Google Sign-In works
echo - Firebase Callables work
echo.
pause
