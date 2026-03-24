#!/usr/bin/env bash
# test_core.sh — Tests for lib/core.sh

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

assert_file_exists() {
    local desc="$1" path="$2"
    if [[ -f "${path}" ]]; then
        echo "  PASS: ${desc}"
        PASS=$((PASS+1))
    else
        echo "  FAIL: ${desc} — file not found: ${path}"
        FAIL=$((FAIL+1))
    fi
}

# ── Setup ─────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LAZY_LIBDIR="${REPO_ROOT}/lib"
export LAZY_LIBDIR

# Pre-set LAZY_CONFIG_FILE so core.sh doesn't load a real config
LAZY_CONFIG_FILE="/tmp/lazy-snapper-no-config-$$"

# shellcheck source=../lib/utils.sh
source "${LAZY_LIBDIR}/utils.sh"
# shellcheck source=../lib/core.sh
source "${LAZY_LIBDIR}/core.sh"

# Stub resolve_sudo AFTER sourcing so it overrides the real implementation
resolve_sudo() { export SUDO_CMD=""; }

# ── Tests ─────────────────────────────────────────────────────────────────

echo "=== test_core.sh ==="

# 1. Version is set
version_set=0
[[ -n "${LAZY_VERSION:-}" ]] && version_set=1
assert_eq "LAZY_VERSION is non-empty" "1" "${version_set}"

# 2. Config defaults
assert_eq "LAZY_DEBUG default is 0" "0" "${LAZY_DEBUG}"

pager_set=0
[[ -n "${LAZY_PAGER}" ]] && pager_set=1
assert_eq "LAZY_PAGER default is non-empty" "1" "${pager_set}"

# 3. load_config reads KEY=VALUE pairs
TMP_CFG=$(mktemp)
echo "LAZY_DEBUG=1"      > "${TMP_CFG}"
echo "# comment line"   >> "${TMP_CFG}"
echo "LAZY_PAGER=more"  >> "${TMP_CFG}"

LAZY_DEBUG=0
LAZY_PAGER=less
LAZY_CONFIG_FILE="${TMP_CFG}"
load_config
assert_eq "load_config sets LAZY_DEBUG" "1" "${LAZY_DEBUG}"
assert_eq "load_config sets LAZY_PAGER" "more" "${LAZY_PAGER}"
rm -f "${TMP_CFG}"

# 4. load_config is a no-op when file missing
LAZY_CONFIG_FILE="/tmp/lazy-snapper-nonexistent-$$"
LAZY_DEBUG=0
load_config
assert_eq "load_config no-op on missing file" "0" "${LAZY_DEBUG}"

# 5. snapper_config_flag returns empty when unset
LAZY_SNAPPER_CONFIG=""
result=$(snapper_config_flag)
assert_eq "snapper_config_flag empty when unset" "" "${result}"

# 6. snapper_config_flag returns flag when set
LAZY_SNAPPER_CONFIG="home"
result=$(snapper_config_flag)
assert_eq "snapper_config_flag with value" "--config home" "${result}"

# 7. resolve_sudo sets SUDO_CMD to empty when already root-stubbed
resolve_sudo
assert_eq "SUDO_CMD is set after resolve_sudo stub" "" "${SUDO_CMD}"

# 8. pkg symlink exists and points to bin/lazy-snapper
pkg_target=$(readlink "${REPO_ROOT}/pkg" 2>/dev/null || true)
assert_eq "pkg symlink points to bin/lazy-snapper" "bin/lazy-snapper" "${pkg_target}"

# ── Summary ───────────────────────────────────────────────────────────────

echo ""
echo "Results: ${PASS} passed, ${FAIL} failed"
[[ "${FAIL}" -eq 0 ]]
