@echo off
echo ========================================
echo Starting HomeFix Admin Panel (Clean)
echo ========================================
echo.

cd /d "%~dp0"

echo [1/2] Clearing cache...
if exist .next rmdir /s /q .next
echo Cache cleared!
echo.

echo [2/2] Starting dev server...
echo.
npm run dev
