# Wireframe-Muster — Referenz

Wie QD-Wireframes aufgebaut sind: Low-Fi zuerst, dann Hi-Fi daneben. Jede Fläche beantwortet: Was ist das, warum ist es da, was passiert bei Klick?

## 1. Aufbau-Regeln

- **12-Spalten Desktop / 4-Spalten Mobil**, Gutter 16–24px, Inhalt max ~1200px zentriert (Main-Guideline).
- **Ein Fokus pro View**: eine H1, eine primäre Aktion. Rest subordiniert.
- **Boxen beschriften**: `[Header]`, `[Hero: H1 + CTA]`, `[Grid 3×Cards]`, `[Footer]` — kein Lorem ohne Funktion.
- **Grid-Overlay** in Preview umschaltbar (zeigt Spalten/Gutter/Breakpoint).
- **Breakpoints**: 0–640 (1 Spalte, Stapel) / 641–1024 (2–3 Spalten) / 1025+ (12 Spalten).

## 2. Low-Fi → Hi-Fi Ablauf

1. **Low-Fi** (Grau-Boxen + Labels, Guideline-Abstände, keine Farben außer Struktur): Struktur freigeben lassen.
2. **Hi-Fi** (Palette `#2563EB`/`#0F172A`/`#64748B`, Typo-Skala, Komponenten aus Guideline): Look freigeben lassen.
3. **Responsive-Check**: alle 3 Breakpoints im Preview durchklicken, Touch-Targets ≥44px mobil.
4. Erst danach in echte Artefakte überführen (HTML/CSS, PDF, Bild).

## 3. Frage-Verknüpfung (Beispiel)

Offene Punkte als klickbare Optionen im Frage-Panel, parallel per `question`-Tool:

- `Hero-Variante?` → [A: Text links + Bild rechts (Empfohlen)] [B: Zentriert] [C: Full-Bleed]
- `CTA?` → [A: 1 primärer Button] [B: primär + sekundär]
- `Karten-Anzahl?` → [3] [4] [6]

Jede Wahl → sofort Preview-Update + Log (Memory + design.log). Freigabe nur explizit.

## 4. Export

- Skizzen aus Excalidraw: `.excalidraw`-JSON (Quelle) + PNG/SVG nach `/root/.ssa/design/renders/<name>-wire.{png,svg}`.
- Hi-Fi-Screenshots/Notizen daneben: `<name>-preview.{png,pdf}` + Entscheidungs-Log im Design-Log.
- Kein Rendern ohne Alt-Text/Name zum Kontext; Raster 2x, Ziel <200KB.
