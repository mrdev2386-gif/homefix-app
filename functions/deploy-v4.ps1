# Firebase Functions v4 Deployment Script
# This script deploys the downgraded firebase-functions v4.4.1

Write-Host "🔧 Firebase Functions v4 Deployment" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Navigate to functions directory
Write-Host "📁 Step 1: Navigating to functions directory..." -ForegroundColor Yellow
Set-Location "C:\Users\yash\projects\homefix\functions"
Write-Host "✅ Current directory: $(Get-Location)" -ForegroundColor Green
Write-Host ""

# Step 2: Clean old dependencies
Write-Host "🧹 Step 2: Cleaning old dependencies..." -ForegroundColor Yellow
if (Test-Path "node_modules") {
    Write-Host "   Removing node_modules..." -ForegroundColor Gray
    Remove-Item -Recurse -Force node_modules
    Write-Host "   ✅ node_modules removed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ node_modules not found (already clean)" -ForegroundColor Gray
}

if (Test-Path "package-lock.json") {
    Write-Host "   Removing package-lock.json..." -ForegroundColor Gray
    Remove-Item -Force package-lock.json
    Write-Host "   ✅ package-lock.json removed" -ForegroundColor Green
} else {
    Write-Host "   ℹ️ package-lock.json not found (already clean)" -ForegroundColor Gray
}
Write-Host ""

# Step 3: Install dependencies
Write-Host "📦 Step 3: Installing compatible versions..." -ForegroundColor Yellow
Write-Host "   firebase-functions: ^4.4.1" -ForegroundColor Gray
Write-Host "   firebase-admin: ^11.11.1" -ForegroundColor Gray
Write-Host ""
npm install
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Dependencies installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ npm install failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 4: Verify versions
Write-Host "🔍 Step 4: Verifying installed versions..." -ForegroundColor Yellow
$packageJson = Get-Content "package.json" | ConvertFrom-Json
Write-Host "   firebase-functions: $($packageJson.dependencies.'firebase-functions')" -ForegroundColor Gray
Write-Host "   firebase-admin: $($packageJson.dependencies.'firebase-admin')" -ForegroundColor Gray
Write-Host "✅ Versions verified" -ForegroundColor Green
Write-Host ""

# Step 5: Build functions
Write-Host "🔨 Step 5: Building TypeScript functions..." -ForegroundColor Yellow
npm run build
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Build successful" -ForegroundColor Green
} else {
    Write-Host "❌ Build failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 6: Deploy to Firebase
Write-Host "🚀 Step 6: Deploying to Firebase..." -ForegroundColor Yellow
Write-Host "   Region: asia-south1" -ForegroundColor Gray
Write-Host "   Project: homefix-aa42d" -ForegroundColor Gray
Write-Host ""
firebase deploy --only functions
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Deployment successful" -ForegroundColor Green
} else {
    Write-Host "❌ Deployment failed" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Step 7: Summary
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host "✅ DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📊 Summary:" -ForegroundColor Cyan
Write-Host "   • firebase-functions downgraded to v4.4.1" -ForegroundColor White
Write-Host "   • firebase-admin downgraded to v11.11.1" -ForegroundColor White
Write-Host "   • Functions built successfully" -ForegroundColor White
Write-Host "   • Functions deployed to asia-south1" -ForegroundColor White
Write-Host ""
Write-Host "🧪 Next Steps:" -ForegroundColor Cyan
Write-Host "   1. Test 'Add to Cart' in customer app" -ForegroundColor White
Write-Host "   2. Test 'Toggle Favorite' in customer app" -ForegroundColor White
Write-Host "   3. Check backend logs for request.auth.uid" -ForegroundColor White
Write-Host ""
Write-Host "📝 Expected Result:" -ForegroundColor Cyan
Write-Host "   ✅ No UNAUTHENTICATED errors" -ForegroundColor Green
Write-Host "   ✅ Backend receives request.auth.uid" -ForegroundColor Green
Write-Host "   ✅ All Cloud Functions work" -ForegroundColor Green
Write-Host ""
