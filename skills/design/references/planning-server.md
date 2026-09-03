# QD Planning Server — Referenz

Start-, Proxy-, Firewall- und Aufräum-Befehle für `#design plan` / `#design preview` / `#design wireframe`.
Prinzip: **localhost-first**. UFW bleibt im Normalfall unangetastet (active, offen nur 22/80/443).

## 1. Start (localhost, ephemerer Port)

```bash
# Variante A: Python (kein Install nötig)
mkdir -p /tmp/qd-preview && cp -r <entwurf>/ /tmp/qd-preview/
python3 -m http.server 0 --bind 127.0.0.1 --directory /tmp/qd-preview
# Port aus Ausgabe ablesen (z.B. 4100) — timeout setzen, kein Dauer-Dienst:
timeout 3600 python3 -m http.server 4123 --bind 127.0.0.1 --directory /tmp/qd-preview

# Variante B: Node (npx, kein globaler Install)
npx -y serve -l 127.0.0.1:4123 /tmp/qd-preview
```

Regeln: Bind **immer `127.0.0.1`**, Port ab 4100 frei wählen (`ss -tlnp | grep 41` prüfen), `timeout` setzen, Prozess nach Session killen.

## 2. Extern sichtbar machen — ohne UFW-Change (bevorzugt)

```bash
# A: SSH-Tunnel (kein Server-Change nötig, Default für Remote-Operator)
ssh -L 4123:127.0.0.1:4123 talbergh@talbergh.art
# → Operator öffnet lokal http://localhost:4123

# B: Temporärer Nginx-Reverse-Proxy über Bestand (80/443, keine neue UFW-Regel)
# Snippet (nach Security-Freigabe) in Site-Config, z.B. /etc/nginx/sites-available/talbergh.art:
#   location /design-preview/ {
#     proxy_pass http://127.0.0.1:4123/;
#     allow <operator-ip>; deny all;   # IP-Restriktion Pflicht
#   }
nginx -t && systemctl reload nginx
# Nach Session: Block entfernen + erneut nginx -t && reload
```

## 3. Ausnahme: temporäre UFW-Regel (nur mit Security-Freigabe)

Nur wenn Tunnel/Proxy nachweislich nicht reichen (z.B. Handy-Preview ohne SSH):

```bash
ufw status numbered > /tmp/qd-ufw-before.txt && ss -tlnp > /tmp/qd-ports-before.txt
# → IST in /root/.ssa/logs/design.log + Memory (mit Ablaufzeit, max 24h)
ufw allow from <operator-ip> to any port 4123 proto tcp comment 'QD-Preview temp <datum> <grund>'
# Betrieb...
ufw delete allow from <operator-ip> to any port 4123 proto tcp
ufw status numbered && ss -tlnp   # gegen IST prüfen
```

Jede Temp-Regel braucht: Grund, Operator-IP, Ablaufzeit, Log-Eintrag, Memory-Eintrag — und einen **verifizierten Rollback**.

## 4. OSS-Basen: wann was

- **Eigene statische Planning-Page** (Default): Frage-Panel + Wireframe/Hi-Fi-Toggle + Breakpoint-Umschalter + Freigabe-Button. Reicht für 90 % der Abstimmungen.
- **Excalidraw-Embed** (`@excalidraw/excalidraw`, MIT, npm): wenn der Operator **selbst skizzieren** will. Einbettung in Planning-Page (CDN oder `npm i @excalidraw/excalidraw`), Export als `.excalidraw`-JSON + PNG/SVG nach `/root/.ssa/design/renders/`.
- **Penpot self-hosted** (nur Voll-Designsystem): Docker + Compose (Backend, Frontend, Exporter, Postgres, Valkey), lauscht auf `localhost:9001`, dahinter Nginx-Proxy + HTTPS. Auf diesem Server **nicht installiert** — Install nur via `ohmyserver-maintenance` + Operator-Freigabe + Security-Review (Ports, Volumes, Backups, Updates). Doku: help.penpot.app/technical-guide (Docker), MCP-Server für AI-Workflows.

## 5. Aufräum-Checkliste (Pflicht nach jeder Session)

- [ ] Preview-Prozess gestoppt (`pkill -f "http.server 412"`, verifiziert via `ss -tlnp`)
- [ ] Nginx-Snippet entfernt (falls gesetzt) + `nginx -t && reload`
- [ ] Temp-UFW-Regel gelöscht (falls gesetzt) + `ufw status` gegen IST
- [ ] `/tmp/qd-preview` geleert (Artefakte nur in `/root/.ssa/design/renders/` + `.omo/plans/`)
- [ ] Log geschlossen (`/root/.ssa/logs/design.log`: geöffnet → zurückgebaut + verifiziert)
- [ ] Memory aufgelöst (Temp-Eintrag streichen, Entscheidungen + Präferenzen behalten)
