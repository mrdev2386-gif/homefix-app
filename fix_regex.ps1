# PowerShell script to fix broken regex in technician_profile_screen.dart

$filePath = "apps\technician_app\lib\features\profile\presentation\technician_profile_screen.dart"

# Read the file
$content = Get-Content $filePath -Raw -Encoding UTF8

# Replace the broken regex pattern - multiple patterns to try
# Pattern 1: The broken regex with literal \n
$brokenPattern1 = "if (!RegExp(r'^[0-9]{9,18}`n    }`n    return null;"
$replacement1 = "if (!RegExp(r'^[0-9]{9,18}$').hasMatch(cleaned)) {
      return 'Invalid Account Number';
    }

    return null;"

if ($content -match [regex]::Escape($brokenPattern1)) {
    Write-Host "Found broken pattern 1"
    $content = $content -replace [regex]::Escape($brokenPattern1), $replacement1
} else {
    Write-Host "Pattern 1 not found, trying alternative..."
    # Try with actual newline characters
    $brokenPattern2 = "if (!RegExp(r'^[0-9]{9,18}`n    }`n    return null;`n  }`n`n  Future<void> _saveBankDetails() async {"
    $replacement2 = "if (!RegExp(r'^[0-9]{9,18}$').hasMatch(cleaned)) {
      return 'Invalid Account Number';
    }

    return null;
  }

  Future<void> _saveBankDetails() async {"
    
    if ($content -match [regex]::Escape($brokenPattern2)) {
        Write-Host "Found broken pattern 2"
        $content = $content -replace [regex]::Escape($brokenPattern2), $replacement2
    } else {
        Write-Host "Pattern 2 not found"
    }
}

# Write the fixed content back
Set-Content -Path $filePath -Value $content -Encoding UTF8 -NoNewline

Write-Host "Done!"
