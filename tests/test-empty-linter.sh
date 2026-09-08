#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Test script for empty-linter validation

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
VALIDATOR="$REPO_ROOT/.githooks/validate-empty-linter.sh"
FIXTURES="$REPO_ROOT/tests/fixtures/empty-linter"
TEST_TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TEST_TMPDIR"' EXIT

echo "=========================================="
echo "Empty-Linter Validator Test Suite"
echo "=========================================="
echo ""

# Test 1: Clean file should pass
echo "Test 1: Clean file (should pass)..."
cd "$REPO_ROOT"
if INPUT_PATH="$FIXTURES/clean-no-bom.sh" bash "$VALIDATOR" > "$TEST_TMPDIR/clean.log" 2>&1; then
    echo "  ✓ PASS: Clean file passed validation"
else
    echo "  ✗ FAIL: Clean file was incorrectly flagged"
    cat "$TEST_TMPDIR/clean.log"
    exit 1
fi
echo ""

# Test 2: File with UTF-8 BOM should be detected
echo "Test 2: File with UTF-8 BOM (should detect)..."
cd "$REPO_ROOT"
if INPUT_PATH="$FIXTURES/with-bom-utf8.sh" bash "$VALIDATOR" > "$TEST_TMPDIR/bom.log" 2>&1; then
    echo "  ✗ FAIL: BOM file was not detected"
    cat "$TEST_TMPDIR/bom.log"
    exit 1
else
    if grep -q "Leading UTF-8 BOM detected" "$TEST_TMPDIR/bom.log"; then
        echo "  ✓ PASS: UTF-8 BOM correctly detected"
    else
        echo "  ✗ FAIL: BOM file failed but with wrong message"
        cat "$TEST_TMPDIR/bom.log"
        exit 1
    fi
fi
echo ""

# Test 3: File with NBSP should be detected
echo "Test 3: File with NBSP (should detect)..."
cd "$REPO_ROOT"
if INPUT_PATH="$FIXTURES/with-nbsp.sh" bash "$VALIDATOR" > "$TEST_TMPDIR/nbsp.log" 2>&1; then
    echo "  ✗ FAIL: NBSP file was not detected"
    cat "$TEST_TMPDIR/nbsp.log"
    exit 1
else
    if grep -q "Invisible Unicode character detected" "$TEST_TMPDIR/nbsp.log"; then
        echo "  ✓ PASS: NBSP correctly detected by PCRE pattern"
    else
        echo "  ✗ FAIL: NBSP file failed but with wrong message"
        cat "$TEST_TMPDIR/nbsp.log"
        exit 1
    fi
fi
echo ""

# Test 4: File with zero-width space should be detected
echo "Test 4: File with zero-width space (should detect)..."
if INPUT_PATH="$FIXTURES/with-zero-width-space.sh" bash "$VALIDATOR" > "$TEST_TMPDIR/zero-width.log" 2>&1; then
    echo "  ✗ FAIL: Zero-width-space file was not detected"
    cat "$TEST_TMPDIR/zero-width.log"
    exit 1
elif grep -q "Invisible Unicode character detected" "$TEST_TMPDIR/zero-width.log"; then
    echo "  ✓ PASS: Zero-width space correctly detected by PCRE pattern"
else
    echo "  ✗ FAIL: Zero-width-space file failed but with wrong message"
    cat "$TEST_TMPDIR/zero-width.log"
    exit 1
fi
echo ""

echo "=========================================="
echo "All tests passed!"
echo "=========================================="
