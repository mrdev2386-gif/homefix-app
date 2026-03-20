@echo off
REM ============================================
REM Firebase Functions Region Fix Deployment
REM ============================================

echo.
echo ========================================
echo Firebase Functions Region Fix
echo ========================================
echo.

cd C:\Users\yash\projects\homefix\functions

echo [STEP 1/3] Building Cloud Functions...
echo.
call npm run build

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ BUILD FAILED!
    echo Please fix TypeScript errors and try again.
    pause
    exit /b 1
)

echo.
echo ✅ Build successful!
echo.

echo [STEP 2/3] Deploying ALL functions to asia-south1...
echo.
echo IMPORTANT: This will deploy ALL functions to ensure consistency.
echo.
pause

call firebase deploy --only functions

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ DEPLOYMENT FAILED!
    echo Check Firebase Console for errors.
    pause
    exit /b 1
)

echo.
echo ✅ Deployment successful!
echo.

echo [STEP 3/3] Verification Steps
echo.
echo Please verify the following:
echo.
echo 1. Open Firebase Console: https://console.firebase.google.com/
echo 2. Navigate to Functions Dashboard
echo 3. Verify ALL functions show region: asia-south1
echo 4. Test the following in Technician App:
echo    - Add a service
echo    - Delete a service
echo    - Toggle service status
echo    - Update profile
echo    - Toggle online status
echo.
echo If all tests pass, the fix is complete!
echo.
echo For detailed verification steps, see: REGION_FIX_DEPLOYMENT.md
echo.

pause
