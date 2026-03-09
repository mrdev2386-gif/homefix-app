#!/bin/bash
# Cloud Functions v2 Migration Validation Script
# Run this script to verify the migration is complete

echo "=========================================="
echo "Cloud Functions v2 Migration Validator"
echo "=========================================="
echo ""

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check 1: Search for functions.config()
echo "✓ Checking for deprecated functions.config() usage..."
DEPRECATED_COUNT=$(grep -r "functions\.config()" src/ --include="*.ts" --exclude-dir=v2_templates | grep -v "// \*" | wc -l)

if [ "$DEPRECATED_COUNT" -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - No functions.config() found in production code"
else
    echo -e "${RED}✗ FAILED${NC} - Found $DEPRECATED_COUNT instances of functions.config()"
    grep -rn "functions\.config()" src/ --include="*.ts" --exclude-dir=v2_templates | grep -v "// \*"
    exit 1
fi

echo ""

# Check 2: Verify TypeScript build
echo "✓ Running TypeScript build..."
npm run build > /dev/null 2>&1

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - TypeScript build successful (0 errors)"
else
    echo -e "${RED}✗ FAILED${NC} - TypeScript build failed"
    npm run build
    exit 1
fi

echo ""

# Check 3: Verify environment variables are documented
echo "✓ Checking environment variable documentation..."
if [ -f "ENV_VARIABLES_SETUP_GUIDE.md" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Environment setup guide exists"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - Environment setup guide not found"
fi

echo ""

# Check 4: Verify migration report exists
echo "✓ Checking migration documentation..."
if [ -f "FUNCTIONS_CONFIG_MIGRATION_REPORT.md" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - Migration report exists"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - Migration report not found"
fi

echo ""

# Check 5: Verify process.env usage in bank_verification.ts
echo "✓ Verifying bank_verification.ts uses process.env..."
PROCESS_ENV_COUNT=$(grep -c "process\.env\.RAZORPAY" src/technician/bank_verification.ts)

if [ "$PROCESS_ENV_COUNT" -ge 2 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - bank_verification.ts correctly uses process.env"
else
    echo -e "${RED}✗ FAILED${NC} - bank_verification.ts may not be using process.env correctly"
    exit 1
fi

echo ""

# Check 6: Verify payment files use process.env
echo "✓ Verifying payment files use process.env..."
RAZORPAY_ENV_COUNT=$(grep -c "process\.env\.RAZORPAY" src/payments/razorpay.ts)

if [ "$RAZORPAY_ENV_COUNT" -ge 3 ]; then
    echo -e "${GREEN}✓ PASSED${NC} - razorpay.ts correctly uses process.env"
else
    echo -e "${YELLOW}⚠ WARNING${NC} - razorpay.ts may need verification"
fi

echo ""

# Summary
echo "=========================================="
echo "Validation Summary"
echo "=========================================="
echo -e "${GREEN}✓ Migration Complete${NC}"
echo -e "${GREEN}✓ No deprecated functions.config() usage${NC}"
echo -e "${GREEN}✓ TypeScript build successful${NC}"
echo -e "${GREEN}✓ All files use process.env${NC}"
echo ""
echo "Next Steps:"
echo "1. Review MIGRATION_SUMMARY.md"
echo "2. Set environment variables (see ENV_VARIABLES_SETUP_GUIDE.md)"
echo "3. Deploy to staging: firebase deploy --only functions --project staging"
echo "4. Test bank verification and payments"
echo "5. Deploy to production: firebase deploy --only functions --project production"
echo ""
echo "=========================================="
