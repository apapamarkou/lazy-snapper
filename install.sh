#!/usr/bin/env bash
# install.sh — Install lazy-snapper to ~/.local

set -euo pipefail

INSTALL_DIR="${HOME}/.local/share/lazy-snapper"
BIN_DIR="${HOME}/.local/bin"
REPO_URL="https://github.com/apapamarkou/lazy-snapper"

# Detect if running via pipe (no local repo)
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" ]]; then
    REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
    REPO_ROOT=""
fi

_green()  { echo -e "\033[0;32m$*\033[0m"; }
_yellow() { echo -e "\033[0;33m$*\033[0m"; }

echo ""
_green "Installing lazy-snapper..."
echo ""

# ── Copy files ────────────────────────────────────────────────────────────

mkdir -p "${INSTALL_DIR}" "${BIN_DIR}"

if [[ -n "${REPO_ROOT}" ]]; then
    cp -r "${REPO_ROOT}/bin" "${INSTALL_DIR}/"
    cp -r "${REPO_ROOT}/lib" "${INSTALL_DIR}/"
else
    _yellow "  Cloning repository..."
    git clone --depth=1 "${REPO_URL}" "${INSTALL_DIR}" 2>/dev/null || {
        rm -rf "${INSTALL_DIR}"
        git clone --depth=1 "${REPO_URL}" "${INSTALL_DIR}"
    }
fi

chmod +x "${INSTALL_DIR}/bin/lazy-snapper"

# ── Symlink binary ────────────────────────────────────────────────────────

ln -sf "${INSTALL_DIR}/bin/lazy-snapper" "${BIN_DIR}/snapshots"
_green "  ✓ Installed to ${INSTALL_DIR}"
_green "  ✓ Symlinked to ${BIN_DIR}/snapshots"

# ── PATH check ────────────────────────────────────────────────────────────

if ! echo "${PATH}" | grep -q "${BIN_DIR}"; then
    echo ""
    _yellow "  ⚠  ${BIN_DIR} is not in your PATH."
    _yellow "     Add the following to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo "       export PATH=\"\${HOME}/.local/bin:\${PATH}\""
    echo ""
fi

# ── Config scaffold ───────────────────────────────────────────────────────

CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/lazy-snapper"
CONFIG_FILE="${CONFIG_DIR}/config"

if [[ ! -f "${CONFIG_FILE}" ]]; then
    mkdir -p "${CONFIG_DIR}"
    cat > "${CONFIG_FILE}" <<'EOF'
# lazy-snapper configuration
# Uncomment and edit as needed.

# Snapper config name (default: system)
# LAZY_SNAPPER_CONFIG=system

# Pager for diff output
# LAZY_PAGER=less

# Enable debug logging (0 or 1)
# LAZY_DEBUG=0
EOF
    _green "  ✓ Default config written to ${CONFIG_FILE}"
fi

echo ""
_green "Done! Run: lazy-snapper"
echo ""
