# Fix onCall syntax - remove enforceAppCheck parameter

$files = @("src\customer_features.ts", "src\index.ts", "src\instant_booking.ts")

foreach ($file in $files) {
    Write-Host "Processing $file..."
    $content = Get-Content $file -Raw
    
    # Remove the enforceAppCheck object parameter (handles multi-line)
    $content = $content -replace '(?s)functions\.https\.onCall\(\s*\{\s*enforceAppCheck:\s*false\s*\},\s*', 'functions.https.onCall('
    
    Set-Content $file $content -NoNewline
}

Write-Host "Done!"
