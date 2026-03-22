# lazy-snapper

A fast, user-friendly terminal UI (TUI) for managing Btrfs snapshots via [snapper](http://snapper.io/), powered by [fzf](https://github.com/junegunn/fzf).

```
┌─────────────────────────────────────────────────────────────────┐
│  lazy-snapper v1.0.0                                            │
│                                                                 │
│  Step 1 — Pick a snapper config:                                │
│  ▶ system                                                       │
│    home                                                         │
│                                                                 │
│  Step 2 — Browse & Manage snapshots (newest first):            │
│    4     │ 2024-01-12 14:30:00 │ single │ manual backup        │
│  ▶ 3     │ 2024-01-11 09:16:00 │ post   │ after pacman         │
│    2     │ 2024-01-11 09:15:00 │ pre    │ before pacman        │
│    1     │ 2024-01-10 08:00:00 │ single │ pre-update           │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## Features

- Config picker on launch — choose which snapper config to manage
- Browse snapshots newest-first with live preview (number, date, type, description, disk usage)
- Create snapshots inline with `Ctrl+N` — list reloads automatically
- Create, delete, and modify snapshots interactively
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
curl -sSL https://raw.githubusercontent.com/apapamarkou/lazy-snapper/main/install | bash
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
  -c, --config <name>   Skip config picker, use this snapper config directly
  -d, --debug           Enable debug output
  -v, --version         Print version and exit
  -h, --help            Show this help
```

## Keybindings

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate list |
| `Enter` | Select / confirm |
| `Ctrl+N` | Create a new snapshot (in Browse & Manage) |
| `Ctrl+R` | Reload snapshot list |
| `Ctrl+C` / `Esc` | Cancel / go back |

## Configuration

A default config is written to `~/.config/lazy-snapper/config` on first install:

```bash
# Snapper config name (leave unset to show picker on launch)
# LAZY_SNAPPER_CONFIG=system

# Pager for diff output
# LAZY_PAGER=less

# Enable debug logging
# LAZY_DEBUG=0
```

All options can also be set as environment variables:

```bash
LAZY_SNAPPER_CONFIG=home LAZY_DEBUG=1 lazy-snapper
```

## Uninstall

```bash
make uninstall
# or
bash uninstall
```

## License

GPL-3.0 — see [LICENSE](LICENSE).
