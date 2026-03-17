@echo off
echo 🧹 Cleaning up legacy HomeFix Cloud Functions...

echo 📋 This will delete 60+ legacy Cloud Functions
echo.

set /p CONFIRM="⚠️  This will permanently delete legacy Cloud Functions. Continue? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo ❌ Cleanup cancelled
    pause
    exit /b 1
)

echo.
echo 🗑️  Deleting legacy functions...

REM Delete legacy functions one by one
firebase functions:delete deleteTechnicianServiceNew --region us-central1 --force
firebase functions:delete onCartAbandoned --region us-central1 --force
firebase functions:delete runWalletReconciliation --region us-central1 --force
firebase functions:delete toggleTechnicianServiceStatusNew --region us-central1 --force
firebase functions:delete updateTechnicianServiceNew --region us-central1 --force
firebase functions:delete adminUpdateBankStatus --region us-central1 --force
firebase functions:delete adminUpdateDocumentStatus --region us-central1 --force
firebase functions:delete admin_manageCleaningEssentials --region us-central1 --force
firebase functions:delete admin_manageProfessionalVideos --region us-central1 --force
firebase functions:delete admin_manageServiceBanners --region us-central1 --force
firebase functions:delete admin_manageTechnicianCategories --region us-central1 --force
firebase functions:delete admin_manageTechnicianSubcategories --region us-central1 --force
firebase functions:delete approveJobQuote --region us-central1 --force
firebase functions:delete bindDevice --region us-central1 --force
firebase functions:delete bulkMarkPayoutsPaid --region us-central1 --force
firebase functions:delete completeJob --region us-central1 --force
firebase functions:delete completeTraining --region us-central1 --force
firebase functions:delete confirmAfterWorkPayment --region us-central1 --force
firebase functions:delete createBookingRequest --region us-central1 --force
firebase functions:delete customerConfirmPayment --region us-central1 --force
firebase functions:delete deleteAccount --region us-central1 --force
firebase functions:delete getEligibleTechnicians --region us-central1 --force
firebase functions:delete getFcmTokens --region us-central1 --force
firebase functions:delete getPayoutAnalytics --region us-central1 --force
firebase functions:delete initiatePhoneVerification --region us-central1 --force
firebase functions:delete markPayoutPaid --region us-central1 --force
firebase functions:delete markWorkCompleted --region us-central1 --force
firebase functions:delete matchTechnicians --region us-central1 --force
firebase functions:delete notifyAdminNewBooking --region us-central1 --force
firebase functions:delete payBeforeWork --region us-central1 --force
firebase functions:delete putPayoutOnHold --region us-central1 --force
firebase functions:delete rejectBookingByAdmin --region us-central1 --force
firebase functions:delete rejectJobQuote --region us-central1 --force
firebase functions:delete releasePayoutFromHold --region us-central1 --force
firebase functions:delete removeAllFcmTokens --region us-central1 --force
firebase functions:delete reuploadVerificationDocument --region us-central1 --force
firebase functions:delete saveAvailability --region us-central1 --force
firebase functions:delete saveBankDetails --region us-central1 --force
firebase functions:delete saveExperienceDetails --region us-central1 --force
firebase functions:delete savePersonalDetails --region us-central1 --force
firebase functions:delete saveServiceArea --region us-central1 --force
firebase functions:delete saveSkillSelection --region us-central1 --force
firebase functions:delete scheduleInspection --region us-central1 --force
firebase functions:delete startInspection --region us-central1 --force
firebase functions:delete startJob --region us-central1 --force
firebase functions:delete submitApplication --region us-central1 --force
firebase functions:delete submitFullApplication --region us-central1 --force
firebase functions:delete submitInspectionReport --region us-central1 --force
firebase functions:delete technicianRespondBooking --region us-central1 --force
firebase functions:delete updateBookingStatus --region us-central1 --force
firebase functions:delete updateBookingStatusNew --region us-central1 --force
firebase functions:delete updateLocation --region us-central1 --force
firebase functions:delete updatePrivacySettings --region us-central1 --force
firebase functions:delete updateTechnicianBankDetails --region us-central1 --force
firebase functions:delete updateTechnicianLastAssignment --region us-central1 --force
firebase functions:delete updateTechnicianPersonalDetails --region us-central1 --force
firebase functions:delete updateTechnicianProfileData --region us-central1 --force
firebase functions:delete verifyBookingPayment --region us-central1 --force

echo.
echo 🎉 Legacy functions cleanup complete!
echo 🚀 You can now deploy the updated functions:
echo firebase deploy --only functions

echo.
echo ✨ Cleanup complete!
pause