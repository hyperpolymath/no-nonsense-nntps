#!/usr/bin/env bash
# SPDX-License-Identifier: MPL-2.0
# Copyright (c) 2026 Jonathan D.A. Jewell (hyperpolymath) <j.d.a.jewell@open.ac.uk>
#
# validate-empty-linter.sh — Empty-linter: invisible character detection
#
# Performs two complementary scans to detect invisible/problematic characters:
#   1. PCRE pattern scan: zero-width spaces, joiners, BOM, soft hyphens,
#      non-breaking spaces, null bytes, C0 control characters, etc.
#   2. Byte-wise leading-BOM scan: raw byte-level check for BOM markers at
#      the start of files (EF BB BF for UTF-8, FF FE / FE FF for UTF-16,
#      etc.) — added as a separate check because regex-based BOM detection
#      can be locale-dependent or unreliable.
#
# The byte-wise scan catches leading BOMs that might be missed by the PCRE
# pattern, ensuring robust detection regardless of locale settings or grep
# implementation quirks.
#
# Environment variables:
#   INPUT_PATH         — Directory to scan (default: .)
#   INPUT_PATHS_IGNORE — Newline-separated path fragments to skip
#
# Exit codes:
#   0 — All files clean
#   1 — Invisible characters or BOMs detected

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

SCAN_PATH="${INPUT_PATH:-.}"
PATHS_IGNORE_RAW="${INPUT_PATHS_IGNORE:-}"
GITHUB_OUTPUT_FILE="${GITHUB_OUTPUT:-/dev/null}"
GITHUB_WORKSPACE="${GITHUB_WORKSPACE:-$(pwd)}"
TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT

FIXTURE_DIR="$(realpath -m "$GITHUB_WORKSPACE/tests/fixtures/empty-linter")"
SCAN_PATH_ABS="$(realpath -m "$SCAN_PATH")"
FIXTURE_FIND_ARGS=(-not -path '*/tests/fixtures/empty-linter/*')
if [[ "$SCAN_PATH_ABS" == "$FIXTURE_DIR" || "$SCAN_PATH_ABS" == "$FIXTURE_DIR"/* ]]; then
    FIXTURE_FIND_ARGS=()
fi

# Parse paths-ignore: newline-separated fragments, blank lines and # comments
# stripped. Each fragment is a substring match against the file path.
PATHS_IGNORE=()
while IFS= read -r _frag; do
    # Strip leading and trailing whitespace
    _frag="${_frag#"${_frag%%[![:space:]]*}"}"
    _frag="${_frag%"${_frag##*[![:space:]]}"}"
    [[ -z "$_frag" || "$_frag" == \#* ]] && continue
    PATHS_IGNORE+=("$_frag")
done <<< "$PATHS_IGNORE_RAW"

# Returns 0 if path should be skipped (matches any ignore fragment)
path_ignored() {
    local p="$1" frag
    for frag in "${PATHS_IGNORE[@]}"; do
        [[ "$p" == *"$frag"* ]] && return 0
    done
    return 1
}

# Counters
FILES_WITH_ISSUES=0

# Track files already flagged to avoid double-counting
declare -A FLAGGED_FILES

# File extensions to scan
FILE_PATTERNS=(
    -name '*.rs' -o -name '*.ex' -o -name '*.exs' -o -name '*.res'
    -o -name '*.js' -o -name '*.ts' -o -name '*.json' -o -name '*.toml'
    -o -name '*.yml' -o -name '*.yaml' -o -name '*.md' -o -name '*.adoc'
    -o -name '*.idr' -o -name '*.zig' -o -name '*.v' -o -name '*.jl'
    -o -name '*.gleam' -o -name '*.hs' -o -name '*.ml' -o -name '*.sh'
)

# ---------------------------------------------------------------------------
# Helper: emit GitHub annotation
# ---------------------------------------------------------------------------
annotate() {
    local level="$1" file="$2" message="$3"
    local rel_path="${file#"$GITHUB_WORKSPACE"/}"
    echo "::${level} file=${rel_path}::${message}"
}

# ---------------------------------------------------------------------------
# Scan 1: PCRE pattern-based invisible character detection
# ---------------------------------------------------------------------------
scan_pcre_patterns() {
    echo "Scan 1: PCRE pattern for invisible Unicode characters..."
    echo ""

    # PCRE pattern for invisible characters:
    # - (*UTF) modifier: locale-independent UTF-8 mode
    # - \x00-\x08, \x0B, \x0C, \x0E-\x1F: C0 control characters (excluding TAB, LF, CR)
    # - \x{a0}: non-breaking space (NBSP)
    # - \x{ad}: soft hyphen
    # - \x{200b}-\x{200f}: zero-width space, joiners, directional marks
    # - \x{202a}-\x{202f}: bidi formatting characters, narrow no-break space
    # - \x{2060}: word joiner
    # - \x{2066}-\x{2069}: directional isolates
    # - \x{feff}: zero-width no-break space / BOM
    local PATTERNS='(*UTF)[\x00-\x08\x0B\x0C\x0E-\x1F\x{a0}\x{ad}\x{200b}-\x{200f}\x{202a}-\x{202f}\x{2060}\x{2066}-\x{2069}\x{feff}]'

    local pcre_results="$TEMP_DIR/pcre-results"
    local files_to_check="$TEMP_DIR/pcre-files"

    # Run find + grep with PCRE patterns
    # -a: treat binary files as text (so NUL bytes don't cause skips)
    # -P: Perl-compatible regex
    # -l: list filenames only
    find "$SCAN_PATH" \
        -not -path '*/.git/*' -not -path '*/node_modules/*' \
        -not -path '*/.deno/*' -not -path '*/target/*' \
        -not -path '*/_build/*' -not -path '*/deps/*' \
        -not -path '*/external_corpora/*' -not -path '*/.lake/*' \
        "${FIXTURE_FIND_ARGS[@]}" \
        -type f \( "${FILE_PATTERNS[@]}" \) -print0 > "$files_to_check"

    : > "$pcre_results"
    local filepath pcre_exit
    while IFS= read -r -d '' filepath; do
        if ! iconv -f UTF-8 -t UTF-8 -- "$filepath" >/dev/null 2>&1; then
            echo "::error file=${filepath}::Invisible-character scan failed: invalid UTF-8 input"
            return 2
        fi
        pcre_exit=0
        grep -aPl "$PATTERNS" -- "$filepath" >> "$pcre_results" 2>/dev/null || pcre_exit=$?
        if [[ "$pcre_exit" -ne 0 && "$pcre_exit" -ne 1 ]]; then
            echo "::error file=${filepath}::PCRE invisible-character scan failed with status ${pcre_exit}"
            return "$pcre_exit"
        fi
    done < "$files_to_check"

    local pcre_count=0
    if [[ -f "$pcre_results" ]]; then
        pcre_count=$(wc -l < "$pcre_results" 2>/dev/null || echo 0)

        # Emit annotations for each file
        while IFS= read -r filepath; do
            [[ -z "$filepath" ]] && continue

            # Skip ignored paths
            if path_ignored "$filepath"; then
                continue
            fi

            # Track this file to avoid double-counting
            if [[ -z "${FLAGGED_FILES[$filepath]:-}" ]]; then
                FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
                FLAGGED_FILES[$filepath]=1
            fi

            annotate "warning" "$filepath" "Invisible Unicode character detected (PCRE scan: zero-width space, BOM, NBSP, C0 control, etc.)"
        done < "$pcre_results"

    fi

    echo "  Found $pcre_count file(s) with invisible characters (PCRE pattern)"
    echo ""

    return 0
}

# ---------------------------------------------------------------------------
# Scan 2: Byte-wise leading-BOM detection
# ---------------------------------------------------------------------------
scan_leading_bom() {
    echo "Scan 2: Byte-wise leading-BOM scan..."
    echo ""

    # BOM byte sequences:
    # - EF BB BF: UTF-8 BOM
    # - FF FE: UTF-16 LE BOM
    # - FE FF: UTF-16 BE BOM
    # - FF FE 00 00: UTF-32 LE BOM
    # - 00 00 FE FF: UTF-32 BE BOM
    #
    # This raw byte-level check supplements the PCRE pattern because:
    # 1. grep -P can be locale-dependent when matching \x{feff}
    # 2. Some grep implementations may interpret BOMs as encoding markers
    #    rather than matchable characters
    # 3. A BOM at the start of a file is particularly problematic (breaks
    #    shebangs, SPDX headers, parsers expecting ASCII-clean starts)

    local bom_results="$TEMP_DIR/bom-results"

    # Find all files to check
    local files_to_check="$TEMP_DIR/bom-files"
    find "$SCAN_PATH" \
        -not -path '*/.git/*' -not -path '*/node_modules/*' \
        -not -path '*/.deno/*' -not -path '*/target/*' \
        -not -path '*/_build/*' -not -path '*/deps/*' \
        -not -path '*/external_corpora/*' -not -path '*/.lake/*' \
        "${FIXTURE_FIND_ARGS[@]}" \
        -type f \( "${FILE_PATTERNS[@]}" \) > "$files_to_check" 2>/dev/null

    # Check each file for leading BOM bytes
    : > "$bom_results"
    while IFS= read -r filepath; do
        [[ -z "$filepath" ]] && continue

        # Skip ignored paths
        if path_ignored "$filepath"; then
            continue
        fi

        # Read first 4 bytes and check for BOM signatures
        local first_bytes
        if [[ -f "$filepath" && -r "$filepath" ]]; then
            # Use xxd, od, or python to read raw bytes (in order of preference)
            if command -v xxd >/dev/null 2>&1; then
                first_bytes=$(xxd -p -l 4 "$filepath" 2>/dev/null | tr -d '\n' || echo "")
            elif command -v od >/dev/null 2>&1; then
                first_bytes=$(od -An -tx1 -N4 "$filepath" 2>/dev/null | tr -d ' \n' || echo "")
            elif command -v python3 >/dev/null 2>&1; then
                first_bytes=$(python3 -c "import sys; sys.stdout.write(''.join(f'{b:02x}' for b in open('$filepath', 'rb').read(4)))" 2>/dev/null || echo "")
            else
                # Fallback: skip this file if no tool available
                continue
            fi

            # Check for various BOM patterns
            if [[ "$first_bytes" =~ ^efbbbf ]]; then
                echo "$filepath" >> "$bom_results"
                annotate "warning" "$filepath" "Leading UTF-8 BOM detected (EF BB BF) at start of file - BOMs should not be used in source files"
                # Only increment counter if not already flagged
                if [[ -z "${FLAGGED_FILES[$filepath]:-}" ]]; then
                    FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
                    FLAGGED_FILES[$filepath]=1
                fi
            elif [[ "$first_bytes" =~ ^fffe0000 ]]; then
                echo "$filepath" >> "$bom_results"
                annotate "warning" "$filepath" "Leading UTF-32 LE BOM detected (FF FE 00 00) at start of file"
                if [[ -z "${FLAGGED_FILES[$filepath]:-}" ]]; then
                    FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
                    FLAGGED_FILES[$filepath]=1
                fi
            elif [[ "$first_bytes" =~ ^0000feff ]]; then
                echo "$filepath" >> "$bom_results"
                annotate "warning" "$filepath" "Leading UTF-32 BE BOM detected (00 00 FE FF) at start of file"
                if [[ -z "${FLAGGED_FILES[$filepath]:-}" ]]; then
                    FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
                    FLAGGED_FILES[$filepath]=1
                fi
            elif [[ "$first_bytes" =~ ^fffe ]]; then
                echo "$filepath" >> "$bom_results"
                annotate "warning" "$filepath" "Leading UTF-16 LE BOM detected (FF FE) at start of file"
                if [[ -z "${FLAGGED_FILES[$filepath]:-}" ]]; then
                    FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
                    FLAGGED_FILES[$filepath]=1
                fi
            elif [[ "$first_bytes" =~ ^feff ]]; then
                echo "$filepath" >> "$bom_results"
                annotate "warning" "$filepath" "Leading UTF-16 BE BOM detected (FE FF) at start of file"
                if [[ -z "${FLAGGED_FILES[$filepath]:-}" ]]; then
                    FILES_WITH_ISSUES=$((FILES_WITH_ISSUES + 1))
                    FLAGGED_FILES[$filepath]=1
                fi
            fi
        fi
    done < "$files_to_check"

    local bom_count=0
    if [[ -f "$bom_results" ]]; then
        bom_count=$(wc -l < "$bom_results" 2>/dev/null || echo 0)
    fi

    echo "  Found $bom_count file(s) with leading BOM markers (byte-wise scan)"
    echo ""

    return 0
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

echo "::group::Empty-Linter (Invisible Character Detection)"
echo "Scanning ${SCAN_PATH} for invisible characters and BOMs..."
echo ""

# Run both scans
scan_pcre_patterns
scan_leading_bom

echo "────────────────────────────────────────"
echo "Files with issues: ${FILES_WITH_ISSUES}"
echo "────────────────────────────────────────"

# Write outputs for GitHub Actions
{
    echo "findings=${FILES_WITH_ISSUES}"
    echo "exit_code=$((FILES_WITH_ISSUES > 0 ? 1 : 0))"
    echo "ready=true"
} >> "$GITHUB_OUTPUT_FILE" 2>/dev/null || true

echo "::endgroup::"

# Exit with failure if issues were found
if [[ $FILES_WITH_ISSUES -gt 0 ]]; then
    echo "::error::Empty-linter found ${FILES_WITH_ISSUES} file(s) with invisible characters or BOMs"
    exit 1
fi

echo "Empty-linter: All files clean."
exit 0
