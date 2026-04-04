@echo off
echo ========================================
echo ONBOARDING FIX - CLEAN BUILD
echo ========================================
echo.

cd C:\Users\yash\projects\homefix\apps\customer_app

echo [1/4] Cleaning Flutter build...
call flutter clean

echo.
echo [2/4] Getting dependencies...
call flutter pub get

echo.
echo [3/4] Building app...
call flutter build apk --debug

echo.
echo [4/4] Running app...
call flutter run

echo.
echo ========================================
echo BUILD COMPLETE
echo ========================================
pause
