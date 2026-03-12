#!/usr/bin/env pwsh

# Firebase Functions Gen1 to Gen2 Migration Script
# This script systematically migrates all functions.https.onCall to Gen2 onCall

$srcPath = "c:\Users\yash\projects\homefix\functions\src"
$files = Get-ChildItem -Path $srcPath -Filter "*.ts" -Recurse

Write-Host "Found $(($files).Count) TypeScript files to scan"

$filesWithGen1 = @()

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw
    
    if ($content -match 'functions\.https\.onCall') {
        $filesWithGen1 += $file.FullName
        Write-Host "[$($filesWithGen1.Count)] $($file.Name)"
    }
}

Write-Host "`nTotal files needing Gen1->Gen2 migration: $($filesWithGen1.Count)"
Write-Host "Sample files:"
$filesWithGen1 | Select-Object -First 10 | ForEach-Object { Write-Host "  $_" }
