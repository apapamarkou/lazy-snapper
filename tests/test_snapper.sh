#!/usr/bin/env bash
# test_snapper.sh — Tests for lib/snapper.sh (with mocked snapper)

set -euo pipefail

PASS=0; FAIL=0

# ── Helpers ───────────────────────────────────────────────────────────────

assert_eq() {
    local desc="$1" expected="$2" actual="$3"
    if [[ "${expected}" == "${actual}" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS+1))
    else
        echo "  FAIL: ${desc}"
        echo "        expected: '${expected}'"
        echo "        actual:   '${actual}'"
        FAIL=$((FAIL+1))
    fi
}

assert_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if echo "${haystack}" | grep -qF "${needle}"; then
        echo "  PASS: ${desc}"
        PASS=$((PASS+1))
    else
        echo "  FAIL: ${desc} — '${needle}' not found in output"
        FAIL=$((FAIL+1))
    fi
}

assert_not_contains() {
    local desc="$1" needle="$2" haystack="$3"
    if ! echo "${haystack}" | grep -qF "${needle}"; then
        echo "  PASS: ${desc}"
        PASS=$((PASS+1))
    else
        echo "  FAIL: ${desc} — '${needle}' unexpectedly found in output"
        FAIL=$((FAIL+1))
    fi
}

# ── Mock snapper ──────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Create a mock snapper binary in a temp dir and prepend to PATH
MOCK_BIN_DIR=$(mktemp -d)
cat > "${MOCK_BIN_DIR}/snapper" <<MOCK
#!/usr/bin/env bash
case "\${1:-}" in
    list)           cat "${REPO_ROOT}/tests/fixtures/snapper_list.txt" ;;
    list-configs)   printf 'Config | Subvolume\n------\n root  | /\n home  | /home\n' ;;
    create-config)  echo "Created config." ;;
    create)         echo "Created snapshot." ;;
    delete)         echo "Deleted snapshot \${2:-}." ;;
    modify)         echo "Modified snapshot." ;;
    status)         echo "M /etc/fstab"; echo "M /etc/hostname" ;;
    *)              echo "mock snapper: unknown command '\$1'" >&2; exit 1 ;;
esac
MOCK
chmod +x "${MOCK_BIN_DIR}/snapper"

export PATH="${MOCK_BIN_DIR}:${PATH}"
export SUDO_CMD=""

# ── Source modules ────────────────────────────────────────────────────────

LAZY_LIBDIR="${REPO_ROOT}/lib"
export LAZY_LIBDIR

# Pre-set LAZY_CONFIG_FILE to avoid loading real config
LAZY_CONFIG_FILE="/tmp/lazy-snapper-no-config-$$"

resolve_sudo() { export SUDO_CMD=""; }

# shellcheck source=../lib/utils.sh
source "${LAZY_LIBDIR}/utils.sh"
# shellcheck source=../lib/core.sh
source "${LAZY_LIBDIR}/core.sh"
# shellcheck source=../lib/snapper.sh
source "${LAZY_LIBDIR}/snapper.sh"

# ── Tests ─────────────────────────────────────────────────────────────────

echo "=== test_snapper.sh ==="

# 1. snapper_list_formatted excludes snapshot 0
list_output=$(snapper_list_formatted)
assert_not_contains "list excludes snapshot 0" "│ 0 │" "${list_output}"

# 2. snapper_list_formatted includes known snapshots
assert_contains "list includes snapshot 1" "1 " "${list_output}"
assert_contains "list includes snapshot 4" "4 " "${list_output}"

# 3. snapper_list_formatted includes descriptions
assert_contains "list includes description 'pre-update'" "pre-update" "${list_output}"
assert_contains "list includes description 'manual backup'" "manual backup" "${list_output}"

# 4. snapper_list_formatted output has 4 columns separated by │
col_count=$(echo "${list_output}" | head -1 | awk -F'│' '{print NF}')
assert_eq "list output has 4 │-separated columns" "4" "${col_count}"

# 5. snapper_get_row returns correct row
row=$(snapper_get_row "1")
assert_contains "get_row returns row for snapshot 1" "pre-update" "${row}"

# 6. snapper_get_row returns empty for missing snapshot
row=$(snapper_get_row "999")
assert_eq "get_row empty for missing snapshot" "" "${row}"

# 7. snapper_get_info output contains expected fields
info=$(snapper_get_info "1")
assert_contains "get_info shows Number"      "Number"     "${info}"
assert_contains "get_info shows Date/Time"   "Date/Time"  "${info}"
assert_contains "get_info shows description" "pre-update" "${info}"

# 8. snapper_get_info returns error for missing snapshot
info=$(snapper_get_info "999" 2>&1 || true)
assert_contains "get_info error for missing snapshot" "not found" "${info}"

# 9. snapper_current_desc returns description
desc=$(snapper_current_desc "4")
assert_eq "current_desc for snapshot 4" "manual backup" "${desc}"

# 10. snapper_delete calls snapper delete
output=$(snapper_delete "1" 2>&1)
assert_contains "snapper_delete calls delete" "Deleted" "${output}"

# 11. snapper_create calls snapper create
output=$(snapper_create "test snapshot" 2>&1)
assert_contains "snapper_create calls create" "Created" "${output}"

# ── Cleanup ───────────────────────────────────────────────────────────────

rm -rf "${MOCK_BIN_DIR}"

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
