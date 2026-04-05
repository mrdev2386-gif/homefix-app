#!/usr/bin/env pwsh
# SECURE RAZORPAY INTEGRATION - DEPLOYMENT SCRIPT
# Run this script to deploy the secure Razorpay integration

Write-Host "🚀 DEPLOYING SECURE RAZORPAY INTEGRATION" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

# Change to functions directory
Set-Location "c:\Users\yash\projects\homefix\functions"

Write-Host "📁 Current directory: $(Get-Location)" -ForegroundColor Yellow

# Check if Firebase CLI is installed
try {
    $firebaseVersion = firebase --version
    Write-Host "✅ Firebase CLI found: $firebaseVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Firebase CLI not found. Please install: npm install -g firebase-tools" -ForegroundColor Red
    exit 1
}

# Check if logged in to Firebase
try {
    $currentUser = firebase auth:list 2>$null
    Write-Host "✅ Firebase authentication verified" -ForegroundColor Green
} catch {
    Write-Host "❌ Not logged in to Firebase. Run: firebase login" -ForegroundColor Red
    exit 1
}

# Prompt for Razorpay configuration
Write-Host ""
Write-Host "🔑 RAZORPAY CONFIGURATION SETUP" -ForegroundColor Cyan
Write-Host "================================" -ForegroundColor Cyan

$keyId = Read-Host "Enter Razorpay Key ID (rzp_test_xxx or rzp_live_xxx)"
if ([string]::IsNullOrWhiteSpace($keyId)) {
    Write-Host "❌ Key ID is required" -ForegroundColor Red
    exit 1
}

$keySecret = Read-Host "Enter Razorpay Key Secret" -AsSecureString
$keySecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($keySecret))
if ([string]::IsNullOrWhiteSpace($keySecretPlain)) {
    Write-Host "❌ Key Secret is required" -ForegroundColor Red
    exit 1
}

$webhookSecret = Read-Host "Enter Razorpay Webhook Secret" -AsSecureString
$webhookSecretPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($webhookSecret))
if ([string]::IsNullOrWhiteSpace($webhookSecretPlain)) {
    Write-Host "❌ Webhook Secret is required" -ForegroundColor Red
    exit 1
}

# Set Firebase Functions configuration
Write-Host ""
Write-Host "⚙️  Setting Firebase Functions configuration..." -ForegroundColor Yellow

try {
    firebase functions:config:set "razorpay.key_id=$keyId" | Out-Null
    Write-Host "✅ Key ID configured" -ForegroundColor Green
    
    firebase functions:config:set "razorpay.key_secret=$keySecretPlain" | Out-Null
    Write-Host "✅ Key Secret configured" -ForegroundColor Green
    
    firebase functions:config:set "razorpay.webhook_secret=$webhookSecretPlain" | Out-Null
    Write-Host "✅ Webhook Secret configured" -ForegroundColor Green
} catch {
    Write-Host "❌ Failed to set Firebase configuration: $_" -ForegroundColor Red
    exit 1
}

# Verify configuration
Write-Host ""
Write-Host "🔍 Verifying configuration..." -ForegroundColor Yellow
$config = firebase functions:config:get | ConvertFrom-Json
if ($config.razorpay) {
    Write-Host "✅ Configuration verified" -ForegroundColor Green
} else {
    Write-Host "❌ Configuration verification failed" -ForegroundColor Red
    exit 1
}

# Build TypeScript
Write-Host ""
Write-Host "🔨 Building TypeScript..." -ForegroundColor Yellow
try {
    npm run build
    Write-Host "✅ Build successful" -ForegroundColor Green
} catch {
    Write-Host "❌ Build failed: $_" -ForegroundColor Red
    exit 1
}

# Deploy functions
Write-Host ""
Write-Host "🚀 Deploying functions..." -ForegroundColor Yellow

$deployChoice = Read-Host "Deploy only new Razorpay functions? (y/n) [y]"
if ([string]::IsNullOrWhiteSpace($deployChoice) -or $deployChoice.ToLower() -eq "y") {
    try {
        firebase deploy --only functions:createOrder,functions:verifyPayment,functions:razorpayWebhook
        Write-Host "✅ Razorpay functions deployed successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
        exit 1
    }
} else {
    try {
        firebase deploy --only functions
        Write-Host "✅ All functions deployed successfully" -ForegroundColor Green
    } catch {
        Write-Host "❌ Deployment failed: $_" -ForegroundColor Red
        exit 1
    }
}

# Get project info for webhook URL
$projectId = (firebase use | Select-String "Now using project (.+)" | ForEach-Object { $_.Matches[0].Groups[1].Value })
$webhookUrl = "https://asia-south1-$projectId.cloudfunctions.net/razorpayWebhook"

# Display success message and next steps
Write-Host ""
Write-Host "🎉 DEPLOYMENT SUCCESSFUL!" -ForegroundColor Green
Write-Host "========================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 NEXT STEPS:" -ForegroundColor Cyan
Write-Host "1. Configure Razorpay Webhook:" -ForegroundColor White
Write-Host "   URL: $webhookUrl" -ForegroundColor Yellow
Write-Host "   Events: payment.captured, payment.failed" -ForegroundColor Yellow
Write-Host ""
Write-Host "2. Update Flutter apps to use new functions:" -ForegroundColor White
Write-Host "   - createOrder (instead of createPaymentOrder)" -ForegroundColor Yellow
Write-Host "   - verifyPayment (instead of verifyRazorpayPayment)" -ForegroundColor Yellow
Write-Host ""
Write-Host "3. Test the integration:" -ForegroundColor White
Write-Host "   firebase functions:shell" -ForegroundColor Yellow
Write-Host ""
Write-Host "📞 Support: 9508322397" -ForegroundColor Cyan
Write-Host ""

# Clear sensitive variables
$keySecretPlain = $null
$webhookSecretPlain = $null

Write-Host "✅ Secure Razorpay integration deployed successfully!" -ForegroundColor Green