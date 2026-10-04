# CLAUDE.md

Questo file fornisce indicazioni a Claude Code (claude.ai/code) per lavorare sul codice di questo repository.

## Cos'è questo repo

Strumenti per i miei backup personali (AGPL-3.0). Ogni directory di primo livello è un "obiettivo" di backup indipendente:

- `home/`: backup di `$HOME` su un disco USB con rsync e un timer systemd **utente**. Vedi `home/README.md`.
- `cloud/`: per ora è vuota, un segnaposto.

Non ci sono build, lint o test. README, messaggi degli script e messaggi di commit sono in **italiano**: continua a usare l'italiano.

## Architettura di home/

I file del repo sono dei modelli. Si installano copiandoli in percorsi fissi, e lo script dipende da quei percorsi:

| File nel repo | Installato in |
|---|---|
| `home/bin/backup-home.sh` | `~/.local/bin/backup-home.sh` (il servizio esegue `%h/.local/bin/backup-home.sh`) |
| `home/config/exclude.txt` | `~/.config/backup-home/exclude.txt` |
| `home/systemd/backup-home.{service,timer}` | `~/.config/systemd/user/` |

Modificare il repo non cambia la copia installata. Per provare una modifica, ricopia il file (vedi `home/README.md`) e poi esegui:

```
systemctl --user daemon-reload
systemctl --user start backup-home.service
journalctl --user -u backup-home -f
```

Come funziona:

- **Timer**: scatta ogni ora (`Persistent=true`). È lo script a garantire al massimo un backup ogni `MIN_AGE` (20h), usando il timestamp in `~/.local/state/backup-home/last`. Il timer si limita a controllare; è lo script a decidere se fare il backup. Se il disco non è montato o un backup è stato fatto da poco, lo script esce con 0, così l'unità non risulta fallita.
- **Snapshot**: incrementali, con `rsync --link-dest` rispetto a `$DEST/latest`, quindi i file non modificati sono hard link. Lo script scrive nella directory fissa `$DEST/.inprogress`, così un giro interrotto riprende da lì al giro successivo. Quando rsync finisce, lo script la rinomina in `YYYY-MM-DD_HHMM` e sposta il link simbolico `latest` su di essa.
- **Conservazione**: lo script tiene le `KEEP` (14) directory più recenti che corrispondono a `20??-*` e cancella le altre.
- **Codici di uscita di rsync**: 24 (file spariti durante la copia) vale come successo. 23 (trasferimento parziale, di solito file illeggibili) salva comunque lo snapshot, ma lo script esce con 23 per rendere visibile l'errore. Di solito la soluzione è aggiungere il percorso illeggibile a `exclude.txt`.
- **Percorso del disco**: scritto nella variabile `MNT`, come percorso con UUID sotto `/run/media/feroda/...`.

`exclude.txt` usa la sintassi dei filtri di rsync, relativa a `$HOME/`. Uno `/` iniziale ancora il pattern alla radice della home. Un pattern senza `/` iniziale (es. `node_modules/`) corrisponde a qualsiasi profondità.
