@echo off
echo ========================================
echo HomeFix Customer App - Final UI Test
echo ========================================
echo.

cd /d C:\Users\yash\projects\homefix\apps\customer_app

echo [1/3] Cleaning build...
call flutter clean

echo.
echo [2/3] Getting dependencies...
call flutter pub get

echo.
echo [3/3] Running app...
echo.
echo VERIFY:
echo - Categories: 2 rows, horizontal scroll
echo - Icons: Circular orange gradient (48x48)
echo - Cards: White with shadows, rounded corners
echo - Touch: Ripple effect on tap
echo - Responsive: Works on all devices
echo.
call flutter run

pause
