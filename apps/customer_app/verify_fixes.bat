@echo off
echo ========================================
echo HomeFix - Production Fixes Verification
echo ========================================
echo.

cd C:\Users\yash\projects\homefix\apps\customer_app

echo [1/3] Verifying assets...
if exist "assets\images\ac_repair.png" (
    echo   ✅ ac_repair.png exists
) else (
    echo   ❌ ac_repair.png missing
)
echo.

echo [2/3] Getting dependencies...
call flutter pub get
echo.

echo [3/3] Running app...
echo.
echo Watch console for:
echo   ✅ Firebase App Check debug token
echo   ✅ "Skip token save" (before login)
echo   ✅ "FCM token saved" (after login)
echo   ✅ No banner 404 errors
echo   ✅ No asset load errors
echo.
call flutter run

pause
