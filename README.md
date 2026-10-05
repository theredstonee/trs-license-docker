# TRS License

**Selbst gehostete Lizenzverwaltung für deine Software** — Lizenzschlüssel erstellen, an Geräte binden, sperren und online prüfen. Läuft als Docker-Paket auf deinem eigenen Server, mit automatischem HTTPS.

By [TheRedStonee](https://www.theredstonee.de/) · kostenlos nutzbar

> **English:** Self-hosted license management for your software. Create license keys, bind them to devices, block them and validate them through a signed HTTP API. One `docker compose up`, automatic HTTPS via Let's Encrypt. The panel is currently in German. Jump to [Quick start](#schnellstart).

---

## Was es kann

- **Lizenzen** — Schlüssel einzeln oder im Stapel erzeugen, Ablaufdatum, sperren und entsperren, Kunde und Notiz, Suche und Filter
- **Produkte & Tarife** — Laufzeit, Geräteanzahl, Test-Tarife und frei benennbare Funktionen pro Tarif
- **Geräte-Bindung** — jede Lizenz gilt für eine festgelegte Anzahl Geräte; Geräte lassen sich einzeln zurücksetzen
- **Prüf-API** — `validate`, `activate`, `heartbeat`, `deactivate`; jede Antwort ist mit Ed25519 signiert, damit sie niemand fälschen kann
- **Offline-Lizenzen** — signierte Lizenzdateien für Rechner ohne Internet, dazu eine einstellbare Kulanzzeit, wenn dein Server nicht erreichbar ist
- **Verwaltungs-API** — Lizenzen aus deinem Shop oder eigenen Skripten erstellen, ändern, sperren und löschen (API-Schlüssel mit Lese- oder Schreibrecht)
- **Webhooks** — Ereignisse wie „Lizenz gesperrt“ oder „Gerät aktiviert“ an eigene Adressen, signiert und mit automatischer Wiederholung
- **E-Mail-Versand** — Lizenzschlüssel und Ablauf-Erinnerungen über deinen eigenen Mailserver (SMTP)
- **Kunden-Portal** — Kunden melden sich per Link aus der E-Mail an, sehen ihre Lizenzen, setzen Geräte selbst zurück und laden Offline-Dateien
- **Zahlungen mit Stripe** — nach einer Zahlung entsteht die Lizenz von selbst und geht an den Käufer; bei Erstattung wird sie gesperrt
- **Team & Rollen** — mehrere Konten als Inhaber, Admin oder „Nur lesen“, dazu ein Protokoll, wer wann was getan hat
- **Export, Import, Sicherung** — Lizenzen als CSV oder JSON, komplette Sicherung in einer Datei und Wiederherstellung im Panel
- **Zwei-Faktor-Anmeldung** — Code aus einer Authenticator-App plus Notfall-Codes
- **Dashboard** — aktive Lizenzen, Geräte, Prüfungen pro Tag, bald ablaufende Lizenzen
- **Code-Beispiele** im Panel für cURL, JavaScript, Python, PHP, C# und Java (z. B. Minecraft-Plugins)
- **Einrichtungs-Assistent** — Design und Akzentfarbe wählen, Domain verbinden, Admin-Konto anlegen; die Domain lässt sich später in den Einstellungen ändern
- **Automatisches HTTPS** — Zertifikat von Let's Encrypt, wird von selbst verlängert

## Voraussetzungen

| | Minimum | Empfohlen |
|---|---|---|
| CPU | 1 vCPU | 1–2 vCPU |
| RAM | 1 GB | 2 GB |
| Speicher | 5 GB frei | 10 GB |

- Linux-Server (Debian oder Ubuntu) mit Root-Zugriff
- Port **80** und **443** von außen erreichbar
- Für HTTPS: eine (Sub-)Domain, deren DNS-A-Eintrag auf den Server zeigt

Im Leerlauf brauchen App und Datenbank zusammen rund 60 MB RAM.

## Schnellstart

```bash
mkdir trs-license && cd trs-license
for f in docker-compose.yml Caddyfile install.sh; do curl -fsSLO "https://raw.githubusercontent.com/theredstonee/trs-license-docker/main/$f"; done
sudo bash install.sh
```

Das Skript installiert Docker (falls nötig), erzeugt ein Datenbank-Passwort, startet alles und zeigt dir am Ende die Adresse und den **Setup-Code**. Öffne die Adresse im Browser und folge dem Assistenten.

<details>
<summary>Lieber von Hand?</summary>

```bash
mkdir trs-license && cd trs-license
for f in docker-compose.yml Caddyfile .env.example; do curl -fsSLO "https://raw.githubusercontent.com/theredstonee/trs-license-docker/main/$f"; done
cp .env.example .env
nano .env                # DB_PASSWORD setzen (lang und zufällig)
docker compose up -d
docker compose logs app | grep Setup-Code
```

Danach `http://<IP-deines-Servers>` im Browser öffnen.
</details>

### Domain und HTTPS

Im Assistenten gibst du deine Domain ein. Er zeigt dir die erkannte Server-IP und den nötigen DNS-Eintrag, prüft ihn und holt das Zertifikat.

- Lege einen **A-Eintrag** auf die IP deines Servers an.
- Bei **Cloudflare**: Proxy ausschalten (graue Wolke), sonst kann das Zertifikat nicht ausgestellt werden.
- Du nutzt schon einen eigenen Reverse-Proxy (nginx, Traefik, Cloudflare Tunnel)? Wähle im Assistenten „Hinter eigenem Proxy“. Der Proxy muss `X-Forwarded-Proto` und `X-Forwarded-For` setzen.

## Deine Software anbinden

```bash
curl -X POST https://license.deinefirma.de/api/v1/activate \
  -H "Content-Type: application/json" \
  -d '{"key":"TRS-XXXX-XXXX-XXXX","product":"mein-produkt","hwid":"GERAETE-ID"}'
```

```json
{
  "valid": true,
  "code": "OK",
  "license": { "plan": "Pro", "expiresAt": "2027-10-12T21:59:59.000Z", "maxDevices": 3, "devices": 1, "features": ["export"] },
  "payload": "…",
  "signature": "…"
}
```

| Code | Bedeutung |
|---|---|
| `OK` | Alles in Ordnung |
| `NOT_FOUND` | Schlüssel unbekannt |
| `BLOCKED` | Lizenz gesperrt |
| `EXPIRED` | Lizenz abgelaufen |
| `WRONG_PRODUCT` | Schlüssel gehört zu einem anderen Produkt |
| `DEVICE_LIMIT` | Alle Geräteplätze belegt |
| `NOT_ACTIVATED` | Gerät noch nicht aktiviert |

Fertige Beispiele für sechs Sprachen und den öffentlichen Schlüssel zum Prüfen der Signatur findest du im Panel unter **API & Beispiele**.

### Lizenzen automatisch verwalten

Lege im Panel unter **API-Schlüssel** einen Schlüssel an und rufe damit die Verwaltungs-API auf:

```bash
curl -X POST https://license.deinefirma.de/api/v1/licenses \
  -H "Authorization: Bearer trsl_DEIN_SCHLUESSEL" \
  -H "Content-Type: application/json" \
  -d '{"product":"mein-produkt","plan":"Standard","customer":{"email":"kunde@beispiel.de"}}'
```

| Methode | Pfad | Zweck |
|---|---|---|
| `GET` | `/api/v1/licenses` | Lizenzen auflisten und filtern |
| `POST` | `/api/v1/licenses` | Lizenzen erzeugen |
| `GET` | `/api/v1/licenses/{key}` | Eine Lizenz mit ihren Geräten |
| `PATCH` | `/api/v1/licenses/{key}` | Sperren, verlängern, ändern |
| `DELETE` | `/api/v1/licenses/{key}` | Lizenz löschen |
| `DELETE` | `/api/v1/licenses/{key}/devices/{hwid}` | Gerät zurücksetzen |
| `GET` | `/api/v1/products` | Produkte und Tarife |


## Betrieb

**Aktualisieren**

```bash
cd trs-license
docker compose pull && docker compose up -d
```

Die Datenbank wird beim Start automatisch auf den neuen Stand gebracht.

**Sichern**

```bash
docker compose exec -T db pg_dump -U trs trs_license | gzip > backup-$(date +%F).sql.gz
```

**Wiederherstellen**

```bash
gunzip -c backup-2026-10-05.sql.gz | docker compose exec -T db psql -U trs trs_license
```

**Protokoll ansehen**

```bash
docker compose logs -f app
```

**Zwei-Faktor-Anmeldung verloren?** Handy weg und keine Notfall-Codes mehr: einmal mit zurückgesetzter 2FA starten, danach normal.

```bash
TRS_RESET_2FA=deinbenutzername docker compose up -d app
docker compose up -d app
```

## Sicherheit

- Passwörter mit bcrypt, Sitzungen als httpOnly-Cookie, HTTPS wird erzwungen, sobald eine Domain eingerichtet ist
- Zwei-Faktor-Anmeldung per Authenticator-App; nach mehreren Fehlversuchen wird die Anmeldung vorübergehend gesperrt
- API-Schlüssel werden nur als Fingerabdruck gespeichert; Webhooks an Adressen im privaten Netz sind gesperrt
- Der Setup-Code aus dem Container-Log schützt eine frische Installation, bis du sie eingerichtet hast
- App und Datenbank sind nicht direkt aus dem Internet erreichbar, nur über den HTTPS-Proxy
- Der Container läuft nicht als root

Eine Sicherheitslücke gefunden? Bitte nicht öffentlich melden, sondern über das [Kontaktformular](https://www.theredstonee.de/contact/).

## Lizenz

TRS License ist **kostenlos nutzbar**, aber **nicht Open Source**. Der Quellcode ist nicht öffentlich. Du darfst das Image für eigene und kommerzielle Zwecke betreiben. Der Hinweis „By TheRedStonee“ im Panel bleibt erhalten. Weiterverkauf und Zurückentwickeln sind nicht erlaubt.

Dieses Repository enthält nur die Installationsdateien. Das Image liegt unter [`ghcr.io/theredstonee/trs-license`](https://github.com/users/theredstonee/packages/container/package/trs-license).

---

[theredstonee.de](https://www.theredstonee.de/) · [Discord](https://dc.theredstonee.de) · Fehler und Wünsche: [Issues](https://github.com/theredstonee/trs-license-docker/issues)
