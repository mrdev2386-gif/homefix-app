@echo off
cd /d "%~dp0"
flutter clean
flutter pub get
adb uninstall com.homefix.customer
flutter run
