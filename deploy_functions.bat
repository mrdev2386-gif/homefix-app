@echo off
echo Deploying Cloud Functions to asia-south1...

cd functions
firebase deploy --only functions:updateTechnicianPersonalDetails --force

echo.
echo Deployment complete!
pause