@echo off
setlocal enabledelayedexpansion

REM Read the service account JSON file
for /f "delims=" %%A in (serviceAccountKey.json) do (
  set "line=%%A"
  set "FIREBASE_SERVICE_ACCOUNT=!FIREBASE_SERVICE_ACCOUNT!!line!"
)

REM Run the Node script
node setAdminRole.js %1

endlocal
