@echo off
echo ========================================
echo HomeFix Customer App - Production Test
echo ========================================
echo.

cd C:\Users\yash\projects\homefix\apps\customer_app

echo [1/3] Getting dependencies...
call flutter pub get
echo.

echo [2/3] Cleaning build...
call flutter clean
echo.

echo [3/3] Running app...
echo.
echo Watch console for:
echo   - Firebase App Check debug token
echo   - FCM token saved message
echo   - No initialization errors
echo.
call flutter run

pause
