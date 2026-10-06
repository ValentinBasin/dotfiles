#!/bin/bash
# Installs the external-drive restic backup mechanism (systemd unit + udev
# rule + script) on the current machine. Re-run any time these source files
# change. Also migrates a previous "backup-mig" install (legacy name) if one
# is found: same mechanism, renamed.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_USER="${SUDO_USER:-$USER}"
TARGET_UID="$(id -u "$TARGET_USER")"

echo "Installing external-backup for user '$TARGET_USER' (uid $TARGET_UID)"

missing=()
for dep in restic zenity jq notify-send udisksctl systemctl udevadm; do
    command -v "$dep" >/dev/null 2>&1 || missing+=("$dep")
done
if [ "${#missing[@]}" -gt 0 ]; then
    echo "WARNING: missing dependencies: ${missing[*]}"
    echo "This mechanism needs systemd + udisks2 on a Linux desktop (Arch: pacman -S restic zenity jq libnotify udisks2)."
fi

# --- Legacy "backup-mig" cleanup -------------------------------------------

if [ -f /etc/systemd/system/backup-mig.service ]; then
    echo "Removing legacy backup-mig.service"
    sudo systemctl disable --now backup-mig.service 2>/dev/null || true
    sudo rm -f /etc/systemd/system/backup-mig.service
fi
[ -f /usr/local/bin/backup-mig.sh ] && sudo rm -f /usr/local/bin/backup-mig.sh
[ -f /etc/udev/rules.d/99-backup-mig.rules ] && sudo rm -f /etc/udev/rules.d/99-backup-mig.rules

OLD_CONFIG_DIR="$HOME/.config/backup"
NEW_CONFIG_DIR="$HOME/.config/external-backup"
mkdir -p "$NEW_CONFIG_DIR"

if [ -f "$OLD_CONFIG_DIR/restic-mig-pass" ] && [ ! -f "$NEW_CONFIG_DIR/restic-password" ]; then
    mv "$OLD_CONFIG_DIR/restic-mig-pass" "$NEW_CONFIG_DIR/restic-password"
    chmod 600 "$NEW_CONFIG_DIR/restic-password"
    echo "Migrated $OLD_CONFIG_DIR/restic-mig-pass -> $NEW_CONFIG_DIR/restic-password"
fi
if [ -f "$OLD_CONFIG_DIR/excludes-mig.txt" ] && [ ! -f "$NEW_CONFIG_DIR/excludes.txt" ]; then
    mv "$OLD_CONFIG_DIR/excludes-mig.txt" "$NEW_CONFIG_DIR/excludes.txt"
    echo "Migrated $OLD_CONFIG_DIR/excludes-mig.txt -> $NEW_CONFIG_DIR/excludes.txt (superseded by this package's excludes.txt below)"
fi
rmdir "$OLD_CONFIG_DIR" 2>/dev/null || true

# --- Install ----------------------------------------------------------------

sudo install -o root -g root -m 755 "$SCRIPT_DIR/external-backup.sh" /usr/local/bin/external-backup.sh

sed -e "s/__USER__/$TARGET_USER/g" -e "s/__UID__/$TARGET_UID/g" \
    "$SCRIPT_DIR/external-backup.service" | sudo tee /etc/systemd/system/external-backup.service > /dev/null
sudo chmod 644 /etc/systemd/system/external-backup.service

sudo install -o root -g root -m 644 "$SCRIPT_DIR/99-external-backup.rules" /etc/udev/rules.d/99-external-backup.rules

sudo systemctl daemon-reload
sudo udevadm control --reload-rules

if [ ! -f "$NEW_CONFIG_DIR/excludes.txt" ]; then
    install -m 644 "$SCRIPT_DIR/excludes.txt" "$NEW_CONFIG_DIR/excludes.txt"
    echo "Installed default $NEW_CONFIG_DIR/excludes.txt"
else
    echo "Kept existing $NEW_CONFIG_DIR/excludes.txt (not overwritten; diff it against $SCRIPT_DIR/excludes.txt for updates)"
fi

echo
if [ -f "$NEW_CONFIG_DIR/restic-password" ]; then
    echo "Found existing $NEW_CONFIG_DIR/restic-password"
else
    echo "ACTION NEEDED: create $NEW_CONFIG_DIR/restic-password with the restic"
    echo "repository password, then: chmod 600 $NEW_CONFIG_DIR/restic-password"
    echo "(the password is never stored in this repo, only on the machine's disk)"
fi

echo
echo "Done. Plug in the drive labeled \"mig\" to trigger a backup."
echo "If this is a different physical drive, edit DISK_UUID in external-backup.sh"
echo "(get the UUID with: lsblk -f) and re-run this script."
