@echo off
echo 🔧 Setting up HomeFix Firebase Environment Variables...

REM Check if Firebase CLI is installed
firebase --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Firebase CLI not found. Please install it first:
    echo npm install -g firebase-tools
    pause
    exit /b 1
)

echo.
echo 📝 Please provide your Razorpay credentials:
echo.

REM Get Razorpay Key ID
set /p RAZORPAY_KEY_ID="Enter Razorpay Key ID (rzp_test_xxx or rzp_live_xxx): "
if "%RAZORPAY_KEY_ID%"=="" (
    echo ❌ Razorpay Key ID is required
    pause
    exit /b 1
)

REM Get Razorpay Key Secret
set /p RAZORPAY_KEY_SECRET="Enter Razorpay Key Secret: "
if "%RAZORPAY_KEY_SECRET%"=="" (
    echo ❌ Razorpay Key Secret is required
    pause
    exit /b 1
)

REM Get Razorpay Webhook Secret
set /p RAZORPAY_WEBHOOK_SECRET="Enter Razorpay Webhook Secret: "
if "%RAZORPAY_WEBHOOK_SECRET%"=="" (
    echo ❌ Razorpay Webhook Secret is required
    pause
    exit /b 1
)

REM Get optional values
set /p RAZORPAY_PAYOUT_WEBHOOK_SECRET="Enter Razorpay Payout Webhook Secret (optional): "
set /p RAZORPAY_ACCOUNT_NUMBER="Enter Razorpay Account Number (for payouts, optional): "

echo.
echo 🚀 Setting environment variables...

REM Set environment variables using Firebase CLI
firebase functions:config:set razorpay.key_id="%RAZORPAY_KEY_ID%" razorpay.key_secret="%RAZORPAY_KEY_SECRET%" razorpay.webhook_secret="%RAZORPAY_WEBHOOK_SECRET%"

if not "%RAZORPAY_PAYOUT_WEBHOOK_SECRET%"=="" (
    firebase functions:config:set razorpay.payout_webhook_secret="%RAZORPAY_PAYOUT_WEBHOOK_SECRET%"
)

if not "%RAZORPAY_ACCOUNT_NUMBER%"=="" (
    firebase functions:config:set razorpay.account_number="%RAZORPAY_ACCOUNT_NUMBER%"
)

echo.
echo ✅ Environment variables set successfully!
echo.
echo 📋 Current configuration:
firebase functions:config:get

echo.
echo 🔄 To apply changes, redeploy your functions:
echo firebase deploy --only functions

echo.
echo 🌐 Webhook URLs to configure in Razorpay Dashboard:
echo Payment Webhook: https://YOUR_PROJECT_ID.cloudfunctions.net/razorpayWebhookV2
echo Payout Webhook: https://YOUR_PROJECT_ID.cloudfunctions.net/razorpayPayoutWebhook

echo.
echo ⚠️  IMPORTANT SECURITY NOTES:
echo 1. Never commit these credentials to version control
echo 2. Use test credentials for development
echo 3. Use live credentials only for production
echo 4. Regularly rotate your API keys

echo.
echo 🎉 Setup complete! Your HomeFix payment system is ready.
pause