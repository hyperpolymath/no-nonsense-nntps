#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Test script for empty-linter validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$REPO_ROOT/.githooks/validate-empty-linter.sh"
FIXTURES="$REPO_ROOT/tests/fixtures/empty-linter"

echo "=========================================="
echo "Empty-Linter Validator Test Suite"
echo "=========================================="
echo ""

# Test 1: Clean file should pass
echo "Test 1: Clean file (should pass)..."
cd "$REPO_ROOT"
if INPUT_PATH="$FIXTURES/clean-no-bom.sh" bash "$VALIDATOR" > /tmp/test-clean.log 2>&1; then
    echo "  ✓ PASS: Clean file passed validation"
else
    echo "  ✗ FAIL: Clean file was incorrectly flagged"
    cat /tmp/test-clean.log
    exit 1
fi
echo ""

# Test 2: File with UTF-8 BOM should be detected
echo "Test 2: File with UTF-8 BOM (should detect)..."
cd "$REPO_ROOT"
if INPUT_PATH="$FIXTURES/with-bom-utf8.sh" bash "$VALIDATOR" > /tmp/test-bom.log 2>&1; then
    echo "  ✗ FAIL: BOM file was not detected"
    cat /tmp/test-bom.log
    exit 1
else
    if grep -q "Leading UTF-8 BOM detected" /tmp/test-bom.log; then
        echo "  ✓ PASS: UTF-8 BOM correctly detected"
    else
        echo "  ✗ FAIL: BOM file failed but with wrong message"
        cat /tmp/test-bom.log
        exit 1
    fi
fi
echo ""

# Test 3: File with NBSP should be detected
echo "Test 3: File with NBSP (should detect)..."
cd "$REPO_ROOT"
if INPUT_PATH="$FIXTURES/with-nbsp.sh" bash "$VALIDATOR" > /tmp/test-nbsp.log 2>&1; then
    echo "  ✗ FAIL: NBSP file was not detected"
    cat /tmp/test-nbsp.log
    exit 1
else
    if grep -q "Invisible Unicode character detected" /tmp/test-nbsp.log; then
        echo "  ✓ PASS: NBSP correctly detected by PCRE pattern"
    else
        echo "  ✗ FAIL: NBSP file failed but with wrong message"
        cat /tmp/test-nbsp.log
        exit 1
    fi
fi
echo ""

echo "=========================================="
echo "All tests passed!"
echo "=========================================="
