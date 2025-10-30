#!/bin/bash

# Integration test script for Sandbox Environment Manager
# Tests API, scripts, and environment creation

set -e

echo "=========================================="
echo "Sandbox Environment Manager - Test Suite"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
    echo -e "${GREEN}?${NC} $1"
}

fail() {
    echo -e "${RED}?${NC} $1"
}

warn() {
    echo -e "${YELLOW}?${NC} $1"
}

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    ((TESTS_RUN++))
    if eval "$1"; then
        pass "$2"
        ((TESTS_PASSED++))
        return 0
    else
        fail "$2"
        ((TESTS_FAILED++))
        return 1
    fi
}

echo "Running tests..."
echo ""

# 1. Check prerequisites
echo "1. Checking Prerequisites"
echo "   ?????????????????????"

run_test "command -v node &>/dev/null" "Node.js installed"
run_test "command -v npm &>/dev/null" "npm installed"
run_test "command -v bash &>/dev/null" "Bash shell available"
run_test "command -v az &>/dev/null" "Azure CLI installed"
run_test "command -v kubectl &>/dev/null" "kubectl installed"

if command -v jq &>/dev/null; then
    pass "jq installed (optional)"
else
    warn "jq not installed (optional but recommended)"
fi

echo ""

# 2. Check project structure
echo "2. Checking Project Structure"
echo "   ??????????????????????????"

run_test "test -d api" "api/ directory exists"
run_test "test -f api/server.js" "api/server.js exists"
run_test "test -f api/package.json" "api/package.json exists"
run_test "test -d api/routes" "api/routes/ directory exists"
run_test "test -d api/services" "api/services/ directory exists"

run_test "test -d ui" "ui/ directory exists"
run_test "test -f ui/index.html" "ui/index.html exists"

run_test "test -d scripts" "scripts/ directory exists"
run_test "test -f scripts/create_env.sh" "scripts/create_env.sh exists"
run_test "test -f scripts/delete_env.sh" "scripts/delete_env.sh exists"
run_test "test -f scripts/list_envs.sh" "scripts/list_envs.sh exists"

echo ""

# 3. Check API dependencies
echo "3. Checking API Dependencies"
echo "   ?????????????????????????"

if [ -d "api/node_modules" ]; then
    pass "API dependencies installed"
else
    warn "API dependencies not installed"
    echo "   Run: cd api && npm install"
fi

echo ""

# 4. Check Azure authentication
echo "4. Checking Azure Authentication"
echo "   ??????????????????????????????"

if az account show &>/dev/null; then
    ACCOUNT=$(az account show --query "name" -o tsv)
    pass "Azure CLI authenticated (Account: $ACCOUNT)"
else
    fail "Azure CLI not authenticated"
    echo "   Run: az login"
fi

echo ""

# 5. Test API (if running)
echo "5. Testing API Endpoints"
echo "   ?????????????????????"

API_URL="http://localhost:3000"

if curl -s "${API_URL}/api/health" &>/dev/null; then
    pass "API is running"
    
    # Test health endpoint
    HEALTH_STATUS=$(curl -s "${API_URL}/api/health" | grep -o '"status":"healthy"')
    if [ "$HEALTH_STATUS" == '"status":"healthy"' ]; then
        pass "Health check endpoint working"
    else
        fail "Health check endpoint not returning healthy status"
    fi
    
    # Test environments endpoint
    if curl -s "${API_URL}/api/envs" | grep -q '\['; then
        pass "Environments endpoint responding"
    else
        fail "Environments endpoint not responding correctly"
    fi
    
else
    warn "API is not running"
    echo "   Start with: cd api && npm start"
fi

echo ""

# 6. Check existing environments
echo "6. Checking Existing Environments"
echo "   ??????????????????????????????"

ENV_FILES=(.env-*.json)
if [[ -e "${ENV_FILES[0]}" ]]; then
    ENV_COUNT=$(ls -1 .env-*.json 2>/dev/null | wc -l)
    pass "Found $ENV_COUNT environment(s)"
    
    for file in .env-*.json; do
        if [ -f "$file" ]; then
            ENV_NAME=$(basename "$file" | sed 's/^\.env-//' | sed 's/\.json$//')
            echo "   • $ENV_NAME"
        fi
    done
else
    warn "No environments found"
    echo "   Create one with: ./scripts/create_env.sh --name test-env"
fi

echo ""

# 7. Test script executability
echo "7. Checking Script Permissions"
echo "   ???????????????????????????"

if [ -x "scripts/create_env.sh" ]; then
    pass "create_env.sh is executable"
else
    warn "create_env.sh is not executable"
    echo "   Run: chmod +x scripts/*.sh"
fi

if [ -x "scripts/delete_env.sh" ]; then
    pass "delete_env.sh is executable"
else
    warn "delete_env.sh is not executable"
fi

echo ""

# 8. Test dry run functionality
echo "8. Testing Script Dry Run"
echo "   ??????????????????????"

if bash scripts/create_env.sh --name test-dry-run --dry-run &>/dev/null; then
    pass "create_env.sh dry run works"
else
    fail "create_env.sh dry run failed"
fi

echo ""

# Summary
echo "=========================================="
echo "Test Summary"
echo "=========================================="
echo "Total Tests:  $TESTS_RUN"
echo -e "${GREEN}Passed:${NC}      $TESTS_PASSED"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed:${NC}      $TESTS_FAILED"
else
    echo "Failed:       0"
fi
echo "=========================================="
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}? All tests passed!${NC}"
    echo ""
    echo "Your environment is ready to use!"
    echo ""
    echo "Next steps:"
    echo "  1. Start API: cd api && npm start"
    echo "  2. Open UI: Open ui/index.html in browser"
    echo "  3. Create environment: ./scripts/create_env.sh --name env1"
    exit 0
else
    echo -e "${RED}? Some tests failed${NC}"
    echo ""
    echo "Please fix the issues above and run tests again"
    exit 1
fi
