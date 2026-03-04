@echo off
REM ============================================
REM TECHNICIAN BANK MODULE - DEPLOYMENT SCRIPT
REM ============================================

echo.
echo ========================================
echo DEPLOYING BANK MODULE TO PRODUCTION
echo ========================================
echo.

REM Step 1: Build Cloud Functions
echo [1/4] Building Cloud Functions...
cd c:\Users\yash\projects\homefix\functions
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Cloud Functions build failed
    pause
    exit /b 1
)
echo ✓ Cloud Functions built successfully
echo.

REM Step 2: Deploy Cloud Functions
echo [2/4] Deploying Cloud Functions...
call firebase deploy --only functions:updateTechnicianBankDetails,functions:adminUpdateBankStatus
if %errorlevel% neq 0 (
    echo ERROR: Cloud Functions deployment failed
    pause
    exit /b 1
)
echo ✓ Cloud Functions deployed successfully
echo.

REM Step 3: Deploy Firestore Rules
echo [3/4] Deploying Firestore Rules...
cd c:\Users\yash\projects\homefix
call firebase deploy --only firestore:rules
if %errorlevel% neq 0 (
    echo ERROR: Firestore rules deployment failed
    pause
    exit /b 1
)
echo ✓ Firestore rules deployed successfully
echo.

REM Step 4: Build Flutter App
echo [4/4] Building Flutter App...
cd c:\Users\yash\projects\homefix\apps\technician_app
call flutter clean
call flutter pub get
call flutter build apk --release
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed
    pause
    exit /b 1
)
echo ✓ Flutter app built successfully
echo.

echo ========================================
echo DEPLOYMENT COMPLETE
echo ========================================
echo.
echo Next Steps:
echo 1. Test on real device
echo 2. Verify all test cases in BANK_MODULE_HARDENING_COMPLETE.md
echo 3. Monitor Cloud Function logs
echo.
pause
