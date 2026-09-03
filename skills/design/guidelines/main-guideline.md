# Main Design Guideline — <domain>

**Source of Truth** for ALL Design Outputs on **<domain>** (Web, PDF, Images, Text, Bot Messages).
This is the **Central Guideline**. Project-Dependent Guidelines Extend, But Never Override Core Principles Here.

> Überarbeitet: 2026-09-03
> Werkzeuge: QD (Optics & Design Skill)

## 0. Philosophy

Design Here is **Purpose-Driven**, Not Decoration. Every Decision Answers: "Does This Make Content Clearer, Faster to Read, or More Pleasant?" If No → Omit. **No AI-Slop.**

## 1. Core Principles (Apply EVERYWHERE)

| Principle | Meaning |
|-----------|---------|
| **Purpose First** | Form Follows Function. Content Dominates, Decoration Follows. |
| **One Focus Per Area** | One Primary Action / One Main Focal Point Per View. |
| **Less is More** | Empty Space is Strength. Don't Fill Every Area. |
| **Consistency** | Same Elements → Same Form Across the ENTIRE System. |
| **Hierarchy** | Clear Reading Order: Title → Subtitle → Content → Action. |
| **Accessibility** | Color Contrast, Readable Font, No Info ONLY via Color. |

## 2. Color & Contrast

### Primary Color Palette
| Role | Value | Use |
|------|-------|-----|
| Primary/Accent | `#2563EB` (Blue) | Actions, Links, Focus |
| Dark (Text) | `#0F172A` | Main Text, Headings |
| Gray (Secondary) | `#64748B` | Secondary Text, Labels |
| Background | `#FFFFFF` / `#F8FAFC` | Pages/Background |
| Success | `#16A34A` | Green, Success |
| Warning | `#D97706` | Yellow/Orange |
| Error | `#DC2626` | Red, Error |

### Contrast Rules (WCAG)
- **Text on Light**: Dark `#0F172A` on White → Contrast Ratio ≥ 7:1 (AA+)
- **Normal Text**: ≥ 4.5:1 Against Background
- **Large Text** (≥18pt / ≥14pt Bold): ≥ 3:1
- **UI Elements** (Buttons, Icons): ≥ 3:1
- **Never** Convey Info Solely Through Color (e.g. Only Red = Error — Always + Symbol/Text)

## 3. Typography

| Level | Size | Weight | Line Height |
|-------|------|--------|-------------|
| Display (Hero) | 40-48px | 700 | 1.1 |
| H1 | 32px | 700 | 1.2 |
| H2 | 24px | 600 | 1.3 |
| H3 | 20px | 600 | 1.4 |
| Body | 16px | 400 | 1.6 |
| Small/Label | 14px (12-14) | 500 | 1.5 |

- **Fonts**: System Stack Preferred (`system-ui, -apple-system, Segoe UI, Roboto, Ubuntu, sans-serif`). Monospace Only for Code/Logs.
- **Line Length**: 45-75 Characters Per Line (Fluid Readability)
- **No More Than** 2-3 Font Weights Per View Unnecessarily Switched.

## 4. Spacing & Grid (4/8pt System)

- **Base Unit**: 4px (Mini Margins) and 8px (Standard Grid)
- **Spacing Scale**: 4 · 8 · 12 · 16 · 24 · 32 · 48 · 64
- **Page Margins**: 16-24px Mobile, 24-32px Desktop Edges, Content Max ~1200px Centered
- **Grid**: 12-Column Desktop, 4-Column Mobile (Fluid, Not Fixed)
- **Gutter** (Column Gap): 16-24px

## 5. Layout & Responsive (Autoscale/Autolayout)

- **Fluid, Never Fixed**: `%`/`fr`/`clamp()` Instead of Fixed Pixels for Container Widths
- **Breakpoints** (Minimum):
  - Mobile: 0-640px (1 Column, Stack)
  - Tablet: 641-1024px (2-3 Columns)
  - Desktop: 1025+ (Full 12 Columns)
- **Fluid Typography**: `clamp(min, vw-based, max)` for Headings
- **Autolayout**: Flexbox/Grid That "Grow Themselves" — No Hardcoded Overrides Per Option
- **Touch Targets**: Min 44×44px on Mobile

## 6. Images & Graphics

- **Format**: PNG (Transparency), JPEG (Photo), SVG (Color Areas/Icons/Diagrams), WebP (Web Performance)
- **Resolution**: 2x (Retina) for Raster Images
- **File Size**: < 200KB Per Image Whenever Possible (Compress)
- **Icons**: Line Icons (1.5-2px Stroke, Rounded Ends), Unified Style
- **No** Clipart Feel, No Unnecessary Shadows/Gradients
- **Alt Text** Mandatory for Web Images

## 7. Components (Unified)

| Component | Style |
|-----------|-------|
| **Primary Button** | Filled `#2563EB`, White Text, Radius 8px, Hover Darker |
| **Secondary Button** | Outline 1px `#CBD5E1`, Dark Text, Radius 8px |
| **Card** | White Background, Border 1px `#E2E8F0`, Radius 12px, Soft Shadow |
| **Input** | Border 1px `#CBD5E1`, Radius 8px, Focus Ring Blue |
| **Badge/Tag** | Full Radius, Small Font 12px, Filled Background |
| **Divider** | 1px `#E2E8F0` |

## 8. Text Formatting (Markdown/Bot)

- **Headings**: `#` Hierarchical, Never Jump (H2←→H4 Without H3)
- **Bold** Only for Key Terms, **Not** Whole Sentences
- Lists: Bullet for Groups, Numbered for Steps/Sequence
- **Code**: Inline `` ` `` Short, Fenced Blocks for Multiline
- **Bot Messages**: Compact, Emoji Sparingly (Only Structure: ✅⚠️🚨), Links Clearly Named, No Unnecessary Bold
- **No** AI-Slop in Text: No "Great Question!", No Filler Sentences

## 9. Brand & Voice
- **Tone**: Factual, Direct, Competent. German (Server Language) or As Project Guideline.
- **Purpose** Over Form: Every Output Serves a Clear Function.

## 10. PDF Specific
- **Margins**: 2cm Left/Right, 2.5cm Top/Bottom (Or Project Specific)
- **Font**: Sans-Serif Readable ≥10pt Body, ≥14pt H1
- **Page Numbers** Bottom Center (From Page 2), Header with Brand
- **Contrast**: Minimized Color for Print (Black/Gray Dominant)
- **No** Images That Disappear When Printed (Resolution ≥ 150dpi)

---

## Project-Dependent Guidelines
Each Project Can Have Its Own Guideline: `/root/.ssa/design/project-guidelines/<projekt>.md`
These Extend the Main Guideline (Brand, Specific Palettes, Logic), Without Violating Core Principles.

## Change History
- 2026-09-03: Initial Main Guideline Created
