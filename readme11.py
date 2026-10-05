# README des oeffentlichen Repos auf Stand 1.1 bringen
import io
p = 'README.md'
s = io.open(p, encoding='utf-8').read()


def ed(a, n):
    global s
    assert s.count(a) == 1, a[:60]
    s = s.replace(a, n)


ed("- **Dashboard** — aktive Lizenzen, Geräte, Prüfungen pro Tag, bald ablaufende Lizenzen\n",
   "- **Offline-Lizenzen** — signierte Lizenzdateien für Rechner ohne Internet, dazu eine einstellbare Kulanzzeit, wenn dein Server nicht erreichbar ist\n"
   "- **Verwaltungs-API** — Lizenzen aus deinem Shop oder eigenen Skripten erstellen, ändern, sperren und löschen (API-Schlüssel mit Lese- oder Schreibrecht)\n"
   "- **Webhooks** — Ereignisse wie „Lizenz gesperrt“ oder „Gerät aktiviert“ an eigene Adressen, signiert und mit automatischer Wiederholung\n"
   "- **Zwei-Faktor-Anmeldung** — Code aus einer Authenticator-App plus Notfall-Codes\n"
   "- **Dashboard** — aktive Lizenzen, Geräte, Prüfungen pro Tag, bald ablaufende Lizenzen\n")
ed("Fertige Beispiele für sechs Sprachen und den öffentlichen Schlüssel zum Prüfen der Signatur findest du im Panel unter **API & Beispiele**.",
   "Fertige Beispiele für sechs Sprachen und den öffentlichen Schlüssel zum Prüfen der Signatur findest du im Panel unter **API & Beispiele**.\n\n"
   "### Lizenzen automatisch verwalten\n\n"
   "Lege im Panel unter **API-Schlüssel** einen Schlüssel an und rufe damit die Verwaltungs-API auf:\n\n"
   "```bash\n"
   "curl -X POST https://license.deinefirma.de/api/v1/licenses \\\n"
   "  -H \"Authorization: Bearer trsl_DEIN_SCHLUESSEL\" \\\n"
   "  -H \"Content-Type: application/json\" \\\n"
   "  -d '{\"product\":\"mein-produkt\",\"plan\":\"Standard\",\"customer\":{\"email\":\"kunde@beispiel.de\"}}'\n"
   "```\n\n"
   "| Methode | Pfad | Zweck |\n|---|---|---|\n"
   "| `GET` | `/api/v1/licenses` | Lizenzen auflisten und filtern |\n"
   "| `POST` | `/api/v1/licenses` | Lizenzen erzeugen |\n"
   "| `GET` | `/api/v1/licenses/{key}` | Eine Lizenz mit ihren Geräten |\n"
   "| `PATCH` | `/api/v1/licenses/{key}` | Sperren, verlängern, ändern |\n"
   "| `DELETE` | `/api/v1/licenses/{key}` | Lizenz löschen |\n"
   "| `DELETE` | `/api/v1/licenses/{key}/devices/{hwid}` | Gerät zurücksetzen |\n"
   "| `GET` | `/api/v1/products` | Produkte und Tarife |\n")
ed("**Protokoll ansehen**\n\n```bash\ndocker compose logs -f app\n```",
   "**Protokoll ansehen**\n\n```bash\ndocker compose logs -f app\n```\n\n"
   "**Zwei-Faktor-Anmeldung verloren?** Handy weg und keine Notfall-Codes mehr: einmal mit zurückgesetzter 2FA starten, danach normal.

"
   "```bash
TRS_RESET_2FA=deinbenutzername docker compose up -d app
docker compose up -d app
```")
ed("- Passwörter mit bcrypt, Sitzungen als httpOnly-Cookie, HTTPS wird erzwungen, sobald eine Domain eingerichtet ist\n",
   "- Passwörter mit bcrypt, Sitzungen als httpOnly-Cookie, HTTPS wird erzwungen, sobald eine Domain eingerichtet ist\n"
   "- Zwei-Faktor-Anmeldung per Authenticator-App; nach mehreren Fehlversuchen wird die Anmeldung vorübergehend gesperrt\n"
   "- API-Schlüssel werden nur als Fingerabdruck gespeichert; Webhooks an Adressen im privaten Netz sind gesperrt\n")
io.open(p, 'w', encoding='utf-8', newline='\n').write(s)
print('ok')
