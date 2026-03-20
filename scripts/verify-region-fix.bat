@echo off
REM ============================================
REM Region Configuration Verification Script
REM ============================================

echo.
echo ========================================
echo Region Configuration Verification
echo ========================================
echo.

cd C:\Users\yash\projects\homefix

echo [CHECK 1/5] Scanning Cloud Functions for region configurations...
echo.

findstr /s /i ".region(" functions\src\*.ts > temp_regions.txt

echo Backend Functions Region Configuration:
echo ----------------------------------------
type temp_regions.txt
echo.

echo [CHECK 2/5] Verifying technician_app Flutter configuration...
echo.

findstr /i "instanceFor" apps\technician_app\lib\core\services\functions_service.dart
findstr /i "instanceFor" apps\technician_app\lib\core\services\technician_catalog_service.dart
echo.

echo [CHECK 3/5] Checking for any us-central1 references...
echo.

findstr /s /i "us-central1" functions\src\*.ts | find /c "us-central1" > temp_count.txt
set /p OLD_REGION_COUNT=<temp_count.txt

if %OLD_REGION_COUNT% GTR 0 (
    echo ❌ WARNING: Found %OLD_REGION_COUNT% references to us-central1
    echo.
    echo Files with us-central1:
    findstr /s /i "us-central1" functions\src\*.ts
    echo.
    echo Please update these to asia-south1
) else (
    echo ✅ No us-central1 references found
)
echo.

echo [CHECK 4/5] Verifying asia-south1 consistency...
echo.

findstr /s /i "asia-south1" functions\src\*.ts | find /c "asia-south1" > temp_count2.txt
set /p NEW_REGION_COUNT=<temp_count2.txt

echo ✅ Found %NEW_REGION_COUNT% references to asia-south1
echo.

echo [CHECK 5/5] Summary
echo.
echo ========================================
echo Verification Summary
echo ========================================
echo.
echo Backend Functions:
echo   - asia-south1 references: %NEW_REGION_COUNT%
echo   - us-central1 references: %OLD_REGION_COUNT%
echo.

if %OLD_REGION_COUNT% GTR 0 (
    echo ❌ STATUS: INCOMPLETE - Some functions still use us-central1
    echo.
    echo ACTION REQUIRED:
    echo 1. Update remaining functions to asia-south1
    echo 2. Run this script again to verify
) else (
    echo ✅ STATUS: COMPLETE - All functions use asia-south1
    echo.
    echo NEXT STEPS:
    echo 1. Run: npm run build
    echo 2. Run: firebase deploy --only functions
    echo 3. Verify in Firebase Console
    echo 4. Test in Technician App
)
echo.

REM Cleanup
del temp_regions.txt 2>nul
del temp_count.txt 2>nul
del temp_count2.txt 2>nul

echo.
echo For detailed deployment steps, see: REGION_FIX_DEPLOYMENT.md
echo For complete analysis, see: REGION_FIX_SUMMARY.md
echo.

pause
