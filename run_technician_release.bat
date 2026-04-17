@echo off
REM Stable release mode - bypasses debug build overhead
cd /d c:\Users\yash\projects\homefix\apps\technician_app
flutter run --release --no-tree-shake-icons
pause
