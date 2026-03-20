@echo off
echo ========================================
echo FIREBASE APP CHECK SDK UPDATE FIX
echo ========================================

cd apps\technician_app

echo Step 1: Cleaning Flutter project...
call flutter clean
if %errorlevel% neq 0 (
    echo Flutter clean failed!
    pause
    exit /b 1
)

echo Step 2: Upgrading Flutter dependencies...
call flutter pub upgrade
if %errorlevel% neq 0 (
    echo Flutter pub upgrade failed!
    pause
    exit /b 1
)

echo Step 3: Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Flutter pub get failed!
    pause
    exit /b 1
)

echo Step 4: Uninstalling existing app from device...
echo (This ensures clean App Check provider installation)
adb uninstall com.homefix.technician
echo App uninstalled (ignore error if app wasn't installed)

echo ========================================
echo READY TO TEST UPDATED APP CHECK
echo ========================================
echo.
echo CHANGES MADE:
echo - Updated firebase_app_check from ^0.3.2+10 to ^0.3.0+15
echo - Cleaned Flutter project completely
echo - Upgraded all dependencies
echo - Uninstalled existing app for clean installation
echo.
echo EXPECTED RESULTS:
echo - App Check provider properly detected
echo - No "No AppCheckProvider installed" errors
echo - Debug token generated successfully
echo - Functions work without UNAUTHENTICATED errors
echo.
echo WHAT TO LOOK FOR:
echo 1. "✅ APP CHECK ACTIVATED" in console
echo 2. "APP_CHECK_DEBUG_TOKEN: [token]" logged
echo 3. No provider installation errors
echo 4. Successful function calls
echo.
echo Press any key to start flutter run...
pause

call flutter run