@echo off
echo ========================================
echo Firebase Cloud Functions - Clean Rebuild
echo ========================================
echo.

cd /d "%~dp0"

echo [1/4] Cleaning build artifacts...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)
echo.

echo [2/4] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)
echo.

echo [3/4] Verifying firebase_app_check...
call flutter pub deps | findstr "firebase_app_check"
echo.

echo [4/4] Building app...
echo.
echo Ready to run: flutter run
echo.
echo ========================================
echo VERIFICATION CHECKLIST:
echo ========================================
echo [ ] Firebase initialized successfully
echo [ ] App Check activated in DEBUG mode
echo [ ] No UNAUTHENTICATED errors
echo [ ] Cloud Functions calls succeed
echo ========================================
echo.

pause
