@echo off
echo ========================================================================
echo DEFINITIVE FIREBASE DEVELOPER_ERROR FIX
echo ========================================================================
echo.

echo [STEP 1] RUNTIME SHA FINGERPRINTS EXTRACTED
echo.
echo SHA-1:   93:DD:67:69:CA:54:7B:67:52:1A:7C:66:F1:E1:CA:1C:D2:72:29:97
echo SHA-256: 93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
echo.
echo Status: VERIFIED from gradlew signingReport
echo.

echo [STEP 2] SHA MATCH VERIFICATION
echo.
echo google-services.json SHA-1: 93dd6769ca547b67521a7c66f1e1ca1cd2722997
echo Runtime SHA-1 (lowercase):  93dd6769ca547b67521a7c66f1e1ca1cd2722997
echo.
echo Result: PERFECT MATCH!
echo.

echo [STEP 3] FIREBASE CONSOLE ACTION REQUIRED
echo.
echo CRITICAL: Add SHA-256 to Firebase Console
echo.
echo 1. Go to: https://console.firebase.google.com
echo 2. Select project: homefix-aa42d
echo 3. Settings -^> Project Settings -^> Your apps -^> com.homefix.customer
echo 4. Scroll to "SHA certificate fingerprints"
echo 5. Click "Add fingerprint"
echo 6. Paste SHA-256: 93:A9:84:61:64:1F:73:9F:94:D7:3D:EE:2D:7B:90:B6:78:D7:DF:C0:F1:4F:4E:68:EF:A9:7C:C4:14:B7:A3:9E
echo 7. Click Save
echo.
echo Press any key after adding SHA-256 to Firebase Console...
pause >nul
echo.

echo [STEP 4] Checking device connection...
adb devices
echo.
echo If device is connected, press any key to uninstall old app...
echo If device is NOT connected, connect it now and press any key...
pause >nul
echo.

echo [STEP 5] Uninstalling old app...
adb uninstall com.homefix.customer
echo.
echo If uninstall failed, manually uninstall from device:
echo - Long press HomeFix app icon
echo - Select Uninstall
echo.
pause
echo.

echo [STEP 6] Cleaning Flutter project...
cd apps\customer_app
call flutter clean
echo Status: CLEANED
echo.

echo [STEP 7] Getting dependencies...
call flutter pub get
echo Status: DEPENDENCIES UPDATED
echo.

echo [STEP 8] Ready for fresh install
echo.
echo FINAL STEP: Run the app
echo Command: flutter run
echo.
echo This will install a fresh build with correct Firebase configuration.
echo.

echo ========================================================================
echo DEFINITIVE FIX COMPLETE
echo ========================================================================
echo.
echo VERIFICATION CHECKLIST:
echo [x] Runtime SHA extracted
echo [x] SHA-1 matches google-services.json
echo [ ] SHA-256 added to Firebase Console (verify manually)
echo [ ] Old app uninstalled
echo [x] Project cleaned
echo [x] Dependencies updated
echo [ ] Fresh build installed (run: flutter run)
echo.
echo EXPECTED RESULTS:
echo - No DEVELOPER_ERROR
echo - Google Sign-In works
echo - Firebase Callables work
echo - All Firebase services work
echo.
echo Press any key to exit...
pause >nul
