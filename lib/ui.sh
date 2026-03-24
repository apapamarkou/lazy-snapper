#!/usr/bin/env bash
# ui.sh — fzf-based TUI menus and action dispatchers
# shellcheck source=utils.sh
# shellcheck source=core.sh
# shellcheck source=snapper.sh

# ── fzf base options ──────────────────────────────────────────────────────

_FZF_COMMON=(
    --ansi
    --reverse
    --border=rounded
    --color="bg+:#1e1e2e,bg:#181825,spinner:#f5c2e7,hl:#cba6f7"
    --color="fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5c2e7"
    --color="marker:#f5c2e7,fg+:#cdd6f4,prompt:#cba6f7,hl+:#cba6f7"
    --pointer="▶"
    --marker="✓"
)

# ── Header helpers ────────────────────────────────────────────────────────

_header() {
    echo -e "${C_BOLD}${C_CYAN}lazy-snapper${C_RESET} ${C_DIM}v${LAZY_VERSION}${C_RESET}"
}

# ── Config picker ────────────────────────────────────────────────────────

# List available snapper configs and let the user pick one.
# Sets LAZY_SNAPPER_CONFIG and returns 1 if user cancels.
pick_config() {
    local configs
    configs=$(${SUDO_CMD} snapper list-configs 2>/dev/null \
        | tail -n +3 \
        | grep -v '^[[:space:]]*─' \
        | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); if ($1 != "") print $1}' \
        || true)

    if [[ -z "${configs}" ]]; then
        clear
        echo -e "${C_BOLD}${C_YELLOW}No snapper configs found.${C_RESET}\n"
        echo -e "Create default configs for ${C_BOLD}root (/)${C_RESET} and ${C_BOLD}home (/home)${C_RESET}?"
        echo -e "${C_DIM}This runs: snapper create-config / and snapper create-config /home${C_RESET}\n"
        printf "  Proceed? [y/N]: "
        local ans
        read -r ans < /dev/tty
        if [[ ! "${ans}" =~ ^[Yy]$ ]]; then
            show_error "No snapper configs available. Configure snapper manually and restart."
            return 1
        fi
        local failed=()
        ${SUDO_CMD} snapper --config root create-config / 2>/dev/null || failed+=("root")
        ${SUDO_CMD} snapper --config home create-config /home 2>/dev/null || failed+=("home")
        if [[ ${#failed[@]} -gt 0 ]]; then
            show_error "Failed to create config(s): ${failed[*]}. Check that the subvolumes exist."
            [[ ${#failed[@]} -eq 2 ]] && return 1
        fi
        configs=$(${SUDO_CMD} snapper list-configs 2>/dev/null \
            | tail -n +3 \
            | grep -v '^[[:space:]]*─' \
            | awk '{gsub(/^[[:space:]]+|[[:space:]]+$/, "", $1); if ($1 != "") print $1}' \
            || true)
        [[ -z "${configs}" ]] && { show_error "Still no configs found after creation attempt."; return 1; }
    fi

    # If only one config exists, select it automatically
    local count
    count=$(echo "${configs}" | wc -l)
    if [[ "${count}" -eq 1 ]]; then
        LAZY_SNAPPER_CONFIG=$(echo "${configs}" | tr -d '[:space:]')
        export LAZY_SNAPPER_CONFIG
        return 0
    fi

    local header_text
    header_text=$(printf '%s\n%s' "$(_header)" "  Select a snapper config")

    local chosen
    chosen=$(
        echo "${configs}" | fzf \
            "${_FZF_COMMON[@]}" \
            --header="${header_text}" \
            --prompt="  Config > " \
            --no-multi \
            --no-preview
    ) || return 1

    LAZY_SNAPPER_CONFIG=$(echo "${chosen}" | tr -d '[:space:]')
    export LAZY_SNAPPER_CONFIG
}

# ── Snapshot browser ──────────────────────────────────────────────────────

# Full Browse & Manage loop for the current LAZY_SNAPPER_CONFIG.
# Ctrl-N creates a new snapshot and reloads. Enter opens action menu.
browse_and_manage() {
    local header_text
    header_text=$(printf '%s\n%s\n%s\n%s' \
        "$(_header)" \
        "  Config: ${LAZY_SNAPPER_CONFIG} - [Ctrl-N] new  [Ctrl-R] reload  [Ctrl-T] timeline" \
        "" \
        "#     │ Date/Time                       │ Type   │ Description    ")

    while true; do
        local output key selected
        output=$(
            snapper_list_formatted | fzf \
                "${_FZF_COMMON[@]}" \
                --tac \
                --header="${header_text}" \
                --header-lines=0 \
                --prompt="  Snapshot > " \
                --preview="bash ${LAZY_BIN} __preview__ {1}" \
                --preview-window="right:45%:wrap" \
                --bind="ctrl-r:reload(bash ${LAZY_BIN} __list__)" \
                --bind="ctrl-n:execute(bash ${LAZY_BIN} __create__)+reload(bash ${LAZY_BIN} __list__)" \
                --expect=ctrl-t \
                --no-multi
        ) || return 0

        key=$(echo "${output}"    | head -1)
        selected=$(echo "${output}" | tail -n +2)

        if [[ "${key}" == "ctrl-t" ]]; then
            ui_timeline || true
            continue
        fi

        local snap_num
        snap_num=$(echo "${selected}" | awk '{print $1}')
        [[ -n "${snap_num}" ]] && action_menu "${snap_num}"
    done
}

# ── Action menu ───────────────────────────────────────────────────────────

action_menu() {
    local snap_num="$1"

    local actions=(
        "  Info          — View full snapshot details"
        "  Diff          — Show changed files vs current"
        "  Modify        — Edit snapshot description"
        "  Delete        — Delete this snapshot"
        "  Back          — Return to snapshot list"
    )

    local header_text
    header_text=$(printf '%s\n%s' "$(_header)" "  Snapshot #${snap_num} — choose action")

    local choice
    choice=$(
        printf '%s\n' "${actions[@]}" | fzf \
            "${_FZF_COMMON[@]}" \
            --header="${header_text}" \
            --prompt="  Action > " \
            --no-multi \
            --preview="bash ${LAZY_BIN} __preview__ ${snap_num}" \
            --preview-window="right:45%:wrap"
    ) || return 0

    case "${choice}" in
        *Info*)   ui_show_info "${snap_num}" ;;
        *Diff*)   ui_diff      "${snap_num}" ;;
        *Modify*) ui_modify    "${snap_num}" ;;
        *Delete*) ui_delete    "${snap_num}" ;;
        *Back*|*) return 0 ;;
    esac
}

# ── Individual action UIs ─────────────────────────────────────────────────

ui_show_info() {
    local snap_num="$1"
    clear
    echo -e "${C_BOLD}${C_CYAN}═══ SNAPSHOT DETAILS ═══${C_RESET}\n"
    snapper_get_info "${snap_num}"
    echo -e "\n${C_DIM}Press any key to continue...${C_RESET}"
    read -rsn1
}

ui_diff() {
    local snap_num="$1"
    snapper_diff "${snap_num}"
}

ui_delete() {
    local snap_num="$1"
    clear
    echo -e "${C_BOLD}${C_RED}═══ DELETE SNAPSHOT ═══${C_RESET}\n"
    snapper_get_info "${snap_num}"

    if confirm_action "Permanently delete snapshot #${snap_num}? This cannot be undone."; then
        if snapper_delete "${snap_num}"; then
            show_success "Snapshot #${snap_num} deleted."
        else
            show_error "Failed to delete snapshot #${snap_num}."
        fi
    fi
}

ui_create() {
    clear
    echo -e "${C_BOLD}${C_CYAN}═══ CREATE SNAPSHOT ═══${C_RESET}\n"
    echo -e "${C_YELLOW}Enter a description for the new snapshot:${C_RESET}"
    local description
    read -re description

    if [[ -z "${description}" ]]; then
        show_error "Description cannot be empty."
        return 1
    fi

    if confirm_action "Create snapshot: '${description}'?"; then
        if snapper_create "${description}"; then
            show_success "Snapshot created: '${description}'"
        else
            show_error "Failed to create snapshot."
        fi
    fi
}

ui_modify() {
    local snap_num="$1"
    clear
    echo -e "${C_BOLD}${C_CYAN}═══ MODIFY SNAPSHOT ═══${C_RESET}\n"
    snapper_get_info "${snap_num}"

    local current_desc
    current_desc=$(snapper_current_desc "${snap_num}")

    echo -e "\n${C_YELLOW}Edit description (Ctrl+A/E for start/end):${C_RESET}"
    local new_desc
    read -re -i "${current_desc}" new_desc

    if [[ -z "${new_desc}" ]]; then
        show_error "Description cannot be empty."
        return 1
    fi

    if confirm_action "Update description for snapshot #${snap_num}?"; then
        if snapper_modify_desc "${snap_num}" "${new_desc}"; then
            show_success "Description updated for snapshot #${snap_num}."
        else
            show_error "Failed to update description."
        fi
    fi
}

ui_timeline() {
    local raw enabled hourly daily weekly monthly yearly

    _tl_load() {
        raw=$(snapper_get_timeline)
        _get_val() { echo "${raw}" | grep "^${1}=" | cut -d= -f2- | tr -d '[:space:]' | grep -oE '[0-9]+|yes|no' | head -1; }
        enabled=$(  _get_val TIMELINE_CREATE);        [[ -z "${enabled}"  ]] && enabled=yes
        hourly=$(   _get_val TIMELINE_LIMIT_HOURLY);  [[ -z "${hourly}"   ]] && hourly=8
        daily=$(    _get_val TIMELINE_LIMIT_DAILY);   [[ -z "${daily}"    ]] && daily=6
        weekly=$(   _get_val TIMELINE_LIMIT_WEEKLY);  [[ -z "${weekly}"   ]] && weekly=0
        monthly=$(  _get_val TIMELINE_LIMIT_MONTHLY); [[ -z "${monthly}"  ]] && monthly=11
        yearly=$(   _get_val TIMELINE_LIMIT_YEARLY);  [[ -z "${yearly}"   ]] && yearly=1
    }

    _tl_items() {
        if [[ "${enabled}" == "yes" ]]; then
            echo "  ●  Disable timeline snapshots"
            echo "  Hourly   │ ${hourly}"
            echo "  Daily    │ ${daily}"
            echo "  Weekly   │ ${weekly}"
            echo "  Monthly  │ ${monthly}"
            echo "  Yearly   │ ${yearly}"
        else
            echo "  ○  Enable timeline snapshots"
        fi
    }

    _tl_load

    while true; do
        local header_text
        header_text=$(printf '%s\n%s' "$(_header)" "  Timeline — Config: ${LAZY_SNAPPER_CONFIG}")

        local choice
        choice=$(
            _tl_items | fzf \
                "${_FZF_COMMON[@]}" \
                --header="${header_text}" \
                --prompt="  Timeline > " \
                --no-multi \
                --no-preview
        ) || return 0

        case "${choice}" in
            *Enable*)
                if snapper_set_timeline "TIMELINE_CREATE=yes"; then
                    enabled=yes
                else
                    show_error "Failed to enable timeline."
                fi
                ;;
            *Disable*)
                if snapper_set_timeline "TIMELINE_CREATE=no"; then
                    enabled=no
                else
                    show_error "Failed to disable timeline."
                fi
                ;;
            *Hourly*|*Daily*|*Weekly*|*Monthly*|*Yearly*)
                local key label current new_val
                case "${choice}" in
                    *Hourly*)  key=TIMELINE_LIMIT_HOURLY;  label=Hourly;  current=${hourly} ;;
                    *Daily*)   key=TIMELINE_LIMIT_DAILY;   label=Daily;   current=${daily} ;;
                    *Weekly*)  key=TIMELINE_LIMIT_WEEKLY;  label=Weekly;  current=${weekly} ;;
                    *Monthly*) key=TIMELINE_LIMIT_MONTHLY; label=Monthly; current=${monthly} ;;
                    *Yearly*)  key=TIMELINE_LIMIT_YEARLY;  label=Yearly;  current=${yearly} ;;
                    *)         continue ;;
                esac
                clear
                printf "\n\n  %s snapshots to keep (current: %s): " "${label}" "${current}"
                read -r new_val < /dev/tty
                [[ -z "${new_val}" ]] && new_val=${current}
                if snapper_set_timeline "${key}=${new_val}"; then
                    case "${key}" in
                        *HOURLY*)  hourly=${new_val} ;;
                        *DAILY*)   daily=${new_val} ;;
                        *WEEKLY*)  weekly=${new_val} ;;
                        *MONTHLY*) monthly=${new_val} ;;
                        *YEARLY*)  yearly=${new_val} ;;
                        *)         ;;
                    esac
                else
                    show_error "Failed to update ${key}."
                fi
                ;;
            *) ;;
        esac
    done
}

# ── Main TUI loop ─────────────────────────────────────────────────────────

main_menu() {
    # Step 1: pick a snapper config (skipped if -c was passed or only one exists)
    if [[ -z "${LAZY_SNAPPER_CONFIG}" ]]; then
        pick_config || return 0
    fi

    # Step 2: Browse & Manage loop for the chosen config
    browse_and_manage
}
