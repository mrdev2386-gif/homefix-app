@echo off
echo ========================================
echo REBUILDING TECHNICIAN APP
echo ========================================
echo.

cd apps\technician_app

echo [1/4] Cleaning build...
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
echo [3/4] Building app...
call flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: Flutter build failed
    pause
    exit /b 1
)

echo.
echo [4/4] Running app...
call flutter run

pause
