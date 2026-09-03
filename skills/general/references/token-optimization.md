# Token-Optimierungs-Regeln für OhMyServer

## Grundprinzip
Weniger Tokens = Schnellere Antworten = Weniger Kosten

## Regeln

### 1. Antwortlänge
| Fragetyp | Max Tokens | Beispiel |
|----------|------------|----------|
| Ja/Nein | 20 | "Ja, Fail2Ban läuft" |
| Status | 50 | "SSH Port 22, Fail2Ban aktiv, 3 Banned IPs" |
| Erklärung | 150 | Kurze Erklärung + Quelle |
| Komplex | 300 | Strukturierte Antwort mit Steps |

### 2. Vermeiden
- Füllwörter: "also", "eigentlich", "ich glaube"
- Wiederholungen: Sage etwas 1x klar
- Listen >5 Punkte: Aufteilen oder zusammenfassen
- Umschreibungen: Direkt zur Sache

### 3. Struktur
```
[Antwort]
[Quelle falls nötig]
[Rückfrage falls nötig]
```

### 4. Token-Einsparungen
- `systemctl status X` → "Status: [aktiv/inaktiv]"
- `df -h` → "Speicher: X/Y belegt (Z%)"
- `docker ps` → "Container: X laufend, Y gestoppt"
