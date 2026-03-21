#!/usr/bin/env bash
# install.sh — Install lazy-snapper to ~/.local

set -euo pipefail

INSTALL_DIR="${HOME}/.local/share/lazy-snapper"
BIN_DIR="${HOME}/.local/bin"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

_green()  { echo -e "\033[0;32m$*\033[0m"; }
_yellow() { echo -e "\033[0;33m$*\033[0m"; }

echo ""
_green "Installing lazy-snapper..."
echo ""

# ── Copy files ────────────────────────────────────────────────────────────

mkdir -p "${INSTALL_DIR}" "${BIN_DIR}"

cp -r "${REPO_ROOT}/bin" "${INSTALL_DIR}/"
cp -r "${REPO_ROOT}/lib" "${INSTALL_DIR}/"

chmod +x "${INSTALL_DIR}/bin/lazy-snapper"

# ── Symlink binary ────────────────────────────────────────────────────────

ln -sf "${INSTALL_DIR}/bin/lazy-snapper" "${BIN_DIR}/lazy-snapper"
_green "  ✓ Installed to ${INSTALL_DIR}"
_green "  ✓ Symlinked to ${BIN_DIR}/lazy-snapper"

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
