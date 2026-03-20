@echo off
echo ========================================
echo FIREBASE APP CHECK ACTIVATION FIX TEST
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
echo READY TO TEST APP CHECK ACTIVATION
echo ========================================
echo.
echo WHAT TO LOOK FOR IN CONSOLE:
echo 1. "✅ APP CHECK ACTIVATED" - confirms activation
echo 2. "APP_CHECK_DEBUG_TOKEN: [token]" - shows token generation
echo 3. NO "No AppCheckProvider installed" errors
echo 4. NO conditional logic bypassing activation
echo.
echo FIXED ISSUES:
echo - Removed all conditional logic around App Check
echo - Removed try/catch blocks swallowing errors
echo - Removed duplicate initialization flags
echo - App Check now activates immediately after Firebase.initializeApp()
echo.
echo Press any key to start flutter run...
pause

call flutter run