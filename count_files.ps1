cd c:\Users\yash\projects\homefix\functions\src

$files = @(
  @{name='technician/onboarding.ts'; type='Callable - Technician Onboarding'},
  @{name='technician/profile_management.ts'; type='Callable - Technician Profile'},
  @{name='technician/bank_verification.ts'; type='Callable + Webhook - Bank Verification'},
  @{name='booking/booking_notifications.ts'; type='Trigger - Firestore (onUpdate)'},
  @{name='custom_requests/custom_request_notifications.ts'; type='Trigger - Firestore (onUpdate)'},
  @{name='booking/booking_lifecycle.ts'; type='Callable - Booking Lifecycle'},
  @{name='technician/services_management.ts'; type='Callable - Service Management'},
  @{name='payments/razorpay.ts'; type='Callable + Webhook - Payments'},
  @{name='custom_request.ts'; type='Callable - Custom Requests'},
  @{name='customer_features.ts'; type='Callable + Trigger - Customer Features'},
  @{name='technician/kyc.ts'; type='Callable - KYC Evaluation'},
  @{name='payments/payouts.ts'; type='Callable - Payouts'},
  @{name='technician/application.ts'; type='Callable - Technician Application'}
)

Write-Host "=== FILE METRICS ===" -ForegroundColor Cyan
Write-Host ""

foreach ($file in $files) {
  $path = $file.name
  if (Test-Path $path) {
    $lines = (Get-Content $path | Measure-Object -Line).Lines
    Write-Host "$($path) - $lines lines ($($file.type))"
  }
}
