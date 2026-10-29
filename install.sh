#!/usr/bin/env bash
# TRS License — Installation auf einem Linux-Server (Debian/Ubuntu, auch RHEL-Verwandte).
# Einzeiler / One-liner (installiert nach /opt/trs-license, anderer Ordner: TRS_DIR=/pfad):
#   curl -fsSL https://raw.githubusercontent.com/theredstonee/trs-license-docker/main/install.sh | sudo bash
# Oder im Ordner mit den Dateien:  sudo bash install.sh
#
# Zwei Wege nach aussen, der Installer erkennt selbst, welcher passt:
#   Caddy  — Port 80/443 sind frei: eigener Caddy mit automatischem HTTPS (Let's Encrypt).
#   Port   — Port 80/443 sind schon belegt (nginx, Apache, Plesk …): die App bekommt einen freien
#            Port auf 127.0.0.1, dein Webserver bekommt einen Virtual Host fuer die Domain.
#
# Schalter (optional):  --lang de|en  --port 8080  --domain license.firma.de  --email du@firma.de
#                       --caddy (Caddy erzwingen)  --no-vhost (keinen Virtual Host anlegen)
# Ein zweiter Aufruf aktualisiert nur (Dateien + Image holen, neu starten) und fragt nichts mehr.
# Dazu richtet er einen kleinen Update-Dienst ein: im Panel unten links „Jetzt aktualisieren“.
# Nur aktualisieren (nichts neu einrichten, keine Fragen):
#   curl -fsSL https://raw.githubusercontent.com/theredstonee/trs-license-docker/main/update.sh | sudo bash
set -euo pipefail
QUELLE="${TRS_QUELLE:-https://raw.githubusercontent.com/theredstonee/trs-license-docker/main}"   # TRS_QUELLE nur fuer Tests
DATEIEN="docker-compose.yml compose.caddy.yml compose.port.yml Caddyfile install.sh update.sh .env.example README.md version.json"
# Ueber curl | bash gestartet (oder Dateien fehlen): alles nach /opt/trs-license holen und dort weitermachen
if [ -f "$0" ] && [ -f "$(dirname "$0")/docker-compose.yml" ]; then
  cd "$(dirname "$0")"
else
  ZIEL="${TRS_DIR:-/opt/trs-license}"
  echo "==> TRS License: $ZIEL"
  mkdir -p "$ZIEL" && cd "$ZIEL"
  for f in $DATEIEN; do curl -fsSL -o "$f" "$QUELLE/$f" || { [ "$f" = "version.json" ] || [ "$f" = ".env.example" ] || { echo "ERROR: $f"; exit 1; }; }; done
  # Rest des Skripts aus der curl-Leitung leer lesen: exec schliesst sie sonst, waehrend curl noch schreibt
  # (Meldung „curl: (23) Failure writing output to destination“ am Ende, obwohl alles geklappt hat)
  [ -t 0 ] || cat >/dev/null 2>&1 || true
  if { true </dev/tty; } 2>/dev/null; then exec bash ./install.sh "$@" </dev/tty; else exec bash ./install.sh "$@"; fi
fi

PORT=""; DOMAIN=""; EMAIL=""; MODUS=""; VHOST="ja"; SPR=""; NUR_DIENST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --lang) SPR="${2,,}"; shift 2 ;;
    --port) PORT="$2"; MODUS="port"; shift 2 ;;
    --domain) DOMAIN="${2,,}"; shift 2 ;;
    --email) EMAIL="$2"; shift 2 ;;
    --caddy) MODUS="caddy"; shift ;;
    --no-vhost) VHOST="nein"; shift ;;
    --dienst) NUR_DIENST="ja"; shift ;;   # nur den Update-Dienst neu einrichten (ruft update.sh auf)
    *) echo "Unbekannter Schalter / Unknown option: $1"; exit 1 ;;
  esac
done

# Aussehen: Farben nur im Terminal (TRS_FARBE=1 erzwingt sie, NO_COLOR/TERM=dumb schaltet sie ab), Zeichen nur mit UTF-8
if { [ -t 1 ] || [ -n "${TRS_FARBE:-}" ]; } && [ -z "${NO_COLOR:-}" ] && [ "${TERM:-}" != "dumb" ]; then
  R=$'\033[38;2;232;48;48m'; R2=$'\033[38;2;255;110;100m'; G=$'\033[38;2;74;222;128m'; Y=$'\033[38;2;251;191;36m'
  C=$'\033[38;2;125;211;252m'; D=$'\033[2m'; B=$'\033[1m'; U=$'\033[4m'; N=$'\033[0m'
else R=""; R2=""; G=""; Y=""; C=""; D=""; B=""; U=""; N=""; fi
if locale charmap 2>/dev/null | grep -qi 'utf-\?8' || echo "${LANG:-}${LC_ALL:-}" | grep -qi 'utf-\?8'; then
  Z_SCHRITT="▸"; Z_OK="✔"; Z_FEHLER="✖"; Z_FRAGE="?"; Z_PUNKT="·"; K_OL="╭"; K_OR="╮"; K_UL="╰"; K_UR="╯"; K_H="─"; K_V="│"; SPIN=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
else
  Z_SCHRITT=">"; Z_OK="OK"; Z_FEHLER="X"; Z_FRAGE="?"; Z_PUNKT="-"; K_OL="+"; K_OR="+"; K_UL="+"; K_UR="+"; K_H="-"; K_V="|"; SPIN=('|' '/' '-' '\')
fi
VERSION_TXT=$(sed -n 's/.*"version": *"\([^"]*\)".*/\1/p' version.json 2>/dev/null | head -1 || true)
banner() {
  echo ""
  printf '%s\n' "${R}${B}   ████████╗██████╗ ███████╗  ${R2}██╗     ██╗ ██████╗███████╗███╗   ██╗███████╗███████╗${N}" \
                "${R}${B}   ╚══██╔══╝██╔══██╗██╔════╝  ${R2}██║     ██║██╔════╝██╔════╝████╗  ██║██╔════╝██╔════╝${N}" \
                "${R}${B}      ██║   ██████╔╝███████╗  ${R2}██║     ██║██║     █████╗  ██╔██╗ ██║███████╗█████╗  ${N}" \
                "${R}${B}      ██║   ██╔══██╗╚════██║  ${R2}██║     ██║██║     ██╔══╝  ██║╚██╗██║╚════██║██╔══╝  ${N}" \
                "${R}${B}      ██║   ██║  ██║███████║  ${R2}███████╗██║╚██████╗███████╗██║ ╚████║███████║███████╗${N}" \
                "${R}${B}      ╚═╝   ╚═╝  ╚═╝╚══════╝  ${R2}╚══════╝╚═╝ ╚═════╝╚══════╝╚═╝  ╚═══╝╚══════╝╚══════╝${N}"
  echo "   ${D}Lizenzverwaltung fuer deine Software ${Z_PUNKT} license management for your software${N}"
  echo "   ${D}${VERSION_TXT:+v$VERSION_TXT  ${Z_PUNKT}  }by TheRedStonee ${Z_PUNKT} https://www.theredstonee.de/license/${N}"
  echo ""
}
# Kasten um wichtige Werte (Setup-Code, Adresse): kasten FARBE "Zeile" ["Zeile" …]
kasten() {
  local farbe="$1"; shift
  local breit=0 z
  for z in "$@"; do [ ${#z} -gt $breit ] && breit=${#z}; done
  local linie; linie=$(printf "%$((breit + 4))s" "" | sed "s/ /${K_H}/g")
  echo "  ${farbe}${K_OL}${linie}${K_OR}${N}"
  # von Hand auffuellen: printf zaehlt Bytes, ${#z} Zeichen (Umlaute, „·“)
  for z in "$@"; do printf '  %s%s%s  %s%s%s%*s  %s%s%s\n' "$farbe" "$K_V" "$N" "$B" "$z" "$N" $((breit - ${#z})) "" "$farbe" "$K_V" "$N"; done
  echo "  ${farbe}${K_UL}${linie}${K_UR}${N}"
}
[ -n "${TRS_KEIN_BANNER:-}" ] || banner

# Sprache: Schalter → .env → fragen (Standard Deutsch)
[ -n "$SPR" ] || SPR=$(sed -n 's/^TRS_LANG=//p' .env 2>/dev/null | tail -1 || true)
if [ "$SPR" != "de" ] && [ "$SPR" != "en" ]; then
  SPR="de"
  if [ -t 0 ]; then
    echo "  ${Y}${Z_FRAGE}${N} ${B}Sprache / Language:${N}   ${C}1${N}) Deutsch   ${C}2${N}) English"
    read -r -p "    [1] " wahl </dev/tty || true
    case "${wahl:-1}" in 2|en|e|english|English) SPR="en" ;; esac
  fi
fi
s() { if [ "$SPR" = "de" ]; then printf '%s' "$1"; else printf '%s' "$2"; fi; }   # s "deutsch" "english"
say() { # Meldung je Art einfaerben: „==> Fertig/Done“ gruen, „==> “ Schritt, FEHLER/ERROR rot, eingerueckt = Detail
  local m; m=$(s "$1" "$2")
  m=$(printf '%s' "$m" | sed -E "s#(https?://[^ )\"']+)#${C}${U}\1${N}#g")
  case "$m" in
    "==> Fertig"*|"==> Done"*) echo ""; echo "${G}${B}${Z_OK} ${m#==> }${N}" ;;
    "==> "*) echo "${R}${B}${Z_SCHRITT}${N} ${B}${m#==> }${N}" ;;
    FEHLER:*|ERROR:*) echo "${R}${B}${Z_FEHLER} ${m}${N}" ;;
    "    FEHLER"*|"    ERROR"*) echo "  ${R}${Z_FEHLER}${N} ${m#    }" ;;
    "    "*) echo "  ${D}${K_V}${N} ${m#    }" ;;
    *) echo "$m" ;;
  esac
}
# Zum Testen: TRS_DRY_RUN=1 zeigt Aenderungen am Webserver nur an, statt sie auszufuehren.
tu() { if [ "${TRS_DRY_RUN:-}" = "1" ]; then echo "    ($(s Probelauf "dry run")) $*"; else "$@"; fi; }
frage() { # frage "Text" "Vorgabe" -> Antwort (ohne Terminal: Vorgabe)
  local antwort=""
  local text="$1"; text="${text#==> }"; text="${text#    }"
  if [ -t 0 ]; then read -r -p "  ${Y}${Z_FRAGE}${N} ${text} ${D}[$2]${N} " antwort </dev/tty || true; fi
  echo "${antwort:-$2}"
}
ja() { # ja "Text" "j" -> 0 bei ja (akzeptiert j/ja/y/yes)
  local vorgabe="$2" a
  [ "$SPR" = "en" ] && [ "$vorgabe" = "j" ] && vorgabe="y"
  a=$(frage "$1 ($(s j/n y/n))" "$vorgabe"); case "${a,,}" in j|ja|y|yes) return 0 ;; *) return 1 ;; esac
}
belegt() { # lauscht etwas auf dem Port?
  if command -v ss >/dev/null 2>&1; then ss -ltnH "sport = :$1" 2>/dev/null | grep -q .
  else (exec 3<>"/dev/tcp/127.0.0.1/$1") 2>/dev/null; fi
}
wer_lauscht() { ss -ltnpH "sport = :$1" 2>/dev/null | grep -o 'users:(("[^"]*"' | head -1 | sed 's/users:(("//'; }

# 7. Update-Dienst: der Knopf „Jetzt aktualisieren“ im Panel legt update/.update-anfrage ab, ein systemd-Path-Dienst
#    holt dann die aktuellen Dateien + das neue Image und startet neu. So braucht die App keinen Zugriff auf Docker.
updater_einrichten() {
  DIENST_GRUND=""
  cat > /usr/local/bin/trs-license-update.neu <<SKRIPT
#!/usr/bin/env bash
# TRS License — Update auf Anfrage aus dem Panel (angelegt von install.sh, systemd: trs-license-update.path)
set -uo pipefail
DIR="$PWD"; UPD="$PWD/update"; QUELLE="$QUELLE"
cd "\$DIR" || exit 1
[ -f "\$UPD/.update-anfrage" ] || exit 0
rm -f "\$UPD/.update-anfrage"
status() { printf '{"status":"%s","zeit":"%s","meldung":"%s"}\n' "\$1" "\$(date -Is)" "\$2" > "\$UPD/.update-status"; chmod 644 "\$UPD/.update-status"; }
kurz() { echo "\$1" | tail -3 | tr '\n"\\\\' '   '; }
status laeuft ""
# Erst das neueste update.sh holen: es bringt Dateien, Image und diesen Dienst selbst auf den neuesten Stand
neu=\$(mktemp)
if curl -fsSL --max-time 30 -o "\$neu" "\$QUELLE/update.sh?t=\$(date +%s)" 2>/dev/null && bash -n "\$neu" 2>/dev/null; then
  TRS_QUELLE="\$QUELLE" exec bash "\$neu" --dir "\$DIR" --status "\$UPD/.update-status"
fi
rm -f "\$neu"
# GitHub nicht erreichbar: wie bisher nur die Images
# Aktuelle Dateien holen (alte als .bak) — neue Compose-Fassungen kommen so mit
stempel=\$(date +%Y%m%d-%H%M%S)
for f in docker-compose.yml compose.caddy.yml compose.port.yml Caddyfile install.sh README.md version.json .env.example; do
  if curl -fsS --max-time 20 -o "/tmp/trs-upd-\$f" "\$QUELLE/\$f" 2>/dev/null && ! cmp -s "/tmp/trs-upd-\$f" "\$f" 2>/dev/null; then
    [ -f "\$f" ] && cp -a "\$f" "\$f.bak-\$stempel"; mv "/tmp/trs-upd-\$f" "\$f"
  fi
  rm -f "/tmp/trs-upd-\$f"
done
if out=\$(docker compose pull 2>&1 && docker compose up -d 2>&1); then status fertig ""
else status fehler "\$(kurz "\$out")"; fi
SKRIPT
  # erst fertig schreiben, dann umbenennen: ein gerade laufender Dienst liest so seine alte Fassung zu Ende
  chmod 755 /usr/local/bin/trs-license-update.neu && mv -f /usr/local/bin/trs-license-update.neu /usr/local/bin/trs-license-update
  local ausloeser=""
  if command -v systemctl >/dev/null 2>&1 && [ -d /run/systemd/system ]; then
    printf '%s\n' "[Unit]" "Description=TRS License: Update-Anfrage aus dem Panel" "[Path]" "PathExists=$PWD/update/.update-anfrage" "[Install]" "WantedBy=multi-user.target" > /etc/systemd/system/trs-license-update.path
    printf '%s\n' "[Unit]" "Description=TRS License aktualisieren" "[Service]" "Type=oneshot" "ExecStart=/usr/local/bin/trs-license-update" > /etc/systemd/system/trs-license-update.service
    if systemctl daemon-reload && systemctl enable --now trs-license-update.path >/dev/null 2>&1; then ausloeser="systemd"; rm -f /etc/cron.d/trs-license-update; fi
  fi
  # Ohne systemd (z. B. Container-Server, Alpine): cron schaut jede Minute nach einer Anfrage
  if [ -z "$ausloeser" ] && [ -d /etc/cron.d ] && { pgrep -x cron >/dev/null 2>&1 || pgrep -x crond >/dev/null 2>&1; }; then
    printf '%s\n' "# TRS License: Update-Anfrage aus dem Panel (angelegt von install.sh, ohne systemd)" "* * * * * root [ -f \"$PWD/update/.update-anfrage\" ] && /usr/local/bin/trs-license-update >/dev/null 2>&1" > /etc/cron.d/trs-license-update
    chmod 644 /etc/cron.d/trs-license-update; ausloeser="cron"
  fi
  [ -n "$ausloeser" ] || { DIENST_GRUND="$(s "Weder systemd noch cron laufen auf diesem Server – ohne einen davon kann der Knopf im Panel nichts ausloesen." "Neither systemd nor cron is running on this server – without one the panel button cannot trigger anything.")"; return 1; }
  printf 'TRS License Update-Dienst\naktionen=update\nstand=2\n' > update/.updater && chown 1000:1000 update/.updater 2>/dev/null || true
  say "==> Update-Dienst eingerichtet ($ausloeser; Panel → Version unten links → „Jetzt aktualisieren“)" "==> Update service set up ($ausloeser; panel → version at the bottom left → “Update now”)"
}


# Nur den Update-Dienst neu einrichten (update.sh ruft das nach jedem Update auf) — ohne Fragen, sonst bleibt alles
if [ -n "$NUR_DIENST" ]; then
  mkdir -p update && chown 1000:1000 update 2>/dev/null || true
  [ "${TRS_DRY_RUN:-}" = "1" ] && exit 0
  updater_einrichten || { say "FEHLER: Update-Dienst nicht eingerichtet: $DIENST_GRUND" "ERROR: update service not set up: $DIENST_GRUND"; exit 1; }
  exit 0
fi

say "==> TRS License wird eingerichtet" "==> Setting up TRS License"

# 0. Zweiter Aufruf im Installationsordner: aktuelle Dateien holen (alte bleiben als .bak), damit Neuerungen der
#    Compose-Dateien (z. B. der Update-Ordner) auch bei bestehenden Installationen ankommen.
if [ -f .env ] && [ "${TRS_DRY_RUN:-}" != "1" ] && curl -fsS --max-time 8 -o /tmp/trs-version.json "$QUELLE/version.json" 2>/dev/null; then
  stempel=$(date +%Y%m%d-%H%M%S); neu=0
  for f in docker-compose.yml compose.caddy.yml compose.port.yml Caddyfile README.md version.json .env.example; do
    if curl -fsS --max-time 15 -o "/tmp/trs-$f" "$QUELLE/$f" 2>/dev/null && ! cmp -s "/tmp/trs-$f" "$f" 2>/dev/null; then
      [ -f "$f" ] && cp -a "$f" "$f.bak-$stempel"; mv "/tmp/trs-$f" "$f"; neu=$((neu + 1))
    fi
    rm -f "/tmp/trs-$f"
  done
  [ "$neu" -gt 0 ] && say "==> $neu Datei(en) auf den neuesten Stand gebracht (alte Fassung: *.bak-$stempel)" "==> Updated $neu file(s) to the latest version (old copy: *.bak-$stempel)"
fi

# 1. Docker (falls noch nicht da)
if ! command -v docker >/dev/null 2>&1; then
  say "==> Docker wird installiert …" "==> Installing Docker …"
  curl -fsSL https://get.docker.com | sh
fi
docker compose version >/dev/null 2>&1 || { say "FEHLER: 'docker compose' fehlt. Bitte Docker aktualisieren." "ERROR: 'docker compose' is missing. Please update Docker."; exit 1; }
for f in docker-compose.yml compose.caddy.yml compose.port.yml Caddyfile; do
  [ -f "$f" ] || { say "FEHLER: $f fehlt neben install.sh. Bitte alle Dateien aus dem Paket in diesen Ordner legen." "ERROR: $f is missing next to install.sh. Please put all files of the package into this folder."; exit 1; }
done

# 2. Bei wenig Arbeitsspeicher eine Auslagerungsdatei anlegen (unter 1,5 GB RAM, noch kein Swap)
ram_mb=$(awk '/MemTotal/ {print int($2/1024)}' /proc/meminfo)
if [ "$ram_mb" -lt 1500 ] && [ "$(swapon --noheadings 2>/dev/null | wc -l)" -eq 0 ] && [ ! -f /swapfile ]; then
  say "==> Nur ${ram_mb} MB RAM: lege 1 GB Auslagerungsdatei an …" "==> Only ${ram_mb} MB RAM: creating a 1 GB swap file …"
  fallocate -l 1G /swapfile && chmod 600 /swapfile && mkswap /swapfile >/dev/null && swapon /swapfile
  grep -q '^/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

# 3. .env: Datenbank-Passwort nur beim ersten Mal (sonst passt es nicht mehr zur Datenbank)
if [ ! -f .env ]; then
  printf 'DB_PASSWORD=%s\nTZ=Europe/Berlin\nTRS_LANG=%s\n' "$(head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n')" "$SPR" > .env
  chmod 600 .env
  say "==> .env mit zufaelligem Datenbank-Passwort angelegt" "==> Created .env with a random database password"
fi
grep -q '^TRS_LANG=' .env || echo "TRS_LANG=$SPR" >> .env

# 4. Weg nach aussen festlegen — nur, solange die .env noch keinen kennt
if ! grep -q '^COMPOSE_FILE=' .env; then
  # Bestehende Installation mit altem Compose (Caddy stand noch in docker-compose.yml): Caddy behalten.
  if [ -z "$MODUS" ] && docker ps --filter "label=com.docker.compose.service=caddy" --format '{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null | grep -qx "$PWD"; then
    MODUS="caddy"
  fi
  if [ -z "$MODUS" ]; then
    if belegt 80 || belegt 443; then
      server=$(wer_lauscht 80 || true); [ -n "$server" ] || server=$(wer_lauscht 443 || true)
      echo ""
      say "==> Port 80/443 sind schon belegt (${server:-unbekannter Dienst})." "==> Ports 80/443 are already in use (${server:-unknown service})."
      say "    TRS License bekommt dann einen eigenen Port auf 127.0.0.1, und dein Webserver" "    TRS License then gets its own port on 127.0.0.1, and your web server"
      say "    leitet die Domain dorthin weiter (Virtual Host, HTTPS ueber deinen Webserver)." "    forwards the domain to it (virtual host, HTTPS through your web server)."
      if ja "$(s "So einrichten? Bei Nein versucht Caddy, Port 80/443 selbst zu belegen." "Set it up like this? If no, Caddy tries to take ports 80/443 itself.")" "j"; then MODUS="port"; else MODUS="caddy"; fi
    else
      MODUS="caddy"
    fi
  fi

  if [ "$MODUS" = "port" ]; then
    if [ -z "$PORT" ]; then
      for p in 8080 8081 8082 8088 8090 8100 8180 8280 3100 3200 9080; do belegt "$p" || { PORT=$p; break; }; done
      [ -n "$PORT" ] || { say "FEHLER: kein freier Port gefunden. Bitte mit --port angeben." "ERROR: no free port found. Please pass one with --port."; exit 1; }
      PORT=$(frage "$(s "Port fuer TRS License (frei)" "Port for TRS License (free)")" "$PORT")
    fi
    belegt "$PORT" && { say "FEHLER: Port $PORT ist belegt." "ERROR: port $PORT is in use."; exit 1; }
    [ -n "$DOMAIN" ] || DOMAIN=$(frage "$(s "Domain, unter der das Panel laufen soll (leer = spaeter)" "Domain for the panel (empty = later)")" "")
    DOMAIN="${DOMAIN,,}"
    {
      echo "COMPOSE_FILE=docker-compose.yml:compose.port.yml"
      echo "TRS_PORT=$PORT"
      echo "TRS_BIND=127.0.0.1"
      echo "TRS_PROXY_DOMAIN=$DOMAIN"
    } >> .env
    say "==> App hoert auf 127.0.0.1:$PORT (ohne eigenen Caddy)" "==> App listens on 127.0.0.1:$PORT (without its own Caddy)"
  else
    echo "COMPOSE_FILE=docker-compose.yml:compose.caddy.yml" >> .env
    say "==> Caddy uebernimmt Port 80/443 und holt das Zertifikat selbst" "==> Caddy takes ports 80/443 and gets the certificate itself"
  fi
fi
# Werte aus der .env (auch bei einem zweiten Aufruf)
PORT=$(sed -n 's/^TRS_PORT=//p' .env | tail -1)
[ -n "$DOMAIN" ] || DOMAIN=$(sed -n 's/^TRS_PROXY_DOMAIN=//p' .env | tail -1)
grep -q 'compose.port.yml' .env && MODUS="port" || MODUS="caddy"

# 5. Update-Ordner: die App (Benutzer node, UID 1000) legt dort Anfragen ab, der Dienst auf dem Server antwortet
mkdir -p update && chown 1000:1000 update 2>/dev/null || true

# 6. Starten
say "==> Image wird geladen und gestartet …" "==> Pulling the image and starting …"
if [ -d .output ]; then docker compose up -d --build; else docker compose pull -q && docker compose up -d; fi

# 7. Update-Dienst einrichten (Funktion steht oben)
[ "${TRS_DRY_RUN:-}" = "1" ] || updater_einrichten || say "    Update-Dienst nicht eingerichtet: $DIENST_GRUND" "    Update service not set up: $DIENST_GRUND"

# 8. Virtual Host fuer die Domain in deinem Webserver (nur im Port-Modus, nur mit Domain)
vhost_angelegt=""
if [ "$MODUS" = "port" ] && [ -n "$DOMAIN" ] && [ "$VHOST" = "ja" ]; then
  webserver=""
  if command -v nginx >/dev/null 2>&1; then webserver="nginx"
  elif command -v apache2ctl >/dev/null 2>&1; then webserver="apache2"
  elif command -v httpd >/dev/null 2>&1; then webserver="httpd"
  fi
  # Zeigt schon ein Eintrag auf diesen Port (zweiter Aufruf)? Dann nichts neu anlegen.
  if [ -n "$webserver" ] && grep -RlsE "(proxy_pass|ProxyPass[[:space:]]+/)[[:space:]]+http://(127\.0\.0\.1|localhost):${PORT}(/|;|[[:space:]]|$)" /etc/nginx/sites-enabled /etc/nginx/conf.d /etc/apache2/sites-enabled /etc/httpd/conf.d 2>/dev/null | grep -q . || [ "${PIPESTATUS[1]:-1}" = "0" ]; then
    vhost_angelegt="vorhanden"; https_ok=1; webserver=""
  fi
  if [ -n "$webserver" ] && ja "$(s "Virtual Host fuer $DOMAIN in $webserver anlegen (Backup vorhandener Dateien, Konfigtest, Neuladen)?" "Create a virtual host for $DOMAIN in $webserver (backup of existing files, config test, reload)?")" "j"; then
    stempel=$(date +%Y%m%d-%H%M%S)
    if [ "$webserver" = "nginx" ]; then
      if [ -d /etc/nginx/sites-enabled ]; then datei=/etc/nginx/sites-available/trs-license.conf; link=/etc/nginx/sites-enabled/trs-license.conf
      else datei=/etc/nginx/conf.d/trs-license.conf; link=""; fi
      inhalt="# TRS License — angelegt von install.sh am $stempel
server {
    listen 80;
    listen [::]:80;
    server_name $DOMAIN;
    client_max_body_size 20m;
    location / {
        proxy_pass http://127.0.0.1:$PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}"
      [ -f "$datei" ] && tu cp -a "$datei" "$datei.bak-$stempel"
      if [ "${TRS_DRY_RUN:-}" = "1" ]; then echo "    ($(s Probelauf "dry run")) $datei:"; echo "$inhalt" | sed 's/^/        /'; else printf '%s\n' "$inhalt" > "$datei"; fi
      [ -n "$link" ] && tu ln -sf "$datei" "$link"
      if tu nginx -t; then tu systemctl reload nginx 2>/dev/null || tu nginx -s reload; vhost_angelegt="$webserver"
      else say "    FEHLER: nginx -t schlaegt fehl — Datei $datei bitte pruefen (Backup: $datei.bak-$stempel)." "    ERROR: nginx -t fails — please check $datei (backup: $datei.bak-$stempel)."; fi
    else
      if [ "$webserver" = "apache2" ]; then datei=/etc/apache2/sites-available/trs-license.conf; else datei=/etc/httpd/conf.d/trs-license.conf; fi
      inhalt="# TRS License — angelegt von install.sh am $stempel
<VirtualHost *:80>
    ServerName $DOMAIN
    ProxyPreserveHost On
    ProxyPass / http://127.0.0.1:$PORT/
    ProxyPassReverse / http://127.0.0.1:$PORT/
    RequestHeader set X-Forwarded-Proto \"expr=%{REQUEST_SCHEME}\"
</VirtualHost>"
      [ -f "$datei" ] && tu cp -a "$datei" "$datei.bak-$stempel"
      if [ "${TRS_DRY_RUN:-}" = "1" ]; then echo "    ($(s Probelauf "dry run")) $datei:"; echo "$inhalt" | sed 's/^/        /'; else printf '%s\n' "$inhalt" > "$datei"; fi
      if [ "$webserver" = "apache2" ]; then
        tu a2enmod -q proxy proxy_http headers
        tu a2ensite -q trs-license.conf
        if tu apache2ctl configtest; then tu systemctl reload apache2; vhost_angelegt="$webserver"; else say "    FEHLER: Apache-Konfigtest schlaegt fehl — $datei bitte pruefen." "    ERROR: Apache config test fails — please check $datei."; fi
      else
        if tu httpd -t; then tu systemctl reload httpd; vhost_angelegt="$webserver"; else say "    FEHLER: httpd -t schlaegt fehl — $datei bitte pruefen." "    ERROR: httpd -t fails — please check $datei."; fi
      fi
    fi
  elif [ -z "$webserver" ] && [ -z "$vhost_angelegt" ]; then
    say "==> Keinen nginx/Apache gefunden — die Vorlage fuer deinen Webserver steht unten." "==> No nginx/Apache found — the template for your web server is below."
  fi

  # 9. Zertifikat per certbot (HTTP-01 ueber den gerade angelegten Virtual Host)
  if [ -n "$vhost_angelegt" ] && [ "$vhost_angelegt" != "vorhanden" ]; then
    plugin="nginx"; [ "$vhost_angelegt" = "nginx" ] || plugin="apache"
    meine_ip=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)
    domain_ip=$(getent ahostsv4 "$DOMAIN" 2>/dev/null | awk '{print $1; exit}' || true)
    if [ -n "$meine_ip" ] && [ "$domain_ip" != "$meine_ip" ]; then
      say "==> $DOMAIN zeigt auf '${domain_ip:-nichts}', dieser Server hat $meine_ip — Zertifikat spaeter holen:" "==> $DOMAIN points to '${domain_ip:-nothing}', this server has $meine_ip — get the certificate later:"
      say "    certbot --$plugin -d $DOMAIN --redirect" "    certbot --$plugin -d $DOMAIN --redirect"
    elif ja "$(s "HTTPS-Zertifikat fuer $DOMAIN mit certbot holen (Let's Encrypt)?" "Get an HTTPS certificate for $DOMAIN with certbot (Let's Encrypt)?")" "j"; then
      if ! command -v certbot >/dev/null 2>&1; then
        if command -v apt-get >/dev/null 2>&1; then tu apt-get install -y -qq certbot "python3-certbot-$plugin"
        elif command -v dnf >/dev/null 2>&1; then tu dnf install -y -q certbot "python3-certbot-$plugin"
        else say "    certbot fehlt und konnte nicht installiert werden — bitte von Hand: certbot --$plugin -d $DOMAIN --redirect" "    certbot is missing and could not be installed — please run manually: certbot --$plugin -d $DOMAIN --redirect"; fi
      fi
      if command -v certbot >/dev/null 2>&1 || [ "${TRS_DRY_RUN:-}" = "1" ]; then
        [ -n "$EMAIL" ] || EMAIL=$(frage "$(s "E-Mail fuer Ablauf-Hinweise von Let's Encrypt (leer = keine)" "E-mail for expiry notices from Let's Encrypt (empty = none)")" "")
        if [ -n "$EMAIL" ]; then mail_arg=(-m "$EMAIL"); else mail_arg=(--register-unsafely-without-email); fi
        if tu certbot "--$plugin" -d "$DOMAIN" --redirect -n --agree-tos "${mail_arg[@]}"; then https_ok=1
        else say "    certbot hat nicht geklappt (Ausgabe oben). Spaeter nochmal: certbot --$plugin -d $DOMAIN --redirect" "    certbot did not work (output above). Try again later: certbot --$plugin -d $DOMAIN --redirect"; fi
      fi
    fi
  fi
fi

# 10. Auf die App warten und den Setup-Code zeigen
say "==> Warte auf den Start …" "==> Waiting for the start …"
for n in $(seq 1 60); do
  if docker compose logs app 2>/dev/null | grep -q 'Setup-Code\|bereit\|ready'; then break; fi
  for k in 0 1 2 3 4 5 6 7; do [ -t 1 ] && printf '\r  %s%s%s %s' "$R" "${SPIN[$(( (n * 8 + k) % ${#SPIN[@]} ))]}" "$N" "$(s "TRS License startet" "TRS License is starting") ($((n * 2)) s)"; sleep 0.25; done
done
[ -t 1 ] && printf '\r\033[K'
# IP fuer die Adresse: die oeffentliche nur, wenn sie auf dem Server selbst liegt (VPS); sonst (hinter einem Router)
# die IP, ueber die der Server ins Netz geht.
ip_pub=$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)
ip_lan=$(ip -4 route get 1.1.1.1 2>/dev/null | sed -n 's/.* src \([0-9.]*\).*/\1/p' | head -1 || true)
[ -n "$ip_lan" ] || ip_lan=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -n "$ip_pub" ] && ip -4 addr 2>/dev/null | grep -qF "inet ${ip_pub}/"; then ip="$ip_pub"
elif [ -n "$ip_lan" ]; then ip="$ip_lan"
else ip="$ip_pub"; fi
code=$(docker compose logs app 2>/dev/null | grep -o 'Setup-Code: *[A-Za-z0-9-]\{6,\}' | tail -1 | sed 's/.*: *//' || true)
echo ""
if [ -n "$code" ]; then
  kasten "$R" "$(s "Setup-Code" "Setup code"):  $code" "$(s "Brauchst du gleich im Browser." "You need it in the browser in a moment.")"
elif docker compose logs app 2>/dev/null | grep -q 'bereit'; then
  say "    Schon eingerichtet — kein Setup-Code noetig." "    Already set up — no setup code needed."
fi
echo ""
ziel_url=""
if [ "$MODUS" = "port" ]; then
  if [ -n "$vhost_angelegt" ]; then
    if [ -n "${https_ok:-}" ]; then ziel_url="https://${DOMAIN}"; else ziel_url="http://${DOMAIN}"; fi
    say "==> Fertig. Oeffne im Browser:  $ziel_url" "==> Done. Open in your browser:  $ziel_url"
  else
    say "==> Fertig. Die App hoert auf 127.0.0.1:${PORT}. Trage in deinem Webserver einen Virtual Host ein:" "==> Done. The app listens on 127.0.0.1:${PORT}. Add a virtual host to your web server:"
    echo ""
    echo "    nginx:                                                 Apache:"
    echo "    server {                                               <VirtualHost *:80>"
    echo "        listen 80;                                             ServerName ${DOMAIN:-license.example.com}"
    echo "        server_name ${DOMAIN:-license.example.com};          ProxyPreserveHost On"
    echo "        location / {                                           ProxyPass / http://127.0.0.1:${PORT}/"
    echo "            proxy_pass http://127.0.0.1:${PORT};               ProxyPassReverse / http://127.0.0.1:${PORT}/"
    echo "            proxy_set_header Host \$host;                       RequestHeader set X-Forwarded-Proto \"expr=%{REQUEST_SCHEME}\""
    echo "            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;   </VirtualHost>"
    echo "            proxy_set_header X-Forwarded-Proto \$scheme;"
    echo "        }"
    echo "    }"
    echo ""
    say "    HTTPS danach z. B. mit:  certbot --nginx -d ${DOMAIN:-license.example.com} --redirect" "    HTTPS afterwards e.g. with:  certbot --nginx -d ${DOMAIN:-license.example.com} --redirect"
    say "    Zum Ausprobieren ohne Domain:  ssh -L ${PORT}:127.0.0.1:${PORT} root@${ip}  und dann  http://127.0.0.1:${PORT}" "    To try it without a domain:  ssh -L ${PORT}:127.0.0.1:${PORT} root@${ip}  and then  http://127.0.0.1:${PORT}"
  fi
  say "    Im Assistenten ist „Hinter eigenem Proxy“ mit deiner Domain schon vorgewaehlt." "    In the wizard, “Behind your own proxy” with your domain is already preselected."
else
  ziel_url="http://${ip}"
  say "==> Fertig. Oeffne im Browser:  $ziel_url" "==> Done. Open in your browser:  $ziel_url"
  say "    Firewall: Port 80 und 443 muessen von aussen erreichbar sein." "    Firewall: ports 80 and 443 must be reachable from outside."
fi
say "    Den Setup-Code siehst du oben (oder: docker compose logs app | grep Setup-Code)." "    You can see the setup code above (or: docker compose logs app | grep Setup-Code)."
if [ -n "$ziel_url" ]; then echo ""; kasten "$G" "TRS License  ${Z_PUNKT}  $ziel_url"; fi
echo ""
