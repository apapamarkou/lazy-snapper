# Usage Guide

## Installation

The `install` script handles everything:

1. Checks for required dependencies (`fzf`, `snapper`).
2. If any are missing, prompts `[y/N]` to install them automatically.
3. Detects the system package manager (`pacman`, `dnf`, `apt`, `zypper`) and installs missing packages.
4. If no supported package manager is found, exits with an error asking for manual installation.
5. Copies files, symlinks the binary to `~/.local/bin/snapshots`, writes a `.desktop` entry to `~/.local/share/applications/`, and scaffolds `~/.config/lazy-snapper/config`.

```bash
bash install
# or via curl:
curl -sSL https://raw.githubusercontent.com/apapamarkou/lazy-snapper/main/install | bash
```

## Starting lazy-snapper

```bash
lazy-snapper              # show config picker, then Browse & Manage
lazy-snapper -c home      # skip picker, use the 'home' snapper config directly
lazy-snapper --debug      # enable verbose debug output
```

## Step 1 — Config Picker

On launch, lazy-snapper lists all available snapper configs and lets you pick one:

```
  system
  home
```

- If only one config exists it is selected automatically with no prompt.
- Pass `-c <name>` to skip the picker entirely.
- If **no configs exist**, lazy-snapper offers to create default `root` (`/`) and `home` (`/home`) configs automatically. If a subvolume doesn't exist the corresponding config is skipped with a warning.

## Step 2 — Browse & Manage

After selecting a config you enter the snapshot browser. Snapshots are shown **newest first**:

```
4     │ 2024-01-12 14:30:00 │ single │ manual backup
3     │ 2024-01-11 09:16:00 │ post   │ after pacman
2     │ 2024-01-11 09:15:00 │ pre    │ before pacman
1     │ 2024-01-10 08:00:00 │ single │ pre-update
```

A live preview panel on the right shows full details for the highlighted snapshot.

### Keybindings in Browse & Manage

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate list |
| `Enter` | Open action menu for selected snapshot |
| `Ctrl+N` | Create a new snapshot inline (list reloads automatically) |
| `Ctrl+R` | Reload snapshot list |
| `Ctrl+T` | Configure timeline snapshots for the current config |
| `Ctrl+C` / `Esc` | Exit back to config picker |

## Action Menu

After pressing `Enter` on a snapshot:

| Action | Description |
|--------|-------------|
| Info | Full snapshot details (number, date, type, user, disk usage, description) |
| Diff | Show files changed between this snapshot and the current state |
| Modify | Edit the snapshot description |
| Delete | Permanently delete the snapshot (requires confirmation) |
| Back | Return to the snapshot list |

## Timeline Configuration

Press `Ctrl+T` from the Browse & Manage list to configure automatic timeline snapshots for the current config. You will be prompted to edit:

| Setting | Description |
|---------|-------------|
| `TIMELINE_CREATE` | Enable (`yes`) or disable (`no`) automatic timeline snapshots |
| `TIMELINE_LIMIT_HOURLY` | Number of hourly snapshots to keep |
| `TIMELINE_LIMIT_DAILY` | Number of daily snapshots to keep |
| `TIMELINE_LIMIT_WEEKLY` | Number of weekly snapshots to keep |
| `TIMELINE_LIMIT_MONTHLY` | Number of monthly snapshots to keep |
| `TIMELINE_LIMIT_YEARLY` | Number of yearly snapshots to keep |

Current values are pre-filled. Press Enter to keep a value unchanged. Changes are applied with `snapper set-config`.

## Creating a Snapshot

Two ways:

- Press `Ctrl+N` from the Browse & Manage list — enter a description, confirm, list reloads.
- The snapshot is created with `snapper --config <name> create --description <text>`.

## Configuration

See `~/.config/lazy-snapper/config` for available options, or pass environment variables:

```bash
LAZY_SNAPPER_CONFIG=home LAZY_DEBUG=1 lazy-snapper
```
