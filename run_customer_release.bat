@echo off
REM Stable release mode - bypasses debug build overhead
cd /d c:\Users\yash\projects\homefix\apps\customer_app
flutter run --release --no-tree-shake-icons
pause
