#!/usr/bin/env bash
# TRS License — Installation auf einem frischen Linux-Server (Debian/Ubuntu).
# Aufruf im entpackten Ordner:  sudo bash install.sh
set -euo pipefail
cd "$(dirname "$0")"

echo "==> TRS License wird eingerichtet"

# 1. Docker (falls noch nicht da)
if ! command -v docker >/dev/null 2>&1; then
  echo "==> Docker wird installiert …"
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || { echo "FEHLER: 'docker compose' fehlt. Bitte Docker aktualisieren."; exit 1; }

# 2. Bei wenig Arbeitsspeicher eine Auslagerungsdatei anlegen (unter 1,5 GB RAM, noch kein Swap)
ram_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if [ "$ram_mb" -lt 1500 ] && [ "$(swapon --noheadings | wc -l)" -eq 0 ] && [ ! -f /swapfile ]; then
  echo "==> Nur ${ram_mb} MB RAM: lege 1 GB Auslagerungsdatei an …"
  fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 3. Datenbank-Passwort erzeugen (nur beim ersten Mal — sonst passt es nicht mehr zur Datenbank)
if [ ! -f .env ]; then
  printf 'DB_PASSWORD=%s\nTZ=Europe/Berlin\n' "$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')" > .env
  chmod 600 .env
  echo "==> .env mit zufaelligem Datenbank-Passwort angelegt"
fi

# 4. Starten
if [ -d .output ]; then docker compose up -d --build; else docker compose pull && docker compose up -d; fi

# 5. Auf die App warten und den Setup-Code zeigen
echo "==> Warte auf den Start …"
for _ in $(seq 1 60); do
  if docker compose logs app 2>/dev/null | grep -q 'Setup-Code\|bereit'; then break; fi
  sleep 2
done
ip=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')
echo ""
docker compose logs app 2>/dev/null | grep -A1 -B2 'Setup-Code' | tail -5 || true
echo ""
echo "==> Fertig. Oeffne im Browser:  http://${ip}"
echo "    Den Setup-Code siehst du oben (oder: docker compose logs app | grep Setup-Code)."
echo "    Firewall: Port 80 und 443 muessen von aussen erreichbar sein."
