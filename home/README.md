# Backup della mia home in locale

In questa directory ci sono i files necessari per effettuare il backup della mia home su un disco USB.

Il mio punto di mount del disco USB è `/run/media/feroda/580f3ebf-ae57-4ad3-a66f-f6c6f7045270/`, cambiare il proprio mount del disco USB nella variabile `MNT` di `~/bin/backup-home.sh`

Verificare e cambiare i path da escludere in `config/exclude.txt`

Poi copiare i files in questo modo:

```
mkdir -p ~/.config/backup-home/
mkdir -p ~/.local/bin
mkdir -p ~/.config/systemd/user/

cp config/exclude.txt ~/.config/backup-home/
cp bin/backup-home.sh ~/.local/bin/
cp systemd/backup-home.service ~/.config/systemd/user/
cp systemd/backup-home.timer ~/.config/systemd/user/
```

Poi per il primo backup eseguire


```
chmod +x ~/.local/bin/backup-home.sh
systemctl --user daemon-reload
systemctl --user enable --now backup-home.timer
systemctl --user start backup-home.service
journalctl --user -u backup-home -f
```
