@echo off
REM Build APK for manual installation (if live run fails)
cd /d c:\Users\yash\projects\homefix\apps\technician_app
echo Building APK...
flutter build apk --release
echo.
echo APK built at: build/app/outputs/flutter-apk/app-release.apk
echo.
echo To install manually, run:
echo adb install build/app/outputs/flutter-apk/app-release.apk
pause
