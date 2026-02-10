#!/usr/bin/env bash
# CI/CD compatibility test for script-dialog library
# Tests that the library can be sourced without errors in headless environments

set -e  # Exit on any error

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXIT_CODE=0

echo "Testing CI/CD compatibility..."
echo ""

# Test 1: With TERM=dumb (common in CI environments)
echo "Test 1: TERM=dumb (common in CI)"
export TERM=dumb
# shellcheck source=../script-dialog.sh
# shellcheck disable=SC1091  # Source file path is constructed at runtime
if output=$(source "${SCRIPT_DIR}"/../script-dialog.sh 2>&1); then
    if echo "$output" | grep -iq "tput.*error\|no value for"; then
        echo "  ✗ FAILED: tput errors detected in output"
        echo "$output"
        EXIT_CODE=1
    else
        echo "  ✓ PASSED: Library loaded without tput errors"
    fi
else
    echo "  ✗ FAILED: Library failed to source"
    EXIT_CODE=1
fi

# Clean up for next test
unset INTERFACE bold red yellow normal underline

# Test 2: With TERM unset (also common in CI)
echo "Test 2: TERM unset"
unset TERM
# shellcheck source=../script-dialog.sh
# shellcheck disable=SC1091  # Source file path is constructed at runtime
if output=$(source "${SCRIPT_DIR}"/../script-dialog.sh 2>&1); then
    if echo "$output" | grep -iq "tput.*error\|no value for"; then
        echo "  ✗ FAILED: tput errors detected in output"
        echo "$output"
        EXIT_CODE=1
    else
        echo "  ✓ PASSED: Library loaded without tput errors"
    fi
else
    echo "  ✗ FAILED: Library failed to source"
    EXIT_CODE=1
fi

# Clean up for next test
unset INTERFACE bold red yellow normal underline

# Test 3: With normal TERM (ensure we didn't break normal usage)
echo "Test 3: TERM=xterm-256color (normal usage)"
export TERM=xterm-256color
# shellcheck source=../script-dialog.sh
# shellcheck disable=SC1091  # Source file path is constructed at runtime
if output=$(source "${SCRIPT_DIR}"/../script-dialog.sh 2>&1); then
    if echo "$output" | grep -iq "error"; then
        echo "  ✗ FAILED: Unexpected errors in output"
        echo "$output"
        EXIT_CODE=1
    else
        echo "  ✓ PASSED: Library loaded successfully"
    fi
else
    echo "  ✗ FAILED: Library failed to source"
    EXIT_CODE=1
fi

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "All CI/CD compatibility tests passed ✓"
else
    echo "Some CI/CD compatibility tests failed ✗"
fi

exit $EXIT_CODE
