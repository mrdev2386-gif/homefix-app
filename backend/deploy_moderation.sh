#!/bin/bash

echo "🚀 Deploying HomeFix Service Moderation Cloud Functions..."

cd backend/functions

echo "📦 Installing dependencies..."
npm install

echo "🔧 Building TypeScript..."
npm run build

echo "☁️ Deploying to Firebase..."
firebase deploy --only functions:approveService,functions:rejectService,functions:disableService

echo "✅ Service moderation functions deployed successfully!"
echo ""
echo "📋 Available functions:"
echo "  - approveService"
echo "  - rejectService" 
echo "  - disableService"
echo ""
echo "🔐 Security features:"
echo "  - Admin role verification"
echo "  - Transaction safety"
echo "  - Audit logging"
echo ""
echo "🎯 Next steps:"
echo "  1. Set admin custom claims for admin users"
echo "  2. Test moderation workflow"
echo "  3. Verify customer app shows only active services"