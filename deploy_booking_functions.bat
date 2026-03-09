@echo off
REM Deploy Secure Booking Lifecycle Cloud Functions

echo Deploying Booking Lifecycle Cloud Functions...

cd functions

REM Build TypeScript
echo Building TypeScript...
call npm run build

REM Deploy functions
echo Deploying functions...
call firebase deploy --only functions:notifyAdminNewBooking,functions:approveBookingByAdmin,functions:rejectBookingByAdmin,functions:technicianAcceptBooking,functions:technicianStartJob,functions:completeBooking,functions:cancelBooking,functions:technicianRejectBooking,functions:verifyBookingPayment,functions:refundBookingPayment

echo.
echo Deployment complete!
echo.
echo Deployed Functions:
echo   - notifyAdminNewBooking (trigger)
echo   - approveBookingByAdmin
echo   - rejectBookingByAdmin
echo   - technicianAcceptBooking
echo   - technicianStartJob
echo   - completeBooking
echo   - cancelBooking
echo   - technicianRejectBooking
echo   - verifyBookingPayment
echo   - refundBookingPayment (NEW)
echo.
echo Verify deployment:
echo   firebase functions:list

pause
