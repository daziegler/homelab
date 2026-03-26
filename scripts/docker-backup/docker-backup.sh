#!/usr/bin/env bash
# docker-backup.sh — rsync /opt/docker_volumes/, keep last 7 snapshots

set -euo pipefail

CONFIG="${BASH_SOURCE[0]%.*}.env"
[[ -f "$CONFIG" ]] || die "Config file not found: '${CONFIG}'"
source "$CONFIG"

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"; }
die() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $*" >&2; exit 1; }

[[ -d "$SOURCE"    ]] || die "SOURCE is not a valid directory: '${SOURCE}'"
[[ -d "$DEST_BASE" ]] || die "DEST_BASE is not a valid directory: '${DEST_BASE}'"

# Lock file released implicitly when the script exits (fd close)
exec 9>/tmp/docker-backup.lock
flock -n 9 || die "Another backup is already running."

TODAY=$(date +%Y-%m-%d)
DEST="${DEST_BASE}/${TODAY}"

[[ -d "$DEST" ]] && log "Destination exists, re-syncing."
log "Starting backup: ${SOURCE} → ${DEST}"

# --delete-after: deletions happen only after all new files are written
rsync -a --no-owner --no-group --delete-after "${SOURCE}" "${DEST}/" || die "rsync failed. No deletions performed."
log "Backup complete."

# Delete all but the most recent $KEEP snapshots
mapfile -t OLD < <(find "$DEST_BASE" -mindepth 1 -maxdepth 1 -type d -name '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' | sort -r | tail -n +$(( KEEP + 1 )))

if (( ${#OLD[@]} == 0 )); then
    log "Nothing to delete."
else
    for dir in "${OLD[@]}"; do
        [[ "$dir" == "${DEST_BASE}/"* ]] || { log "Skipping unexpected path: ${dir}"; continue; }
        log "Deleting: $(basename "$dir")"
        rm -rf "$dir"
    done
fi

log "Done. Kept last ${KEEP} snapshots."
