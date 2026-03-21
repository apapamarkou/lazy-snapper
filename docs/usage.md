# Usage Guide

## Starting lazy-snapper

```bash
lazy-snapper              # use default snapper config (system)
lazy-snapper -c home      # use the 'home' snapper config
lazy-snapper --debug      # enable verbose debug output
```

## Main Menu

On launch you are presented with three choices:

| Option | Description |
|--------|-------------|
| Browse & Manage | Open the snapshot list |
| Create | Take a new snapshot immediately |
| Quit | Exit |

## Snapshot List

The list shows all snapshots (excluding snapshot 0 / current):

```
1     │ 2024-01-10 08:00:00 │ single │ pre-update
2     │ 2024-01-11 09:15:00 │ pre    │ before pacman
3     │ 2024-01-11 09:16:00 │ post   │ after pacman
4     │ 2024-01-12 14:30:00 │ single │ manual backup
```

A live preview panel on the right shows full details for the highlighted snapshot.

Press `Ctrl+R` to reload the list after external changes.

## Action Menu

After selecting a snapshot, choose an action:

| Action | Description |
|--------|-------------|
| Info | Full snapshot details (number, date, type, user, disk usage, description) |
| Diff | Show files changed between this snapshot and the current state |
| ⚠ Revert | Revert all changes made after this snapshot (destructive — requires confirmation) |
| Modify | Edit the snapshot description |
| Delete | Permanently delete the snapshot (requires confirmation) |
| Back | Return to the snapshot list |

## Revert Changes

The **Revert** action calls `snapper undochange <num>..0`, which reverts the working filesystem to the state captured in the snapshot.

You will see:

```
⚠  WARNING: This will revert your system to the state of snapshot #N.
   Files created or modified after this snapshot may be lost.

Confirm? [y/N]:
```

Type `y` to proceed or `n` / `Enter` to cancel.

> A reboot may be required for some changes (e.g. kernel, bootloader) to take effect.

## Creating a Snapshot

Enter a short description when prompted. The snapshot is created with `snapper create --description`.

## Configuration

See `~/.config/lazy-snapper/config` for available options, or pass environment variables:

```bash
LAZY_SNAPPER_CONFIG=home LAZY_DEBUG=1 lazy-snapper
```
