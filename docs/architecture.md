# Architecture

## Module Design

```
bin/lazy-snapper          Entry point — arg parsing, sources all libs, calls main_menu()
lib/utils.sh              Colors, logging, confirm_action(), show_error/success()
lib/core.sh               Version, config loading, bootstrap(), resolve_sudo()
lib/snapper.sh            All snapper command wrappers (list, create, delete, revert, …)
lib/ui.sh                 fzf menus, action dispatchers, TUI loop
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

## snapper Integration

All snapper calls are isolated in `lib/snapper.sh`. The `$SUDO_CMD` variable (set by `resolve_sudo()` in `core.sh`) is prepended to every snapper invocation, so the tool works both as root and as a regular user with sudo.

The `SNAPPER_BIN` environment variable can override the snapper binary path — used by the test suite to inject a mock.

### fzf Preview

The `--preview` flag in fzf calls the binary itself with the internal `__preview__ <num>` subcommand, which calls `snapper_get_info()` and exits. This avoids a separate preview script file.

## Config Loading

`load_config()` in `core.sh` reads `~/.config/lazy-snapper/config` (or `$XDG_CONFIG_HOME/lazy-snapper/config`). It parses only whitelisted `KEY=VALUE` lines, strips comments, and trims whitespace. Environment variables always take precedence over the config file because they are set before `load_config()` is called.

## Caching

There is intentionally no caching layer. Snapper list output is fast (milliseconds) and always reflects the current state. The fzf `Ctrl+R` binding reloads the list on demand via the `__list__` subcommand.

## Error Handling

- `set -euo pipefail` is active in all scripts.
- Snapper calls are wrapped in `if command; then … else show_error …; fi` blocks so a failed snapper invocation shows a user-friendly message rather than crashing.
- Missing dependencies are caught at startup by `check_dependencies()`.

## Testing

Tests in `tests/` are plain Bash scripts (no external test framework required). A mock `snapper` binary is injected into `$PATH` at test time via a temp directory. The fixture file `tests/fixtures/snapper_list.txt` provides deterministic snapper list output.
