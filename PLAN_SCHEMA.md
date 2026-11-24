# plan.json – Schema v1 (für die Garmin-App „Trainingsplan“)

Erzeuge bei jeder Wochenplanung **genau eine** JSON-Datei nach diesem Schema. Nur gültiges JSON, UTF-8, keine Kommentare.

## Felder

| Feld | Typ | Pflicht | Werte / Regeln |
|---|---|---|---|
| `schemaVersion` | Zahl | ja | immer `1` |
| `updated` | Text | ja | Erstellzeitpunkt, Ortszeit Wien, `"JJJJ-MM-TTTHH:MM"` |
| `week` | Text | ja | `"KW nn"` (ISO-Kalenderwoche des ersten Tages) |
| `weekType` | Text | ja | `normal` · `plus` · `minimum` · `entlastung` · `reise` · `taper` |
| `weekNote` | Text | nein | ≤ 60 Zeichen, z. B. Block/Phase |
| `days` | Liste | ja | **7–14 Tage**, beginnend Montag, aufsteigend, ohne Lücken |

**Tag** (`days[]`)

| Feld | Typ | Pflicht | Regeln |
|---|---|---|---|
| `date` | Text | ja | `"JJJJ-MM-TT"` |
| `dayType` | Text | ja | ≤ 20 Zeichen, z. B. `"Ruhetag"`, `"Trainingstag"`, `"Q-Rad-Tag"` |
| `kcal` | Zahl | nein | ganze Zahl |
| `protein` | Zahl | nein | Gramm, ganze Zahl |
| `sessions` | Liste | ja | Einheiten des Tages; **Ruhetag = `[]`** |

**Einheit** (`sessions[]`)

| Feld | Typ | Pflicht | Regeln |
|---|---|---|---|
| `sport` | Text | ja | `rad` · `lauf` · `kraft` · `pump` · `padel` · `schwimmen` · `sonstiges` |
| `title` | Text | ja | **≤ 22 Zeichen** |
| `workout` | Text | nein | Code ≤ 12 Zeichen, z. B. `"Zwift 06"`, `"R1"`, `"K2"` |
| `durationMin` | Zahl | ja* | Minuten, ganze Zahl (*fehlt nur, wenn wirklich unbekannt) |
| `target` | Text | nein | Watt/Puls/Pace als Text, ≤ 40 Zeichen |
| `fuel` | Text | nein | Verpflegung, ≤ 90 Zeichen, Teile mit ` · ` trennen |
| `details` | Liste | nein | Anleitung, max. 8 Zeilen à **≤ 35 Zeichen** |
| `optional` | true/false | nein | nur `true` setzen, wenn die Einheit optional ist |

## Regeln
- **Größe: ≤ 6 KB anstreben, maximal 8 KB.** Lieber kurze Details als lange Sätze.
- Keine weiteren Felder erfinden (die App ignoriert sie, sie kosten nur Platz).
- Ganze Zahlen ohne Anführungszeichen (`70`, nicht `"70"`).
- **Sonderzeichen:** erlaubt sind Umlaute, `ß`, `×`, `·`, `°`, `'`, `–`, `—`, `„ “`, `…`, `•`. **Keine Pfeile oder Symbole** wie `→`, `⟷`, `↔`, `≥`, Emojis – die Uhr zeigt sie als Kästchen. Stattdessen `->`, `/`, `>=` schreiben (z. B. „Klimmzug / Dips“).
- Maximal 3 Einheiten pro Tag.
- Vor dem Speichern prüfen: `python validate_plan.py docs/plan.json`.

## Vollständiges Beispiel (eine Woche, ca. 2,7 KB)

```json
{
  "schemaVersion": 1,
  "updated": "2026-11-22T18:30",
  "week": "KW 48",
  "weekType": "normal",
  "weekNote": "Grundlage I – Sweet Spot Stufe 1",
  "days": [
    { "date": "2026-11-23", "dayType": "Trainingstag", "kcal": 2400, "protein": 140,
      "sessions": [
        { "sport": "lauf", "title": "Lauf locker", "durationMin": 30, "target": "Z2 136–149 bpm" },
        { "sport": "kraft", "title": "Kraft 2", "workout": "K2", "durationMin": 50,
          "details": ["Schrägbank KH 3×8–12", "Rudern Kabel 3×10–12", "Bulg. Split Squat 3×8", "Plank 3×45 s"] }
      ] },
    { "date": "2026-11-24", "dayType": "Q-Rad-Tag", "kcal": 2400, "protein": 140,
      "sessions": [
        { "sport": "rad", "title": "Q1 Sweet Spot 2×15", "workout": "Zwift 05", "durationMin": 60,
          "target": "151–162 W (Zwift 158–169 W)",
          "fuel": "KH-Mahlzeit 2–3 h vorher · Iso 50–60 g + Wasser",
          "details": ["10' einfahren, 3×1' Steigerung", "2×15' Sweet Spot, 5' locker", "10' ausfahren", "Kadenz 85–95"] }
      ] },
    { "date": "2026-11-25", "dayType": "Trainingstag", "kcal": 2300, "protein": 140,
      "sessions": [
        { "sport": "lauf", "title": "Lauf Grundlage", "durationMin": 45, "target": "Z2 136–149 bpm",
          "details": ["Letzte 5' leicht steigern"] },
        { "sport": "pump", "title": "Body Pump", "durationMin": 55, "optional": true }
      ] },
    { "date": "2026-11-26", "dayType": "Ruhetag", "kcal": 2200, "protein": 140, "sessions": [] },
    { "date": "2026-11-27", "dayType": "Trainingstag", "kcal": 2400, "protein": 140,
      "sessions": [
        { "sport": "rad", "title": "Rad locker", "workout": "R1", "durationMin": 60,
          "target": "Z2 120–140 W", "fuel": "Wasser, ggf. Iso 30 g" },
        { "sport": "kraft", "title": "Kraft 1", "workout": "K1", "durationMin": 45,
          "details": ["Kniebeuge 3×8", "Rumän. Kreuzheben 3×10", "Klimmzug 3×max"] }
      ] },
    { "date": "2026-11-28", "dayType": "Q-Rad-Tag", "kcal": 2800, "protein": 140,
      "sessions": [
        { "sport": "rad", "title": "Lange Grundlage", "workout": "Zwift 09", "durationMin": 150,
          "target": "Z2 125–145 W",
          "fuel": "60–70 g KH/h · 500–750 ml/h · Frühstück 3 h vorher",
          "details": ["Gleichmäßig, keine Spitzen", "Alle 20' essen/trinken"] }
      ] },
    { "date": "2026-11-29", "dayType": "Trainingstag", "kcal": 2500, "protein": 140,
      "sessions": [
        { "sport": "padel", "title": "Padel", "durationMin": 90 },
        { "sport": "schwimmen", "title": "Technik Schwimmen", "durationMin": 30,
          "target": "locker, Technik", "details": ["4×50 m Abschlag", "4×50 m Kraul ruhig"] }
      ] }
  ]
}
```
