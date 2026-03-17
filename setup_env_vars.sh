#!/bin/bash

# HomeFix Firebase Environment Variables Setup
# Run this script to configure Razorpay environment variables

echo "🔧 Setting up HomeFix Firebase Environment Variables..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Please install it first:"
    echo "npm install -g firebase-tools"
    exit 1
fi

# Check if user is logged in
if ! firebase projects:list &> /dev/null; then
    echo "❌ Please login to Firebase first:"
    echo "firebase login"
    exit 1
fi

echo ""
echo "📝 Please provide your Razorpay credentials:"
echo ""

# Get Razorpay Key ID
read -p "Enter Razorpay Key ID (rzp_test_xxx or rzp_live_xxx): " RAZORPAY_KEY_ID
if [ -z "$RAZORPAY_KEY_ID" ]; then
    echo "❌ Razorpay Key ID is required"
    exit 1
fi

# Get Razorpay Key Secret
read -s -p "Enter Razorpay Key Secret: " RAZORPAY_KEY_SECRET
echo ""
if [ -z "$RAZORPAY_KEY_SECRET" ]; then
    echo "❌ Razorpay Key Secret is required"
    exit 1
fi

# Get Razorpay Webhook Secret
read -s -p "Enter Razorpay Webhook Secret: " RAZORPAY_WEBHOOK_SECRET
echo ""
if [ -z "$RAZORPAY_WEBHOOK_SECRET" ]; then
    echo "❌ Razorpay Webhook Secret is required"
    exit 1
fi

# Get Razorpay Payout Webhook Secret (optional)
read -s -p "Enter Razorpay Payout Webhook Secret (optional): " RAZORPAY_PAYOUT_WEBHOOK_SECRET
echo ""

# Get Razorpay Account Number (for payouts)
read -p "Enter Razorpay Account Number (for payouts, optional): " RAZORPAY_ACCOUNT_NUMBER

echo ""
echo "🚀 Setting environment variables..."

# Set environment variables using Firebase CLI
firebase functions:config:set \
  razorpay.key_id="$RAZORPAY_KEY_ID" \
  razorpay.key_secret="$RAZORPAY_KEY_SECRET" \
  razorpay.webhook_secret="$RAZORPAY_WEBHOOK_SECRET"

if [ ! -z "$RAZORPAY_PAYOUT_WEBHOOK_SECRET" ]; then
    firebase functions:config:set razorpay.payout_webhook_secret="$RAZORPAY_PAYOUT_WEBHOOK_SECRET"
fi

if [ ! -z "$RAZORPAY_ACCOUNT_NUMBER" ]; then
    firebase functions:config:set razorpay.account_number="$RAZORPAY_ACCOUNT_NUMBER"
fi

echo ""
echo "✅ Environment variables set successfully!"
echo ""
echo "📋 Current configuration:"
firebase functions:config:get

echo ""
echo "🔄 To apply changes, redeploy your functions:"
echo "firebase deploy --only functions"

echo ""
echo "🌐 Webhook URLs to configure in Razorpay Dashboard:"
echo "Payment Webhook: https://YOUR_PROJECT_ID.cloudfunctions.net/razorpayWebhookV2"
echo "Payout Webhook: https://YOUR_PROJECT_ID.cloudfunctions.net/razorpayPayoutWebhook"

echo ""
echo "⚠️  IMPORTANT SECURITY NOTES:"
echo "1. Never commit these credentials to version control"
echo "2. Use test credentials for development"
echo "3. Use live credentials only for production"
echo "4. Regularly rotate your API keys"

echo ""
echo "🎉 Setup complete! Your HomeFix payment system is ready."