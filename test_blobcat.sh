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

# Test cache directory (isolated from real cache)
export BLOBCAT_CACHE_DIR=$(mktemp -d)
trap "rm -rf '$BLOBCAT_CACHE_DIR'" EXIT

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
# ARGUMENT PARSING TESTS
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
    echo "$output" | grep -q "\-j\|--jobs" || missing="$missing --jobs"
    echo "$output" | grep -q "\--no-cache" || missing="$missing --no-cache"
    echo "$output" | grep -q "\--cache-clean" || missing="$missing --cache-clean"
    echo "$output" | grep -q "\--cache-info" || missing="$missing --cache-info"
    
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
    # Use timeout to prevent hanging on az cli checks
    output=$(timeout 5 "$BLOBCAT" -a test -c test -p test 2>&1) || exit_code=$?
    
    # Should not complain about missing arguments
    if ! echo "$output" | grep -qi "missing\|required"; then
        pass "short flags -a -c -p work"
    else
        fail "short flags -a -c -p work" "Arguments accepted" "$output"
    fi
}

test_jobs_flag_accepted() {
    run_test "-j/--jobs flag accepted"
    local output
    local exit_code=0
    # Use timeout to prevent hanging on az cli checks
    output=$(timeout 5 "$BLOBCAT" -a test -c test -p test -j 4 2>&1) || exit_code=$?
    
    # Should not complain about unknown option (exit due to az cli is ok)
    if ! echo "$output" | grep -qi "unknown option"; then
        pass "-j/--jobs flag accepted"
    else
        fail "-j/--jobs flag accepted" "Flag accepted" "$output"
    fi
}

test_no_cache_flag_accepted() {
    run_test "--no-cache flag accepted"
    local output
    local exit_code=0
    # Use timeout to prevent hanging on az cli checks
    output=$(timeout 5 "$BLOBCAT" -a test -c test -p test --no-cache 2>&1) || exit_code=$?
    
    # Should not complain about unknown option (exit due to az cli is ok)
    if ! echo "$output" | grep -qi "unknown option"; then
        pass "--no-cache flag accepted"
    else
        fail "--no-cache flag accepted" "Flag accepted" "$output"
    fi
}

# ====================
# CACHE MANAGEMENT TESTS
# ====================

test_cache_info_works() {
    run_test "--cache-info works"
    local output
    local exit_code=0
    output=$("$BLOBCAT" --cache-info 2>&1) || exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && echo "$output" | grep -qi "cache directory"; then
        pass "--cache-info works"
    else
        fail "--cache-info works" "Shows cache info" "Exit: $exit_code, Output: $output"
    fi
}

test_cache_info_shows_stats() {
    run_test "--cache-info shows statistics"
    local output
    output=$("$BLOBCAT" --cache-info 2>&1)
    
    local missing=""
    echo "$output" | grep -qi "cache directory" || missing="$missing directory"
    echo "$output" | grep -qi "cached files" || missing="$missing files"
    echo "$output" | grep -qi "total size" || missing="$missing size"
    
    if [ -z "$missing" ]; then
        pass "--cache-info shows statistics"
    else
        fail "--cache-info shows statistics" "All stats shown" "Missing:$missing"
    fi
}

test_cache_clean_works() {
    run_test "--cache-clean works"
    
    # Create a dummy cache
    mkdir -p "$BLOBCAT_CACHE_DIR/blobs/test"
    echo "test" > "$BLOBCAT_CACHE_DIR/blobs/test/file.txt"
    
    local output
    local exit_code=0
    output=$("$BLOBCAT" --cache-clean 2>&1) || exit_code=$?
    
    if [[ $exit_code -eq 0 ]] && [[ ! -d "$BLOBCAT_CACHE_DIR" ]]; then
        pass "--cache-clean works"
    else
        fail "--cache-clean works" "Cache removed" "Exit: $exit_code, Dir exists: $(test -d "$BLOBCAT_CACHE_DIR" && echo yes || echo no)"
    fi
    
    # Recreate cache dir for subsequent tests
    mkdir -p "$BLOBCAT_CACHE_DIR"
}

test_cache_clean_on_nonexistent() {
    run_test "--cache-clean on nonexistent dir"
    
    # Ensure cache doesn't exist
    rm -rf "$BLOBCAT_CACHE_DIR"
    
    local output
    local exit_code=0
    output=$("$BLOBCAT" --cache-clean 2>&1) || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass "--cache-clean on nonexistent dir"
    else
        fail "--cache-clean on nonexistent dir" "Exit 0" "Exit: $exit_code"
    fi
    
    # Recreate for subsequent tests
    mkdir -p "$BLOBCAT_CACHE_DIR"
}

test_cache_dir_env_var() {
    run_test "BLOBCAT_CACHE_DIR env var respected"
    local output
    output=$("$BLOBCAT" --cache-info 2>&1)
    
    if echo "$output" | grep -q "$BLOBCAT_CACHE_DIR"; then
        pass "BLOBCAT_CACHE_DIR env var respected"
    else
        fail "BLOBCAT_CACHE_DIR env var respected" "Custom dir in output" "$output"
    fi
}

# ====================
# CACHE COMMANDS DON'T REQUIRE AZURE ARGS
# ====================

test_cache_info_no_azure_args() {
    run_test "--cache-info doesn't require Azure args"
    local exit_code=0
    "$BLOBCAT" --cache-info >/dev/null 2>&1 || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass "--cache-info doesn't require Azure args"
    else
        fail "--cache-info doesn't require Azure args" "Exit 0" "Exit: $exit_code"
    fi
}

test_cache_clean_no_azure_args() {
    run_test "--cache-clean doesn't require Azure args"
    local exit_code=0
    "$BLOBCAT" --cache-clean >/dev/null 2>&1 || exit_code=$?
    
    if [[ $exit_code -eq 0 ]]; then
        pass "--cache-clean doesn't require Azure args"
    else
        fail "--cache-clean doesn't require Azure args" "Exit 0" "Exit: $exit_code"
    fi
    
    # Recreate for subsequent tests
    mkdir -p "$BLOBCAT_CACHE_DIR"
}

# ====================
# RUN TESTS
# ====================

echo "========================================"
echo "blobcat test suite"
echo "========================================"
echo ""

# Argument parsing tests
test_help_flag
test_help_shows_all_options
test_missing_account_fails
test_missing_container_fails
test_missing_path_fails
test_short_flags_work
test_jobs_flag_accepted
test_no_cache_flag_accepted

# Cache management tests
test_cache_info_works
test_cache_info_shows_stats
test_cache_clean_works
test_cache_clean_on_nonexistent
test_cache_dir_env_var
test_cache_info_no_azure_args
test_cache_clean_no_azure_args

echo ""
echo "========================================"
echo "Results: $TESTS_PASSED passed, $TESTS_FAILED failed (of $TESTS_RUN)"
echo "========================================"

if [ $TESTS_FAILED -gt 0 ]; then
    exit 1
fi
