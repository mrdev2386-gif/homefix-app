# Fix Firebase Functions v1 onCall syntax

$files = @(
    "src\customer_features.ts",
    "src\index.ts",
    "src\instant_booking.ts"
)

foreach ($file in $files) {
    Write-Host "Fixing $file..."
    
    # Read content
    $content = Get-Content $file -Raw
    
    # Fix: async (data, context) => to async (data: any, context: any) =>
    $content = $content -replace 'async \(data, context\) =>', 'async (data: any, context: any) =>'
    
    # Write back
    Set-Content $file $content -NoNewline
}

Write-Host "Done!"
