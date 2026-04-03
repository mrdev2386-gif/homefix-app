# Fix all Cloud Functions to add .region('asia-south1')

$files = @(
    "src\admin\bookings.ts",
    "src\admin\booking_moderation.ts",
    "src\admin\catalog_audit.ts",
    "src\admin\dashboard.ts",
    "src\admin\data_migration.ts",
    "src\admin\disputes.ts",
    "src\admin\dynamic_content.ts",
    "src\admin\finance.ts",
    "src\admin\images.ts",
    "src\admin\migrate_booking_status.ts",
    "src\admin\notifications.ts",
    "src\admin\reviews.ts",
    "src\admin\risk.ts",
    "src\admin\serviceApproval.ts",
    "src\admin\services.ts",
    "src\admin\service_management.ts",
    "src\admin\system_initialization.ts",
    "src\admin\technicians.ts",
    "src\admin\technician_approval.ts",
    "src\admin\technician_management.ts",
    "src\admin\technician_normalization.ts",
    "src\admin\users.ts",
    "src\booking\complete_booking_flow.ts",
    "src\booking\final_hardening.ts",
    "src\booking\new_booking_flow.ts",
    "src\booking\production_hardening.ts",
    "src\booking_actions.ts",
    "src\finance\payout_logic.ts",
    "src\finance\technician_withdrawal.ts",
    "src\finance\wallet_reconciliation.ts",
    "src\index.ts",
    "src\instant_booking.ts",
    "src\matching\engine.ts",
    "src\matching\matching_v2.ts",
    "src\matching\matchTechniciansV2.ts",
    "src\matching\technician_matching.ts",
    "src\notifications_management.ts",
    "src\partner\applications.ts",
    "src\payments\payouts.ts",
    "src\technician\application.ts",
    "src\technician\bank_verification.ts",
    "src\technician\booking_actions_hardened.ts",
    "src\technician\kyc.ts",
    "src\technician\onboarding.ts",
    "src\technician\security.ts",
    "src\testing\actions.ts",
    "src\testing\factory.ts"
)

foreach ($file in $files) {
    $fullPath = "c:\Users\yash\projects\homefix\functions\$file"
    
    if (Test-Path $fullPath) {
        Write-Host "Processing: $file"
        
        $content = Get-Content $fullPath -Raw
        
        # Replace functions.https.onCall with functions.region('asia-south1').https.onCall
        # Only if it doesn't already have .region
        $newContent = $content -replace "functions\.https\.onCall\(", "functions.region('asia-south1').https.onCall("
        
        # Write back
        Set-Content -Path $fullPath -Value $newContent -NoNewline
        
        Write-Host "  ✓ Fixed: $file"
    } else {
        Write-Host "  ✗ Not found: $file"
    }
}

Write-Host ""
Write-Host "All functions updated with region"
Write-Host "Now run: npm run build"
Write-Host "Then run: firebase deploy --only functions"
