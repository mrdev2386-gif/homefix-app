@echo off
echo ========================================
echo HomeFix - Wireless ADB Connection Helper
echo ========================================
echo.

echo Step 1: Restarting ADB server...
adb kill-server
timeout /t 2 /nobreak >nul
adb start-server
timeout /t 2 /nobreak >nul

echo.
echo Step 2: Checking for devices...
adb devices

echo.
echo Step 3: Attempting to connect to device...
echo Trying IP: 192.168.31.178:34749
adb connect 192.168.31.178:34749

echo.
echo Step 4: Listing connected devices...
adb devices

echo.
echo ========================================
echo If connection failed, please:
echo 1. On your phone, go to Settings ^> Developer Options
echo 2. Enable "Wireless debugging"
echo 3. Tap "Pair device with pairing code"
echo 4. Note the IP address and port shown
echo 5. Run: adb connect [IP]:[PORT]
echo ========================================
echo.

pause
