@echo off
echo 🚀 SECURE RAZORPAY INTEGRATION DEPLOYMENT
echo ========================================
echo.
echo This script will deploy the secure Razorpay integration
echo using Firebase Functions config (no secrets in frontend).
echo.
pause
echo.
echo Running PowerShell deployment script...
powershell -ExecutionPolicy Bypass -File "deploy_secure_razorpay.ps1"
pause