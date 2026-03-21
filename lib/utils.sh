#!/usr/bin/env bash
# utils.sh — Logging, colors, and general-purpose helpers

# ── Colors ────────────────────────────────────────────────────────────────
readonly C_RESET='\033[0m'
readonly C_RED='\033[0;31m'
readonly C_GREEN='\033[0;32m'
readonly C_YELLOW='\033[0;33m'
readonly C_BLUE='\033[0;34m'
readonly C_MAGENTA='\033[0;35m'
readonly C_CYAN='\033[0;36m'
readonly C_WHITE='\033[1;37m'
readonly C_BOLD='\033[1m'
readonly C_DIM='\033[2m'

# ── Logging ───────────────────────────────────────────────────────────────
log_info()  { echo -e "${C_CYAN}[INFO]${C_RESET}  $*"; }
log_ok()    { echo -e "${C_GREEN}[OK]${C_RESET}    $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET}  $*" >&2; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }
log_debug() { [[ "${LAZY_DEBUG:-0}" == "1" ]] && echo -e "${C_DIM}[DEBUG] $*${C_RESET}" >&2; return 0; }

# ── Prompts ───────────────────────────────────────────────────────────────

# confirm_action <prompt> — returns 0 on Y, 1 on N
confirm_action() {
    local prompt="$1"
    local response

    echo -e "\n${C_YELLOW}${prompt}${C_RESET}"
    echo -e "${C_CYAN}Confirm? [y/N]:${C_RESET} \c"

    while true; do
        read -rsn1 response
        case "${response}" in
            [Yy]) echo -e "${C_GREEN}yes${C_RESET}"; return 0 ;;
            [Nn]|"") echo -e "${C_RED}no${C_RESET}"; return 1 ;;
            *) ;;
        esac
    done
}

show_error() {
    echo -e "\n${C_RED}✗ ${1}${C_RESET}"
    echo -e "${C_DIM}Press any key to continue...${C_RESET}"
    read -rsn1
}

show_success() {
    echo -e "\n${C_GREEN}✓ ${1}${C_RESET}"
    echo -e "${C_DIM}Press any key to continue...${C_RESET}"
    read -rsn1
}

# ── Dependency checks ─────────────────────────────────────────────────────

check_dependencies() {
    local missing=()

    command -v fzf     &>/dev/null || missing+=("fzf")
    command -v snapper &>/dev/null || missing+=("snapper")

    if [[ ${#missing[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing[*]}"
        log_error "Install them and try again."
        exit 1
    fi
}

# Resolve sudo prefix (empty when already root).
# Skips re-assignment if SUDO_CMD is already exported (e.g. in fzf subprocesses).
resolve_sudo() {
    if [[ -n "${SUDO_CMD+set}" ]]; then
        return 0
    fi
    if [[ "${EUID}" -eq 0 ]]; then
        SUDO_CMD=""
    else
        SUDO_CMD="sudo"
    fi
    export SUDO_CMD
}
