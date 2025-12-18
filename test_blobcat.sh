#!/bin/bash
# Test suite for blobcat

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BLOBCAT="$SCRIPT_DIR/blobcat"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test helper functions
pass() {
    ((TESTS_PASSED++))
    echo -e "${GREEN}PASS${NC}: $1"
}

fail() {
    ((TESTS_FAILED++))
    echo -e "${RED}FAIL${NC}: $1"
    echo "  Expected: $2"
    echo "  Got: $3"
}

run_test() {
    ((TESTS_RUN++))
    echo "Running: $1"
}

# ====================
# TESTS
# ====================

test_help_flag() {
    run_test "help flag shows usage"
    local output
    output=$("$BLOBCAT" --help 2>&1) || true
    
    if echo "$output" | grep -q "Usage:"; then
        pass "help flag shows usage"
    else
        fail "help flag shows usage" "Output contains 'Usage:'" "$output"
    fi
}

test_help_shows_all_options() {
    run_test "help shows all options"
    local output
    output=$("$BLOBCAT" --help 2>&1) || true
    
    local missing=""
    echo "$output" | grep -q "\-a\|--account" || missing="$missing --account"
    echo "$output" | grep -q "\-c\|--container" || missing="$missing --container"
    echo "$output" | grep -q "\-p\|--path" || missing="$missing --path"
    echo "$output" | grep -q "\-n\|--max" || missing="$missing --max"
    
    if [ -z "$missing" ]; then
        pass "help shows all options"
    else
        fail "help shows all options" "All options documented" "Missing:$missing"
    fi
}

test_missing_account_fails() {
    run_test "missing --account fails"
    local exit_code=0
    "$BLOBCAT" --container test --path test 2>/dev/null || exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        pass "missing --account fails"
    else
        fail "missing --account fails" "Non-zero exit code" "Exit code: $exit_code"
    fi
}

test_missing_container_fails() {
    run_test "missing --container fails"
    local exit_code=0
    "$BLOBCAT" --account test --path test 2>/dev/null || exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        pass "missing --container fails"
    else
        fail "missing --container fails" "Non-zero exit code" "Exit code: $exit_code"
    fi
}

test_missing_path_fails() {
    run_test "missing --path fails"
    local exit_code=0
    "$BLOBCAT" --account test --container test 2>/dev/null || exit_code=$?
    
    if [ $exit_code -ne 0 ]; then
        pass "missing --path fails"
    else
        fail "missing --path fails" "Non-zero exit code" "Exit code: $exit_code"
    fi
}

test_short_flags_work() {
    run_test "short flags -a -c -p work"
    local output
    local exit_code=0
    # This will fail at the az check, but should get past argument parsing
    output=$("$BLOBCAT" -a test -c test -p test 2>&1) || exit_code=$?
    
    # Should not complain about missing arguments
    if ! echo "$output" | grep -qi "missing\|required"; then
        pass "short flags -a -c -p work"
    else
        fail "short flags -a -c -p work" "Arguments accepted" "$output"
    fi
}

# ====================
# RUN TESTS
# ====================

echo "========================================"
echo "blobcat test suite"
echo "========================================"
echo ""

test_help_flag
test_help_shows_all_options
test_missing_account_fails
test_missing_container_fails
test_missing_path_fails
test_short_flags_work

echo ""
echo "========================================"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed (of $TESTS_RUN)"
echo "========================================"

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
