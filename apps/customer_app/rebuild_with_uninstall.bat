@echo off
echo ========================================
echo Firebase Initialization - Clean Rebuild
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Cleaning build artifacts...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)
echo.

echo [2/5] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)
echo.

echo [3/5] Checking for connected device...
adb devices
echo.

echo [4/5] OPTIONAL: Uninstall existing app to force fresh install
echo This ensures App Check is properly initialized
echo.
set /p UNINSTALL="Uninstall app? (y/n): "
if /i "%UNINSTALL%"=="y" (
    echo Uninstalling com.homefix.customer...
    adb uninstall com.homefix.customer
    echo.
)

echo [5/5] Building and running app...
echo.
echo Running: flutter run
echo.
echo ========================================
echo WATCH FOR THESE LOGS:
echo ========================================
echo [✓] Firebase initialized
echo [✓] App Check ACTIVATED
echo ========================================
echo.

call flutter run

pause
