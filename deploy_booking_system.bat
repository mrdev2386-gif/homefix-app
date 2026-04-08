@echo off
REM ============================================
REM BOOKING SYSTEM DEPLOYMENT SCRIPT
REM ============================================

echo.
echo ============================================
echo HOMEFIX BOOKING SYSTEM DEPLOYMENT
echo ============================================
echo.

REM Check if Firebase CLI is installed
where firebase >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Firebase CLI not found!
    echo Please install: npm install -g firebase-tools
    pause
    exit /b 1
)

echo [1/5] Checking TypeScript compilation...
cd functions
call npx tsc --noEmit
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: TypeScript compilation failed!
    pause
    exit /b 1
)
echo ✓ TypeScript compilation successful
echo.

echo [2/5] Building Cloud Functions...
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Build failed!
    pause
    exit /b 1
)
echo ✓ Build successful
echo.

echo [3/5] Deploying Cloud Functions...
echo Deploying: createBookingRequest, approveBookingByAdmin, rejectBookingByAdmin
cd ..
call firebase deploy --only functions:createBookingRequest,functions:approveBookingByAdmin,functions:rejectBookingByAdmin
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Cloud Functions deployment failed!
    pause
    exit /b 1
)
echo ✓ Cloud Functions deployed
echo.

echo [4/5] Building Admin Panel...
cd apps\admin_panel
call npm run build
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Admin panel build failed!
    pause
    exit /b 1
)
echo ✓ Admin panel built
echo.

echo [5/5] Deploying Admin Panel...
cd ..\..
call firebase deploy --only hosting:admin
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Admin panel deployment failed!
    pause
    exit /b 1
)
echo ✓ Admin panel deployed
echo.

echo ============================================
echo DEPLOYMENT COMPLETE!
echo ============================================
echo.
echo Next steps:
echo 1. Open admin panel and test booking approval
echo 2. Create a test booking from customer app
echo 3. Verify admin receives notification
echo 4. Approve booking and verify technician notification
echo.
echo For detailed testing checklist, see:
echo BOOKING_SYSTEM_FINAL_DEPLOYMENT.md
echo.
pause
