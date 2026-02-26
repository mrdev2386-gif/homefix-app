@echo off
echo ========================================
echo HomeFix Technician - Gradle Stability Fix
echo ========================================
echo.

echo [1/6] Stopping all Gradle daemons...
cd android
call gradlew --stop
cd ..
echo Done.
echo.

echo [2/6] Killing Java processes...
taskkill /F /IM java.exe 2>nul
taskkill /F /IM gradle.exe 2>nul
echo Done.
echo.

echo [3/6] Cleaning Flutter build...
call flutter clean
echo Done.
echo.

echo [4/6] Getting Flutter dependencies...
call flutter pub get
echo Done.
echo.

echo [5/6] Deleting Gradle cache (this may take a moment)...
echo WARNING: This will delete C:\Users\yash\.gradle
echo Press Ctrl+C to cancel, or
pause
rmdir /S /Q C:\Users\yash\.gradle 2>nul
rmdir /S /Q C:\Users\yash\.android\build-cache 2>nul
echo Done.
echo.

echo [6/6] Ready to build!
echo.
echo Run: flutter run --debug
echo.
echo ========================================
echo Cleanup Complete!
echo ========================================
pause
