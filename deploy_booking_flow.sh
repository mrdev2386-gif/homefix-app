#!/bin/bash

echo "🚀 Deploying Complete Booking Flow..."

# Deploy Cloud Functions
echo "📦 Deploying Cloud Functions..."
cd functions
npm run build
firebase deploy --only functions:createBookingRequest,functions:approveBookingRequest,functions:technicianRespondToJob,functions:payBeforeWork,functions:completeService,functions:confirmAfterWorkPayment,functions:generateTechnicianQR,functions:updateBookingStatus

# Deploy Firestore Indexes
echo "🔍 Deploying Firestore Indexes..."
cd ..
firebase deploy --only firestore:indexes

# Deploy Firestore Rules (if needed)
echo "🔒 Deploying Firestore Rules..."
firebase deploy --only firestore:rules

echo "✅ Deployment Complete!"
echo ""
echo "📋 BOOKING FLOW SUMMARY:"
echo "1. Customer creates booking → status: 'pending_admin_approval'"
echo "2. Admin approves → status: 'approved_by_admin'"
echo "3. Technician accepts/rejects job"
echo "4. Payment options: 'pay_before_work' or 'pay_after_work'"
echo "5. Service completion → QR payment for after_work mode"
echo "6. Wallet transactions created for technician earnings"
echo ""
echo "🔧 TESTING CHECKLIST:"
echo "□ Customer can create booking request"
echo "□ Admin can approve/reject booking"
echo "□ Technician sees job in job screen"
echo "□ Payment mode selection works"
echo "□ QR payment flow works"
echo "□ Wallet transactions are created"
echo "□ Status updates work end-to-end"
echo ""
echo "📱 APPS TO UPDATE:"
echo "□ Customer app: Add booking screen with payment options"
echo "□ Technician app: Update job screen to show new bookings"
echo "□ Admin panel: Add booking approval interface"