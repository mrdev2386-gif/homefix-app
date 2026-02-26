#!/bin/bash

echo "🚀 Deploying Reviews, Disputes & Risk Modules"
echo "=============================================="

# Navigate to functions directory
cd "$(dirname "$0")/functions"

echo ""
echo "📦 Step 1: Building Cloud Functions..."
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Build failed. Please fix errors and try again."
    exit 1
fi

echo ""
echo "☁️  Step 2: Deploying Cloud Functions..."
firebase deploy --only functions:admin_manageReview,functions:admin_manageDispute,functions:admin_manageRiskProfile

if [ $? -ne 0 ]; then
    echo "❌ Function deployment failed."
    exit 1
fi

echo ""
echo "📊 Step 3: Deploying Firestore Indexes..."
firebase deploy --only firestore:indexes

echo ""
echo "🎨 Step 4: Building Admin Panel..."
cd ../apps/admin_panel
npm run build

if [ $? -ne 0 ]; then
    echo "❌ Admin panel build failed."
    exit 1
fi

echo ""
echo "🌐 Step 5: Deploying Admin Panel..."
firebase deploy --only hosting

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "📝 Next Steps:"
echo "1. Verify Cloud Functions are active in Firebase Console"
echo "2. Check Firestore indexes are building"
echo "3. Test each module in the admin panel"
echo "4. Review activity logs for admin actions"
echo ""
echo "📖 Documentation: REVIEWS_DISPUTES_RISK_IMPLEMENTATION.md"
