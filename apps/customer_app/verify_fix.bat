@echo off
echo ========================================
echo Firebase Functions Fix - Final Verification
echo ========================================
echo.

cd /d "%~dp0"

echo [1/5] Cleaning...
call flutter clean
echo.

echo [2/5] Getting dependencies...
call flutter pub get
echo.

echo [3/5] Running tests...
call flutter test test/firebase_functions_test.dart
echo.

echo [4/5] Uninstalling app...
adb uninstall com.homefix.customer
echo.

echo [5/5] Running app...
call flutter run
