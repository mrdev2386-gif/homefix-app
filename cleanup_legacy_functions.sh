#!/bin/bash

# HomeFix Legacy Functions Cleanup Script
# This script removes old/duplicate Cloud Functions that are no longer needed

echo "🧹 Cleaning up legacy HomeFix Cloud Functions..."

# Array of legacy functions to delete
LEGACY_FUNCTIONS=(
    "deleteTechnicianServiceNew"
    "onCartAbandoned"
    "runWalletReconciliation"
    "toggleTechnicianServiceStatusNew"
    "updateTechnicianServiceNew"
    "adminUpdateBankStatus"
    "adminUpdateDocumentStatus"
    "admin_manageCleaningEssentials"
    "admin_manageProfessionalVideos"
    "admin_manageServiceBanners"
    "admin_manageTechnicianCategories"
    "admin_manageTechnicianSubcategories"
    "approveJobQuote"
    "bindDevice"
    "bulkMarkPayoutsPaid"
    "completeJob"
    "completeTraining"
    "confirmAfterWorkPayment"
    "createBookingRequest"
    "customerConfirmPayment"
    "deleteAccount"
    "getEligibleTechnicians"
    "getFcmTokens"
    "getPayoutAnalytics"
    "initiatePhoneVerification"
    "markPayoutPaid"
    "markWorkCompleted"
    "matchTechnicians"
    "notifyAdminNewBooking"
    "payBeforeWork"
    "putPayoutOnHold"
    "rejectBookingByAdmin"
    "rejectJobQuote"
    "releasePayoutFromHold"
    "removeAllFcmTokens"
    "reuploadVerificationDocument"
    "saveAvailability"
    "saveBankDetails"
    "saveExperienceDetails"
    "savePersonalDetails"
    "saveServiceArea"
    "saveSkillSelection"
    "scheduleInspection"
    "startInspection"
    "startJob"
    "submitApplication"
    "submitFullApplication"
    "submitInspectionReport"
    "technicianRespondBooking"
    "updateBookingStatus"
    "updateBookingStatusNew"
    "updateLocation"
    "updatePrivacySettings"
    "updateTechnicianBankDetails"
    "updateTechnicianLastAssignment"
    "updateTechnicianPersonalDetails"
    "updateTechnicianProfileData"
    "verifyBookingPayment"
)

echo "📋 Found ${#LEGACY_FUNCTIONS[@]} legacy functions to delete"
echo ""

# Ask for confirmation
read -p "⚠️  This will permanently delete ${#LEGACY_FUNCTIONS[@]} Cloud Functions. Continue? (y/N): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Cleanup cancelled"
    exit 1
fi

echo ""
echo "🗑️  Deleting legacy functions..."

# Delete each function
DELETED_COUNT=0
FAILED_COUNT=0

for func in "${LEGACY_FUNCTIONS[@]}"; do
    echo "Deleting $func..."
    if firebase functions:delete "$func" --region us-central1 --force; then
        ((DELETED_COUNT++))
        echo "✅ Deleted $func"
    else
        ((FAILED_COUNT++))
        echo "❌ Failed to delete $func"
    fi
    echo ""
done

echo ""
echo "📊 Cleanup Summary:"
echo "✅ Successfully deleted: $DELETED_COUNT functions"
echo "❌ Failed to delete: $FAILED_COUNT functions"
echo "📦 Total processed: ${#LEGACY_FUNCTIONS[@]} functions"

if [ $FAILED_COUNT -eq 0 ]; then
    echo ""
    echo "🎉 All legacy functions cleaned up successfully!"
    echo "🚀 You can now deploy the updated functions:"
    echo "firebase deploy --only functions"
else
    echo ""
    echo "⚠️  Some functions failed to delete. Please check the errors above."
    echo "You may need to delete them manually from the Firebase Console."
fi

echo ""
echo "✨ Cleanup complete!"