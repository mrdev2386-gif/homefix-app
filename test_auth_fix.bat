@echo off
echo ========================================
echo FIREBASE CALLABLE AUTH FIX VERIFICATION
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
echo MANUAL TOKEN HANDLING REMOVED
echo ========================================
echo.
echo CRITICAL FIXES APPLIED:
echo - Removed ALL await user.getIdToken(true) calls
echo - Removed manual token refresh logic
echo - Removed JWT validation code
echo - Removed token-related debug logs
echo - Simplified to Firebase automatic token attachment
echo.
echo CORRECT PATTERN NOW USED:
echo 1. Check if user is logged in
echo 2. Create callable function
echo 3. Call function (Firebase auto-attaches token)
echo 4. No manual token handling
echo.
echo EXPECTED RESULTS:
echo - Firebase automatically attaches auth token
echo - context.auth.uid available in backend
echo - deleteService works without UNAUTHENTICATED error
echo - All callable functions work properly
echo.
echo WHAT TO TEST:
echo 1. Navigate to Services screen
echo 2. Try to delete a service
echo 3. Verify no UNAUTHENTICATED errors
echo 4. Check backend logs show context.auth.uid
echo.
echo Press any key to start flutter run...
pause

call flutter run