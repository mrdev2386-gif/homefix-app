@echo off
echo ========================================
echo FIREBASE APP CHECK DEBUG VERIFICATION
echo ========================================

cd apps\technician_app

echo Step 1: Cleaning project...
call flutter clean
if %errorlevel% neq 0 (
    echo Flutter clean failed!
    pause
    exit /b 1
)

echo Step 2: Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo Flutter pub get failed!
    pause
    exit /b 1
)

echo ========================================
echo READY TO RUN APP
echo ========================================
echo.
echo INSTRUCTIONS:
echo 1. Run: flutter run
echo 2. Watch console for: APP_CHECK_DEBUG_TOKEN: [token]
echo 3. Copy the token string
echo 4. Go to Firebase Console → App Check → Debug tokens
echo 5. Add the token with description "Technician App Debug"
echo 6. Test deleteService function
echo.
echo EXPECTED RESULTS:
echo - No UNAUTHENTICATED errors
echo - Functions receive proper auth context
echo - deleteService works successfully
echo.
echo Press any key to start flutter run...
pause

call flutter run