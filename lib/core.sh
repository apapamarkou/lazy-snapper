#!/usr/bin/env bash
# core.sh — Bootstrap: config, environment, and version

LAZY_VERSION="1.0.0"
LAZY_CONFIG_DIR="${XDG_CONFIG_HOME:-${HOME}/.config}/lazy-snapper"
# Allow tests to pre-set LAZY_CONFIG_FILE before sourcing this file
LAZY_CONFIG_FILE="${LAZY_CONFIG_FILE:-${LAZY_CONFIG_DIR}/config}"

# ── Config defaults ───────────────────────────────────────────────────────

LAZY_SNAPPER_CONFIG="${LAZY_SNAPPER_CONFIG:-}"
LAZY_PAGER="${LAZY_PAGER:-${PAGER:-less}}"
LAZY_DEBUG="${LAZY_DEBUG:-0}"

# ── Config loader ─────────────────────────────────────────────────────────

load_config() {
    [[ -f "${LAZY_CONFIG_FILE}" ]] || return 0

    # Source only safe KEY=VALUE lines
    while IFS='=' read -r key value; do
        [[ "${key}" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${key}" ]] && continue
        key="${key// /}"
        value="${value%%#*}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value%"${value##*[![:space:]]}"}"
        case "${key}" in
            LAZY_SNAPPER_CONFIG|LAZY_PAGER|LAZY_DEBUG)
                printf -v "${key}" '%s' "${value}"
                ;;
            *)
                ;;
        esac
    done < "${LAZY_CONFIG_FILE}"
}

# ── Snapper config flag ───────────────────────────────────────────────────

snapper_config_flag() {
    if [[ -n "${LAZY_SNAPPER_CONFIG}" ]]; then
        echo "--config ${LAZY_SNAPPER_CONFIG}"
    fi
}

# ── Bootstrap ─────────────────────────────────────────────────────────────

bootstrap() {
    load_config
    resolve_sudo

    SNAPPER_BIN="${SNAPPER_BIN:-snapper}"
    readonly SNAPPER_BIN

    log_debug "lazy-snapper ${LAZY_VERSION} starting"
    log_debug "config: ${LAZY_CONFIG_FILE}"
    log_debug "sudo: '${SUDO_CMD}'"
}
