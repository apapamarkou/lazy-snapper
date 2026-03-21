#!/usr/bin/env bash
# uninstall.sh — Remove lazy-snapper from ~/.local

set -euo pipefail

INSTALL_DIR="${HOME}/.local/share/lazy-snapper"
BIN_LINK="${HOME}/.local/bin/lazy-snapper"

_green()  { echo -e "\033[0;32m$*\033[0m"; }
_yellow() { echo -e "\033[0;33m$*\033[0m"; }

echo ""
_yellow "Uninstalling lazy-snapper..."
echo ""

if [[ -L "${BIN_LINK}" ]]; then
    rm -f "${BIN_LINK}"
    _green "  ✓ Removed symlink: ${BIN_LINK}"
else
    _yellow "  – Symlink not found: ${BIN_LINK}"
fi

if [[ -d "${INSTALL_DIR}" ]]; then
    rm -rf "${INSTALL_DIR}"
    _green "  ✓ Removed install dir: ${INSTALL_DIR}"
else
    _yellow "  – Install dir not found: ${INSTALL_DIR}"
fi

echo ""
_green "lazy-snapper has been removed."
_yellow "Config at ~/.config/lazy-snapper/ was NOT removed. Delete it manually if desired."
echo ""
