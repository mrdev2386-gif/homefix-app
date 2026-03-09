@echo off
echo Building and deploying admin panel...

cd apps\admin_panel

echo Installing dependencies...
call npm install

echo Building Next.js app...
call npm run build

echo Deploying to Firebase Hosting...
cd ..\..
call firebase deploy --only hosting

echo Deployment complete!
pause