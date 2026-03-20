@echo off
echo ========================================
echo DEPLOYING FIREBASE FUNCTIONS - UNAUTHENTICATED FIX
echo ========================================

cd functions

echo Building TypeScript...
call npm run build
if %errorlevel% neq 0 (
    echo Build failed!
    pause
    exit /b 1
)

echo Deploying functions to us-central1...
call firebase deploy --only functions
if %errorlevel% neq 0 (
    echo Deployment failed!
    pause
    exit /b 1
)

echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo FIXED ISSUES:
echo - Region mismatch: All functions now use us-central1
echo - Added comprehensive auth context logging to deleteService
echo - Added explicit region specification to all callable functions
echo.
echo NEXT STEPS:
echo 1. Test deleteService function from technician app
echo 2. Check Firebase Console logs for auth context
echo 3. Verify no more UNAUTHENTICATED errors
echo.
pause