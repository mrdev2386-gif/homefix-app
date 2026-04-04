@echo off
echo ========================================
echo AUTHWRAPPER FIX - CLEAN BUILD
echo ========================================
echo.

cd C:\Users\yash\projects\homefix\apps\customer_app

echo [1/3] Cleaning Flutter build cache...
call flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Flutter clean failed
    pause
    exit /b 1
)

echo.
echo [2/3] Getting dependencies...
call flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Flutter pub get failed
    pause
    exit /b 1
)

echo.
echo [3/3] Running app...
echo.
echo ========================================
echo Starting app on connected device...
echo ========================================
echo.
call flutter run

pause
