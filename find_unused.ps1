$files = Get-ChildItem -Path "apps\customer_app\lib" -Recurse -Filter "*.dart"
$unusedFiles = @()

foreach ($file in $files) {
    if ($file.Name -in @("main.dart", "firebase_options.dart")) { continue }
    $isUsed = $false
    foreach ($otherFile in $files) {
        if ($otherFile.FullName -eq $file.FullName) { continue }
        if (Select-String -Path $otherFile.FullName -Pattern $file.Name -Quiet) {
            $isUsed = $true
            break
        }
    }
    if (-not $isUsed) {
        $unusedFiles += $file.FullName
    }
}
Write-Output "--- Customer Unused ---"
$unusedFiles
