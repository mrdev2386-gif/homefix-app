@echo off
echo ========================================
echo FIREBASE INTEGRATION FIXES DEPLOYMENT
echo ========================================
echo.

echo Step 1: Deploying Firestore Rules...
cd C:\Users\yash\projects\homefix
firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ERROR: Firestore rules deployment failed!
    pause
    exit /b 1
)
echo ✓ Firestore rules deployed successfully
echo.

echo Step 2: Building Cloud Functions...
cd C:\Users\yash\projects\homefix\functions
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Function build failed!
    pause
    exit /b 1
)
echo ✓ Functions built successfully
echo.

echo Step 3: Deploying updateUserProfile function...
firebase deploy --only functions:updateUserProfile
if %errorlevel% neq 0 (
    echo ERROR: Function deployment failed!
    pause
    exit /b 1
)
echo ✓ Function deployed successfully
echo.

echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Next steps:
echo 1. Register debug tokens in Firebase Console
echo 2. Test state/district selection in app
echo 3. Verify no permission errors
echo.
pause
