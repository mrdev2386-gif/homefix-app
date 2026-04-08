#!/bin/bash

# ============================================
# BOOKING SYSTEM DEPLOYMENT SCRIPT
# ============================================

echo ""
echo "============================================"
echo "HOMEFIX BOOKING SYSTEM DEPLOYMENT"
echo "============================================"
echo ""

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "ERROR: Firebase CLI not found!"
    echo "Please install: npm install -g firebase-tools"
    exit 1
fi

echo "[1/5] Checking TypeScript compilation..."
cd functions
npx tsc --noEmit
if [ $? -ne 0 ]; then
    echo "ERROR: TypeScript compilation failed!"
    exit 1
fi
echo "✓ TypeScript compilation successful"
echo ""

echo "[2/5] Building Cloud Functions..."
npm run build
if [ $? -ne 0 ]; then
    echo "ERROR: Build failed!"
    exit 1
fi
echo "✓ Build successful"
echo ""

echo "[3/5] Deploying Cloud Functions..."
echo "Deploying: createBookingRequest, approveBookingByAdmin, rejectBookingByAdmin"
cd ..
firebase deploy --only functions:createBookingRequest,functions:approveBookingByAdmin,functions:rejectBookingByAdmin
if [ $? -ne 0 ]; then
    echo "ERROR: Cloud Functions deployment failed!"
    exit 1
fi
echo "✓ Cloud Functions deployed"
echo ""

echo "[4/5] Building Admin Panel..."
cd apps/admin_panel
npm run build
if [ $? -ne 0 ]; then
    echo "ERROR: Admin panel build failed!"
    exit 1
fi
echo "✓ Admin panel built"
echo ""

echo "[5/5] Deploying Admin Panel..."
cd ../..
firebase deploy --only hosting:admin
if [ $? -ne 0 ]; then
    echo "ERROR: Admin panel deployment failed!"
    exit 1
fi
echo "✓ Admin panel deployed"
echo ""

echo "============================================"
echo "DEPLOYMENT COMPLETE!"
echo "============================================"
echo ""
echo "Next steps:"
echo "1. Open admin panel and test booking approval"
echo "2. Create a test booking from customer app"
echo "3. Verify admin receives notification"
echo "4. Approve booking and verify technician notification"
echo ""
echo "For detailed testing checklist, see:"
echo "BOOKING_SYSTEM_FINAL_DEPLOYMENT.md"
echo ""
