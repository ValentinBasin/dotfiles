# external-backup

Automatic [restic](https://restic.net/) backup of this machine's home
directory to an external USB drive ("mig"), triggered by plugging the drive
in. No cron, no manual commands — connect the drive, confirm in a dialog,
and a snapshot is taken.

(Previously named `backup-mig` after the laptop-migration task it was
originally built for. Renamed since it has nothing to do with that task
anymore. `install.sh` migrates a previous `backup-mig` install automatically.)

## How it works

1. A **udev rule** (`99-external-backup.rules`) matches the drive by
   filesystem UUID (stable across reboots and USB ports) and starts
   `external-backup.service` whenever a block device with that UUID appears.
2. The **systemd unit** (`external-backup.service`) is a `oneshot` service
   that runs as the desktop user (not root) with just enough environment
   (`XDG_RUNTIME_DIR`, `DBUS_SESSION_BUS_ADDRESS`) to reach that user's
   session bus for desktop notifications.
3. The **script** (`external-backup.sh`) does the actual work:
   - Detects `DISPLAY`/`WAYLAND_DISPLAY` at runtime by scanning
     `/proc/*/environ` of the user's own processes, since the service does
     not inherit them and they can differ between machines/reboots.
   - Shows a `zenity` confirmation dialog ("Start the backup?") with a
     60s timeout. No answer, or "No", and the run is skipped — nothing is
     backed up.
   - Waits for the drive to be mounted at `/run/media/<user>/mig`
     (auto-mounting it via `udisksctl` if the desktop hasn't already).
   - Runs `restic backup --json` over the **whole home directory**, minus
     `excludes.txt` patterns and `--exclude-caches` (standard CACHEDIR.TAG
     detection), streaming progress into a single desktop notification that
     is updated in place (percentage, files done) instead of separate
     start/end toasts.
   - Prunes old snapshots (`restic forget --keep-daily 7 --keep-weekly 4
     --keep-monthly 6 --prune`).
   - Unmounts and powers off (ejects) the drive via `udisksctl`, so it is
     physically safe to unplug as soon as the final notification appears.
   - Logs everything to the systemd journal under the `external-backup` tag.

### Why "whole home minus excludes" instead of an include list

An earlier version listed the specific folders to back up. The problem:
a new folder created later is silently *not* backed up until someone
remembers to add it to the list. Backing up all of `$HOME` by default fixes
that, at the cost of needing a deny-list for known junk so the repository
doesn't get bloated with reinstallable/redundant data (game libraries, tool
caches, cloud-synced folders that already have their own copy elsewhere).
`--exclude-caches` acts as a safety net for whatever isn't in that list
yet: it skips any directory containing a `CACHEDIR.TAG` file (a convention
many caches already follow). There is deliberately no size cap on
individual files (no `--exclude-larger-than`) — a large file can be
legitimate data worth keeping, so size alone isn't used as a signal to
drop something; keep `excludes.txt` up to date for anything that
shouldn't be backed up regardless of size.

restic's exit code 3 ("some source data could not be read") — e.g. from a
permission-denied file somewhere under `$HOME` — is treated as a warning,
not a failure: the run still prunes and ejects the drive normally.

## Dependencies

Linux with systemd and udisks2 (desktop session), plus:

- `restic` — the backup engine
- `zenity` — confirmation dialog
- `libnotify` (`notify-send`) — progress/result notifications
- `jq` — parsing restic's `--json` output
- `udisks2` (`udisksctl`) — mount/unmount/eject

On Arch/Omarchy: `pacman -S restic zenity jq libnotify udisks2`.
`install.sh` checks for these and warns if any are missing.

## Installing on a machine

```bash
./install.sh
```

This will (asking for `sudo` where needed):

- Remove a previous `backup-mig` install if one is found (legacy unit,
  script, udev rule; and migrate `~/.config/backup/restic-mig-pass` /
  `excludes-mig.txt` into their new names/location below)
- Install the script to `/usr/local/bin/external-backup.sh`
- Install the unit to `/etc/systemd/system/external-backup.service`,
  filling in the current user's name/UID in place of the
  `__USER__`/`__UID__` placeholders
- Install the udev rule to `/etc/udev/rules.d/99-external-backup.rules`
- Run `systemctl daemon-reload` and `udevadm control --reload-rules`
- Install a default `~/.config/external-backup/excludes.txt` if one
  doesn't already exist (never overwrites an existing one)

Re-run `install.sh` any time the files in this directory change.

### One manual step: the repository password

The restic repository password is **not** stored in this repo or on the
external drive — only on the machine's own (encrypted) disk, at:

```
~/.config/external-backup/restic-password
```

Create this file yourself with the repository password and:

```bash
chmod 600 ~/.config/external-backup/restic-password
```

`install.sh` reminds you if it's missing but never creates or touches its
contents (and migrates it automatically from a legacy `backup-mig` install).

## Configuration

Everything machine-specific lives in `external-backup.sh` itself:

- `DISK_UUID` — the external drive's filesystem UUID. The same physical
  drive is meant to be used across machines, so this normally doesn't need
  to change. Find a different drive's UUID with `lsblk -f`.
- `BACKUP_SOURCE` — what to back up (`$HOME` by default).
- `EXCLUDE_FILE` (`~/.config/external-backup/excludes.txt`) — glob patterns
  excluded from the backup (build artifacts, caches, game libraries,
  cloud-synced folders, etc.).
- `CONFIRM_TIMEOUT` — seconds to wait for the confirmation dialog before
  giving up on the run.

Edit the script and re-run `install.sh` to deploy the change, or edit
`~/.config/external-backup/excludes.txt` directly (not templated, edited in
place on each machine — `install.sh` never overwrites an existing one).

## Checking status / troubleshooting

```bash
systemctl status external-backup.service   # last run's outcome
journalctl -t external-backup -f           # live/full log for a run
```

If the drive doesn't trigger a run, confirm the udev rule matches its UUID:

```bash
udevadm info --query=property --name=/dev/sdX | grep ID_FS_UUID
```

If `zenity`'s dialog or notifications never appear, the session detection
in `detect_session_env` likely couldn't find `DISPLAY`/`WAYLAND_DISPLAY` —
check that the desktop session was fully started before the drive was
plugged in.

## Restoring from a snapshot

```bash
export RESTIC_PASSWORD_FILE=~/.config/external-backup/restic-password
restic -r /run/media/<user>/mig/restic snapshots
restic -r /run/media/<user>/mig/restic restore <snapshot-id> --target /path/to/restore
```
