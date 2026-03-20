# Delete Old Firebase Functions

Write-Host "🗑️  Deleting Old Firebase Functions" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

$functions = @(
    "deleteTechnicianServiceNew",
    "onCartAbandoned",
    "runWalletReconciliation",
    "toggleTechnicianServiceStatusNew",
    "updateTechnicianServiceNew",
    "adminUpdateBankStatus",
    "adminUpdateDocumentStatus",
    "admin_manageCleaningEssentials",
    "admin_manageProfessionalVideos",
    "admin_manageServiceBanners",
    "admin_manageTechnicianCategories",
    "admin_manageTechnicianSubcategories",
    "approveJobQuote",
    "bindDevice",
    "bulkMarkPayoutsPaid",
    "completeJob",
    "completeTraining",
    "confirmAfterWorkPayment",
    "createBookingRequest",
    "customerConfirmPayment",
    "deleteAccount",
    "getEligibleTechnicians",
    "getFcmTokens",
    "getPayoutAnalytics",
    "initiatePhoneVerification",
    "markPayoutPaid",
    "markWorkCompleted",
    "matchTechnicians",
    "notifyAdminNewBooking",
    "payBeforeWork",
    "putPayoutOnHold",
    "rejectBookingByAdmin",
    "rejectJobQuote",
    "releasePayoutFromHold",
    "removeAllFcmTokens",
    "reuploadVerificationDocument",
    "saveAvailability",
    "saveBankDetails",
    "saveExperienceDetails",
    "savePersonalDetails",
    "saveServiceArea",
    "saveSkillSelection",
    "scheduleInspection",
    "startInspection",
    "startJob",
    "submitApplication",
    "submitFullApplication",
    "submitInspectionReport",
    "updateBookingStatus",
    "updateLocation",
    "updatePrivacySettings",
    "updateTechnicianBankDetails",
    "updateTechnicianLastAssignment",
    "updateTechnicianPersonalDetails",
    "updateTechnicianProfileData",
    "verifyBookingPayment"
)

$total = $functions.Count
$current = 0

foreach ($func in $functions) {
    $current++
    Write-Host "[$current/$total] Deleting $func..." -ForegroundColor Yellow
    
    firebase functions:delete $func --region us-central1 --force 2>&1 | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✅ Deleted" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️  Already deleted or error" -ForegroundColor Gray
    }
}

Write-Host ""
Write-Host "✅ Cleanup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next step: Deploy functions" -ForegroundColor Cyan
Write-Host "  cd functions" -ForegroundColor White
Write-Host "  npm run build" -ForegroundColor White
Write-Host "  firebase deploy --only functions" -ForegroundColor White
Write-Host ""
