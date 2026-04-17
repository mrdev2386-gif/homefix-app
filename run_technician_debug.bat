@echo off
REM Set environment variables for stable Flutter build
setx DART_VM_OPTIONS "--old_gen_heap_size=4096"
setx PUB_ENVIRONMENT "flutter_cli:get"

REM Navigate to technician app
cd /d c:\Users\yash\projects\homefix\apps\technician_app

REM Clean caches
echo Cleaning Flutter cache...
flutter clean

echo Cleaning Gradle cache...
cd android
call gradlew clean
cd ..

REM Get dependencies
echo Getting dependencies...
flutter pub get

REM Run with low memory mode
echo Starting Flutter debug build...
flutter run --no-tree-shake-icons --no-sound-null-safety

pause
