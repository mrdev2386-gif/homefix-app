Phase-2 of the HomeFix Firebase Functions Cleanup has been completed following your safety guidelines. This phase focused on identifying and verifying unused legacy functions to reduce the overall function count toward the healthy 80-110 range.

📋 Phase-2 Scan & Verification Summary
Across the Customer Flutter app, Technician Flutter app, and Admin panel (Next.js):

Candidate Function	Status	Discovery/Verification Results
updateTechnicianProfileData	✅ SAFE_TO_DELETE	0 references found in any application or internal function source.

updatePrivacySettings
✅ SAFE_TO_DELETE	App calls updateUserSettingsCallable (likely a legacy mapping), zero calls to 

updatePrivacySettings
.
getFcmTokens	✅ SAFE_TO_DELETE	0 references found. FCM management now uses saveFcmToken and removeFcmToken.
removeAllFcmTokens	✅ SAFE_TO_DELETE	0 references found in logout flows or admin panel.
managePaymentMethod	⚠️ REVIEW	REFERENCED in 

apps/customer_app/lib/core/services/user_service.dart
. SKIP DELETION.
🧾 Ready-to-Run Delete Commands (Batch-1)
These commands are for the confirmed unused functions from the High-Confidence Candidates list.

IMPORTANT

To prevent these functions from being re-deployed, ensure you also comment out or remove their export const declarations in 

functions/src/index.ts
 (Lines 54, 245, 483, 520) after executing these commands.

bash
firebase functions:delete updateTechnicianProfileData --region us-central1 --force
firebase functions:delete updatePrivacySettings --region us-central1 --force
firebase functions:delete getFcmTokens --region us-central1 --force
firebase functions:delete removeAllFcmTokens --region us-central1 --force
⚠️ Medium-Risk Review (Phase C)
Results for the legacy candidates identified in Phase C:

Function Name	Status	Recommendation
toggleTechnicianServiceStatus	✅ SAFE_TO_DELETE	Technician app has migrated to toggleTechnicianServiceStatusNew.

matchTechnicians
✅ SAFE_TO_DELETE	Customer app has fully migrated to matchTechniciansV2.
updateTechnicianLastAssignment	✅ SAFE_TO_DELETE	Zero references found; matching flow is now managed by MatchingSourceV2.
getEligibleTechnicians	✅ SAFE_TO_DELETE	Replaced by matchTechniciansV2 and findEligibleTechniciansCount.
🔒 Protected Functions Confirmation
The following core flow and trigger functions were verified as UNTOCYED during this scan:

Core Ops: createBookingRequest, technicianRespondBooking, customerConfirmPayment, matchTechniciansV2.
Payments: initiateRazorpayPayment, verifyRazorpayPayment.
Triggers: onBooking*, onReview*, onPayment*, onTechnician*, cleanup*, runWalletReconciliation.
📊 Function Cleanup Projection
Metric	Count
Current Functions Exported	~140
Confirmed Unused (Batch-1)	4
Confirmed Unused (Medium-Risk)	4
Estimated Post-Phase-2 Count	~132
Target Healthy Range	80 - 110
🧠 Risk Assessment Summary
Overall Risk: LOW
Critical Catch: managePaymentMethod was flagged as "High-Confidence" but is still actively referenced in the Customer app's 

UserService
. Deleting it would have broken the payment method management UI.
Dependency Note: 

updatePrivacySettings
 is technically unused because the app points to updateUserSettingsCallable. However, updateUserSettingsCallable is currently missing from the backend source, indicating a potential bug in the app that should be addressed separately from this cleanup.
Action Plan: Execute the 4 Batch-1 commands, then proceed to Phase-3 to remove the Medium-Risk functions and their underlying source code in functions/src/matching/ and functions/src/technician/.