#!/bin/bash
# Run all tests for automations
# Usage: ./tst/run_all.sh

set -e

cd "$(dirname "$0")/.."

# Export LUA_PATH for luam libraries
export LUA_PATH="$HOME/Projects/luam/lib/?.lua;;"

echo "============================================================"
echo "Running automations test suite (using luam)"
echo "============================================================"

# Track overall results
total_passed=0
total_failed=0

run_test_file() {
    local test_file="$1"
    echo ""
    echo "Running: $test_file"
    echo "------------------------------------------------------------"
    
    if luam "$test_file" 2>&1; then
        echo "✓ $test_file completed"
    else
        echo "✗ $test_file had failures"
        total_failed=$((total_failed + 1))
    fi
}

# Run each test file
for test_file in tst/test_*.lua; do
    if [ -f "$test_file" ] && [ "$test_file" != "tst/test_framework.lua" ]; then
        run_test_file "$test_file"
    fi
done

echo ""
echo "============================================================"
echo "All test suites completed"
echo "============================================================"

if [ $total_failed -gt 0 ]; then
    echo "Some test suites had failures"
    exit 1
else
    echo "All test suites passed!"
    exit 0
fi
