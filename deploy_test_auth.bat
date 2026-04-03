@echo off
echo ========================================
echo Firebase Auth Debug Test - Deployment
echo ========================================
echo.

cd c:\Users\yash\projects\homefix\functions

echo [1/3] Building functions...
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)

echo.
echo [2/3] Deploying testAuth function...
call firebase deploy --only functions:testAuth
if %errorlevel% neq 0 (
    echo ERROR: Deployment failed
    pause
    exit /b 1
)

echo.
echo [3/3] Listing deployed functions...
call firebase functions:list | findstr testAuth

echo.
echo ========================================
echo ✅ Deployment Complete!
echo ========================================
echo.
echo Next Steps:
echo 1. Run customer app: cd apps\customer_app ^&^& flutter run
echo 2. Login to the app
echo 3. Navigate to FirebaseTestScreen
echo 4. Tap "TEST CLOUD FUNCTION"
echo.
echo See FIREBASE_AUTH_DEBUG_TEST.md for details
echo.
pause
