@echo off
echo ========================================
echo Firebase Manual Token Handling Verification
echo ========================================
echo.

echo Searching for manual token handling patterns...
echo.

echo 1. Checking for getIdToken usage:
findstr /s /i "getIdToken(" *.dart | findstr /v "windows\\flutter\\ephemeral" | findstr /v "test\\"
if %errorlevel% equ 0 (
    echo ❌ FOUND manual getIdToken usage
) else (
    echo ✅ No manual getIdToken usage found
)
echo.

echo 2. Checking for token refresh logging:
findstr /s /i "Token refreshed" *.dart | findstr /v "windows\\flutter\\ephemeral"
if %errorlevel% equ 0 (
    echo ❌ FOUND token refresh logging
) else (
    echo ✅ No token refresh logging found
)
echo.

echo 3. Checking for JWT validation:
findstr /s /i "jwt" *.dart | findstr /v "windows\\flutter\\ephemeral" | findstr /v "Returns a JWT"
if %errorlevel% equ 0 (
    echo ❌ FOUND JWT validation logic
) else (
    echo ✅ No JWT validation logic found
)
echo.

echo 4. Checking for Authorization headers:
findstr /s /i "Authorization.*Bearer" *.dart | findstr /v "windows\\flutter\\ephemeral"
if %errorlevel% equ 0 (
    echo ❌ FOUND manual Authorization headers
) else (
    echo ✅ No manual Authorization headers found
)
echo.

echo 5. Verifying JWT validator file removal:
if exist "apps\technician_app\lib\core\utils\jwt_validator.dart" (
    echo ❌ JWT validator file still exists
) else (
    echo ✅ JWT validator file successfully removed
)
echo.

echo ========================================
echo VERIFICATION COMPLETE
echo ========================================
echo.
echo All Firebase callable functions should now use:
echo 1. User authentication check only
echo 2. Create callable function
echo 3. Call function (Firebase auto-attaches token)
echo.
echo Expected result:
echo - No UNAUTHENTICATED errors
echo - Clean auth flow
echo - Firebase handles token automatically
echo.

pause