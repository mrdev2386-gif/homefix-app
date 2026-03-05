@echo off
echo ========================================
echo DISABLING APP CHECK FOR DEVELOPMENT
echo ========================================
echo.
echo WARNING: This is for DEVELOPMENT ONLY
echo App Check will be RE-ENABLED before production
echo.

echo Step 1: Building Cloud Functions...
cd C:\Users\yash\projects\homefix\functions
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Function build failed!
    pause
    exit /b 1
)
echo ✓ Functions built successfully
echo.

echo Step 2: Deploying all functions...
firebase deploy --only functions
if %errorlevel% neq 0 (
    echo ERROR: Function deployment failed!
    pause
    exit /b 1
)
echo ✓ Functions deployed successfully
echo.

echo ========================================
echo DEPLOYMENT COMPLETE!
echo ========================================
echo.
echo App Check is now DISABLED for development
echo.
echo You can now:
echo ✓ Call updateUserProfile without App Check errors
echo ✓ Save state and district selections
echo ✓ Test all features in debug mode
echo.
echo IMPORTANT: Before production launch, run:
echo   enable_app_check.bat
echo.
pause
