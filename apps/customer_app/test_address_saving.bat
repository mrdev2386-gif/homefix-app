@echo off
echo ========================================
echo HomeFix - Address Saving Test
echo ========================================
echo.

cd C:\Users\yash\projects\homefix\apps\customer_app

echo [1/3] Cleaning build...
call flutter clean
echo.

echo [2/3] Getting dependencies...
call flutter pub get
echo.

echo [3/3] Running app...
echo.
echo TEST STEPS:
echo 1. Open profile
echo 2. Add primary address with district
echo 3. Tap save
echo 4. Check Firestore console for customers/{uid}
echo 5. Verify fields: primaryAddress, district, state
echo.
echo Expected in Firestore:
echo   - primaryAddress: [full address]
echo   - district: [lowercase district]
echo   - state: [lowercase state]
echo   - addressUpdatedAt: [timestamp]
echo.
call flutter run

pause