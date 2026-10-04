#!/usr/bin/env bash
set -euo pipefail

MNT=/run/media/feroda/580f3ebf-ae57-4ad3-a66f-f6c6f7045270
DEST="$MNT/snapshots"
EXCL="$HOME/.config/backup-home/exclude.txt"
STAMP="$HOME/.local/state/backup-home/last"
KEEP=14
MIN_AGE=$((20*3600))
MIN_FREE_GB=20

mountpoint -q "$MNT" || { echo "Disco non collegato, salto."; exit 0; }
[ -d "$DEST" ]       || { echo "Manca $DEST"; exit 1; }

now=$(date +%s); last=$(cat "$STAMP" 2>/dev/null || echo 0)
(( now - last < MIN_AGE )) && { echo "Backup recente, salto."; exit 0; }

free=$(df --output=avail -BG "$MNT" | tail -1 | tr -dc 0-9)
(( free < MIN_FREE_GB )) && { echo "Spazio insufficiente: ${free}G"; exit 1; }

work="$DEST/.inprogress"          # nome fisso: un giro interrotto viene ripreso
new="$DEST/$(date +%F_%H%M)"
link=(); [ -e "$DEST/latest" ] && link=(--link-dest="$(readlink -f "$DEST/latest")")

rc=0
rsync -aHAX --delete "${link[@]}" --exclude-from="$EXCL" "$HOME/" "$work/" || rc=$?
if (( rc != 0 && rc != 23 && rc != 24 )); then echo "rsync fallito (codice $rc)"; exit "$rc"; fi

mv "$work" "$new"
ln -sfn "$(basename "$new")" "$DEST/latest"
mkdir -p "$(dirname "$STAMP")"; echo "$now" > "$STAMP"

ls -1d "$DEST"/20??-* 2>/dev/null | head -n -"$KEEP" | xargs -r rm -rf --

if (( rc == 23 )); then
  echo "ERRORE: snapshot $new salvato ma con file illeggibili. Vedi sopra e aggiorna exclude.txt"
  exit 23
fi
echo "Backup completato: $new"
