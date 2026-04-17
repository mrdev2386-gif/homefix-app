@echo off
REM Profile mode - lighter than debug, heavier than release
cd /d c:\Users\yash\projects\homefix\apps\customer_app
flutter run --profile --no-tree-shake-icons
pause
