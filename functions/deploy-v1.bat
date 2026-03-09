@echo off
echo ========================================
echo Firebase Functions v1 Migration
echo ========================================
echo.

cd /d c:\Users\yash\projects\homefix\functions

echo [1/5] Cleaning old dependencies...
if exist node_modules rmdir /s /q node_modules
if exist package-lock.json del /f /q package-lock.json
echo Done.
echo.

echo [2/5] Installing Firebase Functions v1 (v4.9.0)...
call npm install
if %errorlevel% neq 0 (
    echo ERROR: npm install failed
    pause
    exit /b 1
)
echo Done.
echo.

echo [3/5] Building TypeScript...
call npm run build
if %errorlevel% neq 0 (
    echo ERROR: Build failed
    pause
    exit /b 1
)
echo Done.
echo.

echo [4/5] Checking build output...
if exist lib\index.js (
    echo ✓ Build successful - lib\index.js created
) else (
    echo ERROR: Build output not found
    pause
    exit /b 1
)
echo.

echo [5/5] Ready to deploy!
echo.
echo ========================================
echo Next Steps:
echo ========================================
echo 1. Review build output above
echo 2. Run: firebase deploy --only functions
echo.
echo Or deploy specific functions:
echo   firebase deploy --only functions:addTechnicianService
echo   firebase deploy --only functions:createTechnicianService
echo ========================================
echo.
pause
