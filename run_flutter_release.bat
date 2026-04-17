@echo off
REM Release mode build (uses less memory than debug)
setx DART_VM_OPTIONS "--old_gen_heap_size=4096"

cd /d c:\Users\yash\projects\homefix\apps\customer_app

echo Cleaning Flutter cache...
flutter clean

echo Cleaning Gradle cache...
cd android
call gradlew clean
cd ..

echo Getting dependencies...
flutter pub get

echo Starting Flutter release build...
flutter run --release

pause
