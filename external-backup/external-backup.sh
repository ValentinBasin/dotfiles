#!/bin/bash
# Backup script triggered when the external "mig" USB drive is plugged in.
# Runs as the desktop user (see external-backup.service, User=).
set -euo pipefail
shopt -s lastpipe

# --- Configuration --------------------------------------------------------

# Filesystem UUID of the external drive (stable across reboots/USB ports,
# and the same value on every machine since it identifies the physical drive).
DISK_UUID="b054959a-36da-46fc-b1f8-c3cb09d1cd1a"

# Where udisks2 / the desktop mounts the drive (based on its "mig" label).
MOUNT_POINT="/run/media/$(id -un)/mig"

# Existing restic repository already present on the drive; do not recreate it.
RESTIC_REPO="$MOUNT_POINT/restic"

# Repository password now lives only on the encrypted laptop disk,
# not on the external drive itself.
export RESTIC_PASSWORD_FILE="$HOME/.config/external-backup/restic-password"

EXCLUDE_FILE="$HOME/.config/external-backup/excludes.txt"
LOG_TAG="external-backup"

# How long to wait for the user to answer the confirmation dialog before
# giving up on this run (drive stays plugged in, nothing gets backed up).
CONFIRM_TIMEOUT=60

# What to back up: the whole home directory, minus EXCLUDE_FILE patterns
# and anything tagged as a cache directory (--exclude-caches, standard
# CACHEDIR.TAG detection). Backing up everything by default means a newly
# created folder is covered automatically instead of relying on remembering
# to add it to an include list; large legitimate files (VM images, etc.)
# are intentionally not size-capped, so keep EXCLUDE_FILE up to date for
# known junk/reproducible/redundant data instead.
BACKUP_SOURCE="$HOME"

# --- Helpers ---------------------------------------------------------------

notify() {
    # $1=title $2=body $3=urgency(optional: low|normal|critical)
    notify-send -u "${3:-normal}" -a "External Backup" "$1" "$2" 2>/dev/null || true
}

log() {
    logger -t "$LOG_TAG" -- "$1"
}

# The service only gets XDG_RUNTIME_DIR/DBUS_SESSION_BUS_ADDRESS from systemd
# (needed for the session bus itself). zenity/notify-send also need a display
# connection, so find the compositor/X11 socket instead of hardcoding
# DISPLAY/WAYLAND_DISPLAY, since they can change across reboots and differ
# between machines.
#
# An earlier version of this looked up the values by reading DISPLAY/
# WAYLAND_DISPLAY out of /proc/<pid>/environ for other processes in the
# session. That doesn't work reliably: file permission bits on
# /proc/<pid>/environ can say a same-user process is readable (`test -r`
# passes) while the kernel's Yama ptrace_scope (1 by default on most
# distros) still denies the actual read unless the reader is an ancestor
# of that process -- which a systemd-launched service never is. That
# turned an occasional missing dialog into the whole script crashing
# under `set -e` the instant it hit such a process. Locating the actual
# Wayland/X11 socket file avoids process introspection (and its
# permissions) entirely.
detect_session_env() {
    local runtime_dir="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
    local sock base

    if [ -z "${WAYLAND_DISPLAY:-}" ]; then
        for sock in "$runtime_dir"/wayland-*; do
            [ -S "$sock" ] || continue
            export WAYLAND_DISPLAY="$(basename "$sock")"
            break
        done
    fi

    if [ -z "${DISPLAY:-}" ]; then
        for sock in /tmp/.X11-unix/X*; do
            [ -S "$sock" ] || continue
            base="$(basename "$sock")"
            export DISPLAY=":${base#X}"
            break
        done
    fi
}

confirm_backup() {
    local rc=0
    zenity --question \
        --title="External Backup" \
        --text="The external backup drive (\"mig\") is connected.\nStart the backup?" \
        --timeout="$CONFIRM_TIMEOUT" \
        2>/dev/null || rc=$?

    if [ "$rc" -ne 0 ]; then
        log "Backup not confirmed (zenity exit $rc), skipping this run"
        notify "Backup skipped" "Backup was not started (no confirmation)."
        exit 0
    fi
}

wait_for_mount() {
    local tries=30
    while [ ! -d "$RESTIC_REPO" ] && [ "$tries" -gt 0 ]; do
        sleep 1
        tries=$((tries - 1))
    done

    if [ ! -d "$RESTIC_REPO" ]; then
        # Desktop auto-mount did not happen in time; mount it ourselves.
        # Safe to call even if it is already mounted.
        udisksctl mount -b "/dev/disk/by-uuid/$DISK_UUID" 2>&1 | logger -t "$LOG_TAG" || true
        sleep 2
    fi

    if [ ! -d "$RESTIC_REPO" ]; then
        notify "Backup failed" "Drive did not mount at $MOUNT_POINT" critical
        log "ERROR: mount point $MOUNT_POINT not ready, aborting"
        exit 1
    fi
}

# Unmounts and powers off (ejects) the drive so it is physically safe to
# unplug right away. Failures here are logged but never fail the run: the
# backup itself already succeeded by the time this is called.
eject_drive() {
    if ! udisksctl unmount -b "/dev/disk/by-uuid/$DISK_UUID" 2>&1 | logger -t "$LOG_TAG"; then
        log "WARNING: failed to unmount the drive, unmount it manually before unplugging"
        return 1
    fi

    if ! udisksctl power-off -b "/dev/disk/by-uuid/$DISK_UUID" 2>&1 | logger -t "$LOG_TAG"; then
        log "WARNING: drive was unmounted but power-off failed"
        return 1
    fi

    return 0
}

# --- Main --------------------------------------------------------------

run_backup() {
    log "Starting backup to $RESTIC_REPO"

    # Single notification, updated in place for the whole run instead of
    # separate "started"/"finished" toasts.
    local notif_id
    notif_id=$(notify-send --print-id -a "External Backup" -u low \
        "Backup running" "Preparing..." 2>/dev/null || true)

    # restic emits a "status" message several times per second on a large
    # backup. Calling notify-send on every single one sent thousands of
    # updates over a run, which piled up in the notification history
    # instead of cleanly replacing in place. Only send an update when the
    # displayed percentage actually changes (at most ~101 calls per run).
    local last_notified_percent=-1

    local restic_exit=1
    # Wrapped in "if ... ; then :; fi" purely to keep it out of `set -e`'s
    # way: the left side of a pipe runs in a subshell, and without this
    # guard, errexit kills that subshell the instant `restic` returns
    # non-zero (e.g. exit 3 for an unreadable file) -- *before* the trailing
    # `echo "__RESTIC_EXIT__:..."` line runs. That silently drops the exit
    # code and, because of pipefail, aborts the whole script right here,
    # skipping prune/eject entirely. The `if` guard suppresses errexit for
    # this one pipeline so the marker line always gets a chance to run.
    if {
        restic -r "$RESTIC_REPO" backup "$BACKUP_SOURCE" \
            --exclude-file="$EXCLUDE_FILE" \
            --exclude-caches \
            --host "$(hostname)" \
            --tag auto \
            --json 2>&1
        echo "__RESTIC_EXIT__:$?"
    } | while IFS= read -r line; do
        if [[ "$line" == __RESTIC_EXIT__:* ]]; then
            restic_exit="${line#__RESTIC_EXIT__:}"
            continue
        fi

        echo "$line" | logger -t "$LOG_TAG"

        local mtype
        mtype=$(jq -r '.message_type // empty' <<<"$line" 2>/dev/null) || continue

        case "$mtype" in
            status)
                local percent files_done total_files
                percent=$(jq -r '((.percent_done // 0) * 100) | floor' <<<"$line" 2>/dev/null || echo 0)
                if [ "$percent" != "$last_notified_percent" ]; then
                    last_notified_percent="$percent"
                    files_done=$(jq -r '.files_done // 0' <<<"$line" 2>/dev/null || echo 0)
                    total_files=$(jq -r '.total_files // 0' <<<"$line" 2>/dev/null || echo 0)
                    [ -n "$notif_id" ] && notify-send --replace-id="$notif_id" -a "External Backup" -u low \
                        -h "int:value:$percent" -h "boolean:transient:true" \
                        "Backup running ($percent%)" "$files_done / $total_files files" 2>/dev/null || true
                fi
                ;;
            error)
                local emsg
                emsg=$(jq -r '.error.message // .message // "unknown error"' <<<"$line" 2>/dev/null || echo "unknown error")
                log "ERROR: $emsg"
                ;;
        esac
    done; then
        :
    fi

    # restic exits 3 when at least one source path was unreadable (e.g. a
    # permission-denied file somewhere under $HOME), but still saves a valid
    # snapshot for everything else. Treat that as a warning, not a failure.
    if [ "$restic_exit" -eq 3 ]; then
        log "WARNING: some source paths were missing or unreadable (restic exit 3); snapshot was still saved"
    elif [ "$restic_exit" -ne 0 ]; then
        if [ -n "$notif_id" ]; then
            notify-send --replace-id="$notif_id" -a "External Backup" -u critical \
                "Backup failed" "restic exited with an error. Check: journalctl -t $LOG_TAG" 2>/dev/null || true
        else
            notify "Backup failed" "restic exited with an error. Check: journalctl -t $LOG_TAG" critical
        fi
        log "ERROR: restic backup failed (exit $restic_exit)"
        exit 1
    fi

    log "Pruning old snapshots"
    # Same `set -e`/pipefail hazard as above: don't let a prune failure
    # abort the script before the drive gets ejected below.
    if restic -r "$RESTIC_REPO" forget \
        --keep-daily 7 --keep-weekly 4 --keep-monthly 6 \
        --prune \
        2>&1 | logger -t "$LOG_TAG"; then
        :
    else
        log "WARNING: pruning old snapshots failed, continuing anyway"
    fi

    local finish_body="Snapshot saved successfully."
    if eject_drive; then
        finish_body="$finish_body Drive unmounted and ejected, you can unplug it now."
    else
        finish_body="$finish_body Unmount the drive manually before unplugging."
    fi

    if [ -n "$notif_id" ]; then
        notify-send --replace-id="$notif_id" -a "External Backup" -u normal \
            "Backup finished" "$finish_body" 2>/dev/null || true
    else
        notify "Backup finished" "$finish_body"
    fi
    log "Backup finished successfully"
}

main() {
    detect_session_env
    confirm_backup
    wait_for_mount
    run_backup
}

main
