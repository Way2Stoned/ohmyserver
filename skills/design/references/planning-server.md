# QD Planning Server — Reference

Start, Proxy, Firewall and Cleanup Commands for `#design plan` / `#design preview` / `#design wireframe`.
Principle: **localhost-first**. UFW Remains Untouched Normally (Active, Open Only 22/80/443).

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

Rules: Bind **Always `127.0.0.1`**, Port from 4100 Up (`ss -tlnp | grep 41` Check), `timeout` Set, Kill Process After Session.

## 2. Make Externally Visible — Without UFW Change (Preferred)

```bash
# A: SSH Tunnel (No Server Change Needed, Default for Remote Operator)
ssh -L 4123:127.0.0.1:4123 <user>@<domain>
# → Operator Opens Locally http://localhost:4123

# B: Temporary Nginx Reverse Proxy via Existing (80/443, No New UFW Rule)
# Snippet (After Security Approval) in Site Config, e.g. /etc/nginx/sites-available/<domain>:
#   location /design-preview/ {
#     proxy_pass http://127.0.0.1:4123/;
#     allow <operator-ip>; deny all;   # IP Restriction Mandatory
#   }
nginx -t && systemctl reload nginx
# After Session: Remove Block + Again nginx -t && reload
```

## 3. Exception: Temporary UFW Rule (Only With Security Approval)

Only If Tunnel/Proxy Provably Don't Suffice (e.g. Mobile Preview Without SSH):

```bash
ufw status numbered > /tmp/qd-ufw-before.txt && ss -tlnp > /tmp/qd-ports-before.txt
# → Current State in /root/.ssa/logs/design.log + Memory (With Expiry, Max 24h)
ufw allow from <operator-ip> to any port 4123 proto tcp comment 'QD-Preview Temp <Date> <Reason>'
# Operation...
ufw delete allow from <operator-ip> to any port 4123 proto tcp
ufw status numbered && ss -tlnp   # Verify Against Current State
```

Every Temp Rule Needs: Reason, Operator IP, Expiry, Log Entry, Memory Entry — and a **Verified Rollback**.

## 4. OSS Bases: When What

- **Own Static Planning Page** (Default): Question Panel + Wireframe/Hi-Fi Toggle + Breakpoint Switcher + Approve Button. Suffices for 90% of Alignments.
- **Excalidraw-Embed** (`@excalidraw/excalidraw`, MIT, npm): When Operator Wants to **Sketch Themselves**. Embed in Planning Page (CDN or `npm i @excalidraw/excalidraw`), Export as `.excalidraw`-JSON + PNG/SVG to `/root/.ssa/design/renders/`.
- **Penpot Self-Hosted** (Only Full Design System): Docker + Compose (Backend, Frontend, Exporter, Postgres, Valkey), Listens on `localhost:9001`, Behind Nginx Proxy + HTTPS. On This Server **Not Installed** — Install Only via `ohmyserver-maintenance` + Operator Approval + Security Review (Ports, Volumes, Backups, Updates). Docs: help.penpot.app/technical-guide (Docker), MCP Server for AI Workflows.

## 5. Cleanup Checklist (Mandatory After Every Session)

- [ ] Preview Process Stopped (`pkill -f "http.server 412"`, Verified via `ss -tlnp`)
- [ ] Nginx Snippet Removed (If Set) + `nginx -t && reload`
- [ ] Temp UFW Rule Deleted (If Set) + `ufw status` vs Current State
- [ ] `/tmp/qd-preview` Cleared (Artifacts Only in `/root/.ssa/design/renders/` + `.omo/plans/`)
- [ ] Log Closed (`/root/.ssa/logs/design.log`: Opened → Rolled Back + Verified)
- [ ] Memory Resolved (Temp Entry Removed, Decisions + Preferences Kept)
