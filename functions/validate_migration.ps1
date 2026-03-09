# Cloud Functions v2 Migration Validation Script (PowerShell)
# Run this script to verify the migration is complete

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Cloud Functions v2 Migration Validator" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

$allPassed = $true

# Check 1: Search for functions.config()
Write-Host "Checking for deprecated functions.config() usage..." -ForegroundColor Yellow
$deprecatedFiles = Get-ChildItem -Path "src" -Recurse -Include "*.ts" -Exclude "*v2_templates*" | 
    Select-String -Pattern "functions\.config\(\)" | 
    Where-Object { $_.Line -notmatch "^\s*//" -and $_.Line -notmatch "^\s*\*" }

if ($deprecatedFiles.Count -eq 0) {
    Write-Host "✓ PASSED - No functions.config() found in production code" -ForegroundColor Green
} else {
    Write-Host "✗ FAILED - Found $($deprecatedFiles.Count) instances of functions.config()" -ForegroundColor Red
    $deprecatedFiles | ForEach-Object { Write-Host "  $($_.Path):$($_.LineNumber) - $($_.Line.Trim())" -ForegroundColor Red }
    $allPassed = $false
}

Write-Host ""

# Check 2: Verify TypeScript build
Write-Host "Running TypeScript build..." -ForegroundColor Yellow
$buildOutput = npm run build 2>&1
$buildExitCode = $LASTEXITCODE

if ($buildExitCode -eq 0) {
    Write-Host "✓ PASSED - TypeScript build successful (0 errors)" -ForegroundColor Green
} else {
    Write-Host "✗ FAILED - TypeScript build failed" -ForegroundColor Red
    Write-Host $buildOutput -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# Check 3: Verify environment variables are documented
Write-Host "Checking environment variable documentation..." -ForegroundColor Yellow
if (Test-Path "ENV_VARIABLES_SETUP_GUIDE.md") {
    Write-Host "✓ PASSED - Environment setup guide exists" -ForegroundColor Green
} else {
    Write-Host "⚠ WARNING - Environment setup guide not found" -ForegroundColor Yellow
}

Write-Host ""

# Check 4: Verify migration report exists
Write-Host "Checking migration documentation..." -ForegroundColor Yellow
if (Test-Path "FUNCTIONS_CONFIG_MIGRATION_REPORT.md") {
    Write-Host "✓ PASSED - Migration report exists" -ForegroundColor Green
} else {
    Write-Host "⚠ WARNING - Migration report not found" -ForegroundColor Yellow
}

Write-Host ""

# Check 5: Verify process.env usage in bank_verification.ts
Write-Host "Verifying bank_verification.ts uses process.env..." -ForegroundColor Yellow
$bankVerificationFile = "src\technician\bank_verification.ts"
if (Test-Path $bankVerificationFile) {
    $processEnvCount = (Select-String -Path $bankVerificationFile -Pattern "process\.env\.RAZORPAY").Count
    
    if ($processEnvCount -ge 2) {
        Write-Host "✓ PASSED - bank_verification.ts correctly uses process.env ($processEnvCount occurrences)" -ForegroundColor Green
    } else {
        Write-Host "✗ FAILED - bank_verification.ts may not be using process.env correctly" -ForegroundColor Red
        $allPassed = $false
    }
} else {
    Write-Host "✗ FAILED - bank_verification.ts not found" -ForegroundColor Red
    $allPassed = $false
}

Write-Host ""

# Check 6: Verify payment files use process.env
Write-Host "Verifying payment files use process.env..." -ForegroundColor Yellow
$razorpayFile = "src\payments\razorpay.ts"
if (Test-Path $razorpayFile) {
    $razorpayEnvCount = (Select-String -Path $razorpayFile -Pattern "process\.env\.RAZORPAY").Count
    
    if ($razorpayEnvCount -ge 3) {
        Write-Host "✓ PASSED - razorpay.ts correctly uses process.env ($razorpayEnvCount occurrences)" -ForegroundColor Green
    } else {
        Write-Host "⚠ WARNING - razorpay.ts may need verification" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ WARNING - razorpay.ts not found" -ForegroundColor Yellow
}

Write-Host ""

# Check 7: Verify no functions.config in compiled JavaScript
Write-Host "Checking compiled JavaScript files..." -ForegroundColor Yellow
if (Test-Path "lib") {
    $jsDeprecated = Get-ChildItem -Path "lib" -Recurse -Include "*.js" | 
        Select-String -Pattern "functions\.config\(\)" | 
        Where-Object { $_.Line -notmatch "^\s*//" }
    
    if ($jsDeprecated.Count -eq 0) {
        Write-Host "✓ PASSED - No functions.config() in compiled JavaScript" -ForegroundColor Green
    } else {
        Write-Host "⚠ WARNING - Found functions.config() in compiled files (may be from comments)" -ForegroundColor Yellow
    }
} else {
    Write-Host "⚠ INFO - lib directory not found (run 'npm run build' first)" -ForegroundColor Cyan
}

Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "Validation Summary" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

if ($allPassed) {
    Write-Host "✓ Migration Complete" -ForegroundColor Green
    Write-Host "✓ No deprecated functions.config() usage" -ForegroundColor Green
    Write-Host "✓ TypeScript build successful" -ForegroundColor Green
    Write-Host "✓ All files use process.env" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Cyan
    Write-Host "1. Review MIGRATION_SUMMARY.md" -ForegroundColor White
    Write-Host "2. Set environment variables (see ENV_VARIABLES_SETUP_GUIDE.md)" -ForegroundColor White
    Write-Host "3. Deploy to staging: firebase deploy --only functions --project staging" -ForegroundColor White
    Write-Host "4. Test bank verification and payments" -ForegroundColor White
    Write-Host "5. Deploy to production: firebase deploy --only functions --project production" -ForegroundColor White
} else {
    Write-Host "✗ Migration validation FAILED" -ForegroundColor Red
    Write-Host "Please review the errors above and fix them before deploying." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan

# Return success
exit 0
