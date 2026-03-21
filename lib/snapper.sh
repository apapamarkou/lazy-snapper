#!/usr/bin/env bash
# snapper.sh — Thin wrappers around snapper commands

# Build the snapper command prefix: sudo [snapper --config <name>]
_snapper() {
    if [[ -n "${LAZY_SNAPPER_CONFIG:-}" ]]; then
        ${SUDO_CMD} snapper --config "${LAZY_SNAPPER_CONFIG}" "$@"
    else
        ${SUDO_CMD} snapper "$@"
    fi
}

# ── Listing ─────────────────────────────────────────────────────────────────────────

# Emit lines: "<num> | <datetime> | <type> | <description>"
# Skips snapshot 0 (current) and header/separator rows.
snapper_list_formatted() {
    local raw
    raw=$(_snapper list 2>/dev/null) || true
    echo "${raw}" \
        | tail -n +3 \
        | grep -v '^[[:space:]]*─' \
        | awk -F'│' '
            {
                num      = $1; type = $2; datetime = $4; desc = $7
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", num)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", type)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", datetime)
                gsub(/^[[:space:]]+|[[:space:]]+$/, "", desc)
                if (num ~ /^[0-9]+$/ && num != "0" && datetime != "")
                    printf "%-5s │ %-19s │ %-6s │ %s\n", num, datetime, type, desc
            }' || true
}

# Raw snapper list row for a single snapshot number (empty string if not found)
snapper_get_row() {
    local num="$1"
    local raw
    raw=$(_snapper list 2>/dev/null) || true
    echo "${raw}" | grep -E "^[[:space:]]*${num}[[:space:]]*│" || true
}

# Parse a field (1-based column index) from a snapper list row
_parse_field() {
    local row="$1" idx="$2"
    echo "${row}" | awk -F'│' -v i="${idx}" '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $i); print $i}'
}

snapper_get_info() {
    local num="$1"
    local row
    row=$(snapper_get_row "${num}")

    if [[ -z "${row}" ]]; then
        echo "Snapshot #${num} not found."
        return 1
    fi

    local type datetime user pre cleanup desc space="N/A"
    type=$(_parse_field "${row}" 2)
    pre=$(_parse_field "${row}" 3)
    datetime=$(_parse_field "${row}" 4)
    user=$(_parse_field "${row}" 5)
    cleanup=$(_parse_field "${row}" 6)
    desc=$(_parse_field "${row}" 7)

    if command -v btrfs &>/dev/null; then
        local snap_path="/.snapshots/${num}/snapshot"
        if [[ -d "${snap_path}" ]]; then
            local du_out
            du_out=$(du -sh "${snap_path}" 2>/dev/null) || true
            space=$(echo "${du_out}" | awk '{print $1}')
        fi
    fi

    echo -e "\033[1;36m╔══════════════════════════════════════╗\033[0m"
    echo -e "\033[1;36m║       SNAPSHOT INFORMATION           ║\033[0m"
    echo -e "\033[1;36m╚══════════════════════════════════════╝\033[0m"
    echo ""
    echo -e "\033[0;33mNumber    :\033[0m  \033[1;37m${num}\033[0m"
    echo -e "\033[0;33mDate/Time :\033[0m  \033[1;37m${datetime}\033[0m"
    echo -e "\033[0;33mType      :\033[0m  \033[1;37m${type}\033[0m"
    echo -e "\033[0;33mPre #     :\033[0m  \033[1;37m${pre}\033[0m"
    echo -e "\033[0;33mUser      :\033[0m  \033[1;37m${user}\033[0m"
    echo -e "\033[0;33mCleanup   :\033[0m  \033[1;37m${cleanup}\033[0m"
    echo -e "\033[0;33mSpace     :\033[0m  \033[1;37m${space}\033[0m"
    echo ""
    echo -e "\033[0;33mDescription:\033[0m"
    echo -e "\033[1;37m${desc:-<none>}\033[0m"
}

# ── Mutating operations ───────────────────────────────────────────────────

snapper_create() {
    local description="$1"
    _snapper create --description "${description}"
}

snapper_delete() {
    local num="$1"
    _snapper delete "${num}"
}

snapper_revert() {
    local num="$1"
    _snapper undochange "${num}..0"
}

snapper_modify_desc() {
    local num="$1" desc="$2"
    _snapper modify -d "${desc}" "${num}"
}

snapper_diff() {
    local num="$1"
    local status_out
    status_out=$(_snapper status "${num}..0") || true
    echo "${status_out}" | "${LAZY_PAGER:-less}"
}

# Return the current description for snapshot <num>
snapper_current_desc() {
    local num="$1"
    local row
    row=$(snapper_get_row "${num}")
    _parse_field "${row}" 7
}
