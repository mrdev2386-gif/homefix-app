@echo off
echo ========================================
echo 🚀 Deploying Reviews, Disputes ^& Risk Modules
echo ========================================
echo.

cd /d "%~dp0functions"

echo 📦 Step 1: Building Cloud Functions...
call npm run build
if %errorlevel% neq 0 (
    echo ❌ Build failed. Please fix errors and try again.
    pause
    exit /b 1
)

echo.
echo ☁️  Step 2: Deploying Cloud Functions...
call firebase deploy --only functions:admin_manageReview,functions:admin_manageDispute,functions:admin_manageRiskProfile
if %errorlevel% neq 0 (
    echo ❌ Function deployment failed.
    pause
    exit /b 1
)

echo.
echo 📊 Step 3: Deploying Firestore Indexes...
call firebase deploy --only firestore:indexes

echo.
echo 🎨 Step 4: Building Admin Panel...
cd ..\apps\admin_panel
call npm run build
if %errorlevel% neq 0 (
    echo ❌ Admin panel build failed.
    pause
    exit /b 1
)

echo.
echo 🌐 Step 5: Deploying Admin Panel...
call firebase deploy --only hosting

echo.
echo ========================================
echo ✅ Deployment Complete!
echo ========================================
echo.
echo 📝 Next Steps:
echo 1. Verify Cloud Functions are active in Firebase Console
echo 2. Check Firestore indexes are building
echo 3. Test each module in the admin panel
echo 4. Review activity logs for admin actions
echo.
echo 📖 Documentation: REVIEWS_DISPUTES_RISK_IMPLEMENTATION.md
echo.
pause
