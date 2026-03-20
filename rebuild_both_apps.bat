@echo off
echo ========================================
echo REBUILDING BOTH APPS
echo ========================================
echo.

echo ========================================
echo CUSTOMER APP
echo ========================================
cd apps\customer_app

echo [1/3] Cleaning build...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Customer app flutter clean failed
    pause
    exit /b 1
)

echo [2/3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Customer app flutter pub get failed
    pause
    exit /b 1
)

echo [3/3] Customer app ready!
echo.

cd ..\..

echo ========================================
echo TECHNICIAN APP
echo ========================================
cd apps\technician_app

echo [1/3] Cleaning build...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Technician app flutter clean failed
    pause
    exit /b 1
)

echo [2/3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Technician app flutter pub get failed
    pause
    exit /b 1
)

echo [3/3] Technician app ready!
echo.

cd ..\..

echo ========================================
echo SUCCESS - BOTH APPS REBUILT
echo ========================================
echo.
echo Next steps:
echo 1. Run customer app: cd apps\customer_app ^&^& flutter run
echo 2. Run technician app: cd apps\technician_app ^&^& flutter run
echo 3. Copy debug tokens from logs
echo 4. Register tokens in Firebase Console
echo.

pause
