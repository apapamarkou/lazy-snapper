# Architecture

## Module Design

```
bin/lazy-snapper          Entry point — arg parsing, exports LAZY_BIN, sources all libs, calls main_menu()
lib/utils.sh              Colors, logging, confirm_action(), show_error/success(), check_dependencies()
lib/core.sh               Version, config loading, bootstrap(), resolve_sudo()
lib/snapper.sh            All snapper command wrappers (_snapper helper, list, create, delete, revert, …)
lib/ui.sh                 Config picker, Browse & Manage loop, action dispatchers
```

Each module has a single responsibility. `bin/lazy-snapper` is the only file that sources all modules and calls `main()`.

### Dependency graph

```
bin/lazy-snapper
  └── utils.sh      (no deps)
  └── core.sh       (uses utils.sh)
  └── snapper.sh    (uses utils.sh, core.sh)
  └── ui.sh         (uses all three)
```

## TUI Flow

```
launch
  └── pick_config()          — fzf list of snapper configs (skipped if -c passed or only one exists)
        └── browse_and_manage()  — persistent fzf snapshot browser (newest first via --tac)
              └── action_menu()  — per-snapshot actions (Info, Diff, Revert, Modify, Delete)
```

## snapper Integration

All snapper calls go through the `_snapper()` helper in `lib/snapper.sh`:

```bash
_snapper() {
    if [[ -n "${LAZY_SNAPPER_CONFIG:-}" ]]; then
        ${SUDO_CMD} snapper --config "${LAZY_SNAPPER_CONFIG}" "$@"
    else
        ${SUDO_CMD} snapper "$@"
    fi
}
```

This ensures `--config <name>` is injected consistently for every snapper invocation once a config is selected. `SUDO_CMD` is set by `resolve_sudo()` in `core.sh` and is empty when running as root.

## fzf Preview and Bindings

`bin/lazy-snapper` exports `LAZY_BIN` (its own absolute path) at startup. fzf `--preview` and `--bind` strings call `bash ${LAZY_BIN}` with internal subcommands:

| Subcommand | Called by | Does |
|------------|-----------|------|
| `__preview__ <num>` | `--preview` | Runs `snapper_get_info()` and exits |
| `__list__` | `ctrl-r:reload(…)` | Runs `snapper_list_formatted()` and exits |
| `__create__` | `ctrl-n:execute(…)` | Runs `ui_create()` and exits; fzf then reloads via `__list__` |

Using `bash ${LAZY_BIN}` (rather than calling `lib/snapper.sh` directly) means the subprocess sources all modules and inherits `LAZY_SNAPPER_CONFIG`, `SUDO_CMD`, and all functions correctly. This also avoids needing `lib/snapper.sh` to be executable.

## Config Loading

`load_config()` in `core.sh` reads `~/.config/lazy-snapper/config` (or `$XDG_CONFIG_HOME/lazy-snapper/config`). It parses only whitelisted `KEY=VALUE` lines, strips inline comments, and trims whitespace. Environment variables always take precedence because they are set before `load_config()` runs.

## Caching

There is intentionally no caching layer. Snapper list output is fast (milliseconds) and always reflects current state. The `Ctrl+R` binding and the post-create reload both call `__list__` to get a fresh list.

## Error Handling

- `set -euo pipefail` is active in all scripts.
- All snapper calls use `|| true` where a non-zero exit is expected (e.g. `grep` no-match).
- Mutating operations (`create`, `delete`, `revert`, `modify`) are wrapped in `if … then … else show_error …` blocks.
- Missing dependencies are caught at startup by `check_dependencies()`.

## Testing

Tests in `tests/` are plain Bash scripts (no external framework). A mock `snapper` binary is injected into `$PATH` via a temp directory at test time. The fixture `tests/fixtures/snapper_list.txt` provides deterministic `snapper list` output in the real table format (with `│` separators) that the parsers expect.
