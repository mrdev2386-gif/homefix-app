#!/bin/bash

# Deploy Secure Booking Lifecycle Cloud Functions
# This script deploys all booking management functions

echo "🚀 Deploying Booking Lifecycle Cloud Functions..."

cd functions

# Build TypeScript
echo "📦 Building TypeScript..."
npm run build

# Deploy functions
echo "🔧 Deploying functions..."
firebase deploy --only \
  functions:notifyAdminNewBooking,\
  functions:approveBookingByAdmin,\
  functions:rejectBookingByAdmin,\
  functions:technicianAcceptBooking,\
  functions:technicianStartJob,\
  functions:completeBooking,\
  functions:cancelBooking,\
  functions:technicianRejectBooking,\
  functions:verifyBookingPayment,\
  functions:refundBookingPayment

echo "✅ Deployment complete!"
echo ""
echo "📋 Deployed Functions:"
echo "  - notifyAdminNewBooking (trigger)"
echo "  - approveBookingByAdmin"
echo "  - rejectBookingByAdmin"
echo "  - technicianAcceptBooking"
echo "  - technicianStartJob"
echo "  - completeBooking"
echo "  - cancelBooking"
echo "  - technicianRejectBooking"
echo "  - verifyBookingPayment"
echo "  - refundBookingPayment (NEW)"
echo ""
echo "🔍 Verify deployment:"
echo "  firebase functions:list"
