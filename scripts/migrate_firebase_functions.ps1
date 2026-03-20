# Firebase Functions Global Instance Migration Script
# Automatically replaces all FirebaseFunctions.instance usages with global instance

Write-Host "🔥 Firebase Functions Global Instance Migration" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

$rootPath = "C:\Users\yash\projects\homefix\apps"
$customerAppPath = "$rootPath\customer_app\lib"
$technicianAppPath = "$rootPath\technician_app\lib"

# Files to update in customer app
$customerFiles = @(
    "core\services\auth_service.dart",
    "core\services\firestore_service.dart",
    "core\services\notifications_service.dart",
    "features\booking\presentation\customer_booking_screen.dart",
    "features\bookings\presentation\rate_technician_screen.dart",
    "features\bookings\presentation\rating_screen.dart",
    "features\job_details\presentation\job_details_screen.dart",
    "features\services\presentation\instant_booking_screen.dart",
    "features\urgent\urgent_booking_screen.dart"
)

# Files to update in technician app
$technicianFiles = @(
    "core\services\functions_service.dart",
    "core\services\booking_service.dart",
    "core\services\onboarding_service.dart",
    "core\services\technician_catalog_service.dart",
    "core\services\technician_service.dart",
    "core\services\wallet_service.dart",
    "core\services\notifications_service.dart",
    "core\providers\technician_provider.dart",
    "features\custom_requests_screen.dart",
    "features\job_requests\technician_job_screen.dart",
    "features\kyc\presentation\kyc_status_screen.dart"
)

function Update-FirebaseFunctionsUsage {
    param(
        [string]$FilePath,
        [string]$AppType
    )
    
    if (-not (Test-Path $FilePath)) {
        Write-Host "  ⚠️  File not found: $FilePath" -ForegroundColor Yellow
        return
    }
    
    $content = Get-Content $FilePath -Raw
    $originalContent = $content
    $modified = $false
    
    # Add import if not present
    if ($content -notmatch "import.*firebase_functions_instance\.dart") {
        # Find the last import statement
        if ($content -match "(?s)(import[^;]+;)(?!.*import)") {
            $lastImport = $matches[1]
            $importToAdd = "`nimport '../firebase/firebase_functions_instance.dart';"
            if ($content -match "core/firebase/") {
                $importToAdd = "`nimport '../firebase/firebase_functions_instance.dart';"
            } elseif ($content -match "features/") {
                $importToAdd = "`nimport '../../core/firebase/firebase_functions_instance.dart';"
            } elseif ($content -match "core/services/") {
                $importToAdd = "`nimport '../firebase/firebase_functions_instance.dart';"
            } elseif ($content -match "core/providers/") {
                $importToAdd = "`nimport '../firebase/firebase_functions_instance.dart';"
            }
            $content = $content -replace [regex]::Escape($lastImport), "$lastImport$importToAdd"
            $modified = $true
        }
    }
    
    # Replace instance declarations
    $patterns = @(
        @{
            Old = "final FirebaseFunctions _functions = FirebaseFunctions\.instance;"
            New = "FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;"
        },
        @{
            Old = "final FirebaseFunctions _functions = FirebaseFunctions\.instanceFor\(region: 'us-central1'\);"
            New = "FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;"
        },
        @{
            Old = "late final FirebaseFunctions _functions;[\r\n\s]+_functions = FirebaseFunctions\.instance;"
            New = "FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;"
        },
        @{
            Old = "final _functions = FirebaseFunctions\.instance;"
            New = "FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;"
        },
        @{
            Old = "final functions = FirebaseFunctions\.instance;"
            New = "final functions = FirebaseFunctionsInstance.instance;"
        },
        @{
            Old = "FirebaseFunction get _functions => FirebaseFunctions\.instance;"
            New = "FirebaseFunctions get _functions => FirebaseFunctionsInstance.instance;"
        }
    )
    
    foreach ($pattern in $patterns) {
        if ($content -match $pattern.Old) {
            $content = $content -replace $pattern.Old, $pattern.New
            $modified = $true
        }
    }
    
    # Replace inline usages
    $inlinePatterns = @(
        "FirebaseFunctions\.instance\.httpsCallable",
        "FirebaseFunctions\.instanceFor\(region: 'us-central1'\)\.httpsCallable"
    )
    
    foreach ($pattern in $inlinePatterns) {
        if ($content -match $pattern) {
            $content = $content -replace $pattern, "FirebaseFunctionsInstance.instance.httpsCallable"
            $modified = $true
        }
    }
    
    if ($modified) {
        Set-Content -Path $FilePath -Value $content -NoNewline
        Write-Host "  ✅ Updated: $FilePath" -ForegroundColor Green
        return $true
    } else {
        Write-Host "  ⏭️  No changes needed: $FilePath" -ForegroundColor Gray
        return $false
    }
}

# Update Customer App
Write-Host "📱 Updating Customer App..." -ForegroundColor Yellow
$customerUpdated = 0
foreach ($file in $customerFiles) {
    $fullPath = Join-Path $customerAppPath $file
    if (Update-FirebaseFunctionsUsage -FilePath $fullPath -AppType "customer") {
        $customerUpdated++
    }
}

Write-Host ""
Write-Host "📱 Updating Technician App..." -ForegroundColor Yellow
$technicianUpdated = 0
foreach ($file in $technicianFiles) {
    $fullPath = Join-Path $technicianAppPath $file
    if (Update-FirebaseFunctionsUsage -FilePath $fullPath -AppType "technician") {
        $technicianUpdated++
    }
}

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "✅ Migration Complete!" -ForegroundColor Green
Write-Host "   Customer App: $customerUpdated files updated" -ForegroundColor White
Write-Host "   Technician App: $technicianUpdated files updated" -ForegroundColor White
Write-Host ""
Write-Host "⚠️  IMPORTANT: Manual verification required for:" -ForegroundColor Yellow
Write-Host "   1. Auth readiness checks (ensureAuthReady + 500ms delay)" -ForegroundColor White
Write-Host "   2. Token refresh (getIdToken(true))" -ForegroundColor White
Write-Host "   3. Import paths (adjust ../../../ as needed)" -ForegroundColor White
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Run: flutter pub get (in both apps)" -ForegroundColor White
Write-Host "   2. Verify no compilation errors" -ForegroundColor White
Write-Host "   3. Test function calls after login" -ForegroundColor White
Write-Host "   4. Check for UNAUTHENTICATED errors" -ForegroundColor White
Write-Host ""
