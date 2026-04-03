@echo off
echo ========================================
echo Firebase Functions Auth Fix Deployment
echo ========================================
echo.

echo [1/4] Building Firebase Functions...
cd c:\Users\yash\projects\homefix\functions
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo ✅ Build successful
echo.

echo [2/4] Deploying Firebase Functions...
call firebase deploy --only functions
if %errorlevel% neq 0 (
    echo ERROR: Deployment failed!
    pause
    exit /b 1
)
echo ✅ Deployment successful
echo.

echo [3/4] Cleaning Flutter app...
cd c:\Users\yash\projects\homefix\apps\customer_app
call flutter clean
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter setup failed!
    pause
    exit /b 1
)
echo ✅ Flutter setup successful
echo.

echo [4/4] Running Flutter app...
echo.
echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo Next steps:
echo 1. App will launch automatically
echo 2. Login to the app
echo 3. Test any function (update profile, add to cart, etc.)
echo 4. Check logs for ✅ SUCCESS messages
echo.
echo If you see ❌ UNAUTHENTICATED errors:
echo - Check Firebase Console logs
echo - Verify user is logged in
echo - See FIREBASE_AUTH_FIX_QUICK_REF.md for troubleshooting
echo.
echo ========================================
echo.

call flutter run

pause
