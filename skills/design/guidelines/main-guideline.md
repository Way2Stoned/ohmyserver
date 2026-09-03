# Main Design Guideline — talbergh.art

**Wahrheitsquelle** für ALLE Design-Ausgaben auf **talbergh.art** (Web, PDF, Bilder, Text, Bot-Messages).
Dies ist die **zentrale Guideline**. Projektabhängige Guidelines ergänzen, überschreiben aber nie die Grundprinzipien hier.

> Überarbeitet: 2026-09-03
> Werkzeuge: QD (Optics & Design Skill)

## 0. Philosophie

Design hier ist **Zweck-getrieben**, nicht Deko. Jede Entscheidung beantwortet: "Macht das den Inhalt klarer, schneller lesbar oder angenehmer?" Wenn nein → weglassen. **Kein AI-Slop.**

## 1. Grundprinzipien (gelten ÜBERALL)

| Prinzip | Bedeutung |
|---------|-----------|
| **Zweck zuerst** | Form folgt Funktion. Inhalt dominiert, Deko folgt. |
| **Ein Fokus pro Fläche** | Eine primäre Aktion / ein Hauptblickfang pro Ansicht. |
| **Weniger ist mehr** | Leere ist Kraft. Nicht jede Fläche füllen. |
| **Konsistenz** | Gleiche Elemente → gleiche Form über das GANZE System. |
| **Hierarchie** | Klare Lesereihenfolge: Titel → Untertitel → Inhalt → Aktion. |
| **Barrierefreiheit** | Farbkontrast, lesbare Schrift, keine Info NUR per Farbe. |

## 2. Farbe & Kontrast

### Primär-Farbpalette
| Rolle | Wert | Einsatz |
|-------|------|---------|
| Primär/Accent | `#2563EB` (blau) | Aktionen, Links, Fokus |
| Dunkel (Text) | `#0F172A` | Haupttext, Köpfe |
| Grau (Sekundär) | `#64748B` | Nebentext, Labels |
| Hintergrund | `#FFFFFF` / `#F8FAFC` | Seiten/Hintergrund |
| Erfolg | `#16A34A` | grün, Erfolg |
| Warnung | `#D97706` | gelb/orange |
| Fehler | `#DC2626` | rot, Fehler |

### Kontrast-Regeln (WCAG)
- **Text auf hell**: Dunkel `#0F172A` auf weiß → Kontrastverhältnis ≥ 7:1 (AA+)
- **Normaltext**: ≥ 4.5:1 gegen Hintergrund
- **Großer Text** (≥18pt / ≥14pt fett): ≥ 3:1
- **UI-Bedienelemente** (Buttons, Icons): ≥ 3:1
- **Nie** Informationen ausschließlich durch Farbe vermitteln (z.B. nur rot = Fehler — immer + Symbol/Text)

## 3. Typografie

| Ebene | Größe | Gewicht | Zeilenhöhe |
|-------|-------|---------|-----------|
| Display (Hero) | 40-48px | 700 | 1.1 |
| H1 | 32px | 700 | 1.2 |
| H2 | 24px | 600 | 1.3 |
| H3 | 20px | 600 | 1.4 |
| Body | 16px | 400 | 1.6 |
| Small/Label | 14px (12-14) | 500 | 1.5 |

- **Schriften**: System-Stack bevorzugt (`system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, sans-serif`). Monospace nur für Code/Logs.
- **Zeilenlänge**: 45-75 Zeichen pro Zeile (flüssig lesbar)
- **Keine** mehr als 2-3 Font-Gewichte pro Ansicht unnötig wechseln.

## 4. Abstände & Grid (4/8pt-System)

- **Basiseinheit**: 4px (Mini-Margen) und 8px (Standard-Raster)
- **Abstands-Skala**: 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64
- **Seiten-Rahmen**: 16-24px mobil, 24-32px Desktop-Kanten, Inhalt max ~1200px zentriert
- **Grid**: 12-Spalten-Desktop, 4-Spalten-Mobil (Fluid, nicht fest)
- **Gutter** (Spaltenabstand): 16-24px

## 5. Layout & Responsive (Autoscale/Autolayout)

- **Fluid, nie fix**: `%`/`fr`/`clamp()` statt fester Pixel für Container-Breiten
- **Breakpoints** (mindestens):
  - Mobil: 0-640px (1 Spalte, Stapel)
  - Tablet: 641-1024px (2-3 Spalten)
  - Desktop: 1025+ (volle 12-Spalten)
- **Fluid-Typo**: `clamp(min, vw-basiert, max)` für Überschriften
- **Autolayout**: Flexbox/Grid die "von selbst wachsen" — keine hartkodierten Overrides pro Option
- **Touch-Targets**: mind. 44×44px auf Mobile

## 6. Bilder & Grafiken

- **Format**: PNG (Transparenz), JPEG (Foto), SVG (Farbflächen/Icons/Diagramme), WebP (Web-Performance)
- **Auflösung**: 2x (Retina) für Rasterbilder
- **Dateigröße**: < 200KB pro Bild wann immer möglich (komprimieren)
- **Icons**: Linien-Icons (1.5-2px Strich, abgerundete Enden), einheitlicher Stil
- **Kein** Clipart-Feeling, kein unnötiger Schatten/Farbverlauf
- **Alt-Text** Pflicht bei Web-Bildern

## 7. Komponenten (einheitlich)

| Komponente | Stil |
|-----------|------|
| **Button Primär** | Gefüllt `#2563EB`, weißer Text, Radius 8px, Hover dunkler |
| **Button Sekundär** | Outline 1px `#CBD5E1`, Text dunkel, Radius 8px |
| **Karte** | Hintergrund weiß, Border 1px `#E2E8F0`, Radius 12px, sanfter Schatten |
| **Input** | Border 1px `#CBD5E1`, Radius 8px, Fokus-Ring blau |
| **Badge/Tag** | Radius full, kleine Schrift 12px, gefüllter Hintergrund |
| **Divider** | 1px `#E2E8F0` |

## 8. Text-Formatierungen (Markdown/Bot)

- **Überschriften**: `#` hierarchisch, nie springen (H2←→H4 ohne H3)
- **Fett** nur für Schlüsselbegriffe, **nicht** ganze Sätze
- Listen: Aufzählung für Gruppen, nummeriert für Schritte/Reihenfolge
- **Code**: Inline `` ` `` kurz, fenced Blocks für mehrzeilig
- **Bot-Messages**: kompakt, Emoji sparsam (nur zur Struktur: ✅⚠️🚨), links klar benannt, kein unnötiges Bold
- **Kein** AI-Slop im Text: keine "Great question!", keine Füllsätze

## 9. Marke & Stimme
- **Ton**: sachlich, direkt, kompetent. Deutsch (Server-Sprache) oder wie Projekt-Guideline.
- **Zweck** über Form: jede Ausgabe dient einer klaren Funktion.

## 10. PDF-Spezifisch
- **Seitenränder**: 2cm links/rechts, 2.5cm oben/unten (oder Projekt-spezifisch)
- **Schrift**: Serifenlos lesbar ≥10pt Body, ≥14pt H1
- **Seitenzahlen** unten mittig (ab Seite 2), Header mit Marke
- **Kontrast**: minimierte Farbnutzung für Druck (schwarz/gray dominant)
- **Keine** Bilder die beim Druck verschwinden (Auflösung ≥ 150dpi)

---

## Projektabhängige Guidelines
Jedes Projekt kann eine eigene Guideline haben: `/root/.ssa/design/project-guidelines/<projekt>.md`
Diese ergänzen die Main-Guideline (Marke, spezifische Paletten, Logik), ohne die Grundprinzipien zu verletzen.

## Änderungs-Historie
- 2026-09-03: Initiale Main-Guideline erstellt
