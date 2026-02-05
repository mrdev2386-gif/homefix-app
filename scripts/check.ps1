Write-Host "Checking Customer App..."
cd apps/customer_app
flutter analyze
dart format . 
cd ../..

Write-Host "Checking Technician App..."
cd apps/technician_app
flutter analyze
dart format . 
cd ../..

Write-Host "Checking Backend..."
cd backend
npm run lint
cd ..

Write-Host "Checking Admin Panel..."
cd apps/admin_panel
npm run lint
cd ../..
