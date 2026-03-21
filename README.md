# lazy-snapper

A fast, user-friendly terminal UI (TUI) for managing Btrfs snapshots via [snapper](http://snapper.io/), powered by [fzf](https://github.com/junegunn/fzf).

```
┌─────────────────────────────────────────────────────────────────┐
│  lazy-snapper v1.0.0                                            │
│                                                                 │
│    Browse & Manage  — Select and manage existing snapshots      │
│  ▶ Create           — Take a new snapshot now                   │
│    Quit             — Exit lazy-snapper                         │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- Browse snapshots with live preview (number, date, type, description, disk usage)
- Create, delete, and modify snapshots interactively
- **Revert changes** (not just "restore") with a clear warning before any destructive action
- Diff snapshot vs current state via `snapper status`
- Catppuccin-themed fzf UI with colored output
- Config file + environment variable overrides
- Graceful error messages when snapper is unavailable

## Dependencies

| Tool | Required |
|------|----------|
| `bash` ≥ 4.0 | ✅ |
| `fzf` | ✅ |
| `snapper` | ✅ |
| `btrfs-progs` | optional (disk usage display) |
| `sudo` | optional (if not running as root) |

## Installation

### One-liner

```bash
curl -sSL https://raw.githubusercontent.com/apapamarkou/lazy-snapper/main/install.sh | bash
```

### Manual

```bash
git clone https://github.com/apapamarkou/lazy-snapper.git
cd lazy-snapper
make install
```

Ensure `~/.local/bin` is in your `PATH`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

## Usage

```
lazy-snapper [OPTIONS]

Options:
  -c, --config <name>   Use a specific snapper config (default: system)
  -d, --debug           Enable debug output
  -v, --version         Print version and exit
  -h, --help            Show this help
```

## Keybindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate list |
| `Enter` | Select / confirm |
| `Ctrl+R` | Reload snapshot list |
| `Ctrl+C` / `Esc` | Cancel / go back |

## Configuration

A default config is written to `~/.config/lazy-snapper/config` on first install:

```bash
# Snapper config name
LAZY_SNAPPER_CONFIG=system

# Pager for diff output
LAZY_PAGER=less

# Enable debug logging
LAZY_DEBUG=0
```

All options can also be set as environment variables.

## Uninstall

```bash
make uninstall
# or
bash uninstall.sh
```

## License

GPL-3.0 — see [LICENSE](LICENSE).
