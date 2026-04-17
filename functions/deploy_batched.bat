@echo off
cd /d C:\Users\yash\projects\homefix\functions

echo === BUILDING FUNCTIONS ===
call npm run build
if %errorlevel% neq 0 (
    echo BUILD FAILED - aborting deploy
    exit /b 1
)
echo BUILD OK

echo.
echo === BATCH 1: Failing functions (priority) ===
call firebase deploy --only functions:admin_manageCategory,functions:cleanupOTPRateLimits,functions:cleanupOldIdempotencyRecords,functions:markBookingActive,functions:rejectBooking,functions:retryRefundCompensation,functions:triggerTechnicianPayout
echo Batch 1 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 2: Booking lifecycle ===
call firebase deploy --only functions:createBookingRequest,functions:approveBookingByAdmin,functions:rejectBookingByAdmin,functions:technicianAcceptBooking,functions:startService,functions:completeService,functions:technicianRejectBooking,functions:cancelBooking,functions:adminChangeTechnician,functions:getAllTechniciansForAdmin
echo Batch 2 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 3: Payments ===
call firebase deploy --only functions:createPaymentOrder,functions:verifyPayment,functions:createRazorpayOrder,functions:initiateRefund,functions:handlePaymentFailure,functions:canRetryPayment,functions:razorpayPayoutWebhook,functions:settleTechnicianBalance,functions:refundBookingPayment
echo Batch 3 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 4: Technician onboarding ===
call firebase deploy --only functions:createTechnicianProfile,functions:saveTechnicianBasicDetails,functions:saveTechnicianDocuments,functions:saveTechnicianServices,functions:submitTechnicianKyc,functions:updateTechnicianStatus,functions:saveTechnicianStepData,functions:updateTechnicianPersonalDetails,functions:updateTechnicianBankDetails,functions:reuploadVerificationDocument
echo Batch 4 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 5: Bank verification ===
call firebase deploy --only functions:verifyTechnicianBankAccountSecure,functions:verifyTechnicianBankAccount,functions:razorpayBankWebhook,functions:checkBankVerificationStatus,functions:cleanupStuckBankVerifications,functions:cleanupOldIdempotencyRecords,functions:adminUpdateBankStatus,functions:adminUpdateDocumentStatus
echo Batch 5 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 6: Admin functions ===
call firebase deploy --only functions:admin_getDashboardStats,functions:admin_getUsers,functions:admin_getUserById,functions:admin_updateUser,functions:admin_blockUser,functions:admin_manageUser,functions:admin_getTechnicians,functions:admin_getTechnicianById,functions:admin_updateTechnician,functions:admin_approveTechnician,functions:admin_approveKYC,functions:admin_suspendTechnician
echo Batch 6 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 7: Admin services + moderation ===
call firebase deploy --only functions:admin_manageService,functions:createService,functions:updateService,functions:deleteService,functions:admin_approveService,functions:admin_rejectService,functions:admin_disableService,functions:approveBooking,functions:updateBookingPayment,functions:admin_manageBooking
echo Batch 7 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 8: Customer features ===
call firebase deploy --only functions:updateUserProfile,functions:manageAddress,functions:manageAddressSecure,functions:setPrimaryAddress,functions:validateAddressForBooking,functions:addToCartCallable,functions:updateCartQuantityCallable,functions:removeFromCartCallable,functions:clearCartCallable,functions:toggleFavoriteCallable,functions:managePaymentMethod,functions:validateReferralCode
echo Batch 8 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 9: Notifications + triggers ===
call firebase deploy --only functions:saveFcmToken,functions:removeFcmToken,functions:markNotificationRead,functions:markAllNotificationsRead,functions:deleteNotificationCallable,functions:deleteAllNotificationsCallable,functions:onBookingStatusChange,functions:onBookingStatusChangeNotify,functions:onUserCreated,functions:onTechnicianApproved
echo Batch 9 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 10: Finance + wallet ===
call firebase deploy --only functions:processWalletTransaction,functions:createWithdrawalRequest,functions:approveWithdrawalRequest,functions:rejectWithdrawalRequest,functions:getWithdrawalRequests,functions:getMyWithdrawalRequests,functions:migrateSingleWallet,functions:getPendingCompensations,functions:autoRetryCompensations,functions:walletReconciliationDisabled,functions:triggerManualReconciliation
echo Batch 10 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 11: Scheduled cleanup + health ===
call firebase deploy --only functions:cleanupStaleBookings,functions:cleanupExpiredIdempotencyRecords,functions:checkOTPRateLimitCallable,functions:cleanupOTPRateLimits,functions:healthCheck,functions:onBookingPaidGenerateInvoice,functions:onStaleTechnicianCleanup
echo Batch 11 done. Waiting 15s...
timeout /t 15 /nobreak >nul

echo.
echo === BATCH 12: Chat + matching + misc ===
call firebase deploy --only functions:getOrCreateChat,functions:sendChatMessage,functions:markMessagesRead,functions:getChatDetails,functions:assignTechnicianToBooking,functions:matchTechniciansV2,functions:respondToAssignment,functions:toggleOnlineStatus,functions:submitKYC,functions:evaluateTechnicianKyc,functions:checkKycStatus
echo Batch 12 done.

echo.
echo === ALL BATCHES COMPLETE ===
