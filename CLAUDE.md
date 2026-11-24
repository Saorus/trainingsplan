# Trainingsplan – Arbeitsanweisungen für Claude

Dieses Repo enthält die Connect-IQ-App „Trainingsplan“ (Forerunner 265) **und** den aktuellen Wochenplan.
Die Uhr lädt `docs/plan.json` über GitHub Pages. **Das Repo ist öffentlich** – alles hier ist für jeden lesbar.

## Wochenplanung (Hauptaufgabe)

Wenn ich eine neue Woche planen will:

1. Plan gemeinsam mit mir besprechen (Kontext unten, letzte Woche in `docs/plan.json` bzw. `plans/`).
2. `docs/plan.json` neu schreiben – exakt nach dem Schema unten (ab Schritt 4: `PLAN_SCHEMA.md`).
3. Prüfen: `python validate_plan.py docs/plan.json` (sobald vorhanden). Ohne Python mindestens: gültiges JSON, Größe ≤ 6 KB.
4. Mir eine kurze Übersicht zeigen (Tag · Einheiten · Dauer) und auf mein OK warten.
5. Nach OK: Kopie als `plans/JJJJ-KWnn.json` ablegen, dann
   `git add docs/plan.json plans/` → `git commit -m "Plan KW nn"` → `git push`.
6. Melden: gepusht; die Uhr holt den Plan beim nächsten Öffnen der App (GitHub Pages braucht ca. 1–10 Minuten).

Nie ohne mein OK pushen. Nie App-Code ändern, wenn ich nur einen Plan will.

## Schema plan.json (Kurzfassung, schemaVersion 1)

- Oben: `schemaVersion` (1), `updated` ("JJJJ-MM-TTTHH:MM", Ortszeit Wien), `week` ("KW 49"),
  `weekType` (normal | plus | minimum | entlastung | reise | taper), `weekNote` (optional, kurz)
- `days[]`: 7–14 Tage, aufsteigend, je `date` ("JJJJ-MM-TT"), `dayType` (z. B. "Ruhetag", "Q-Rad-Tag"),
  optional `kcal`, `protein` (g), `sessions[]` (leer = frei)
- `sessions[]`: `sport` (rad | lauf | kraft | pump | padel | schwimmen | sonstiges), `title`,
  optional `workout` ("Zwift 06", "R1", "K2"), `durationMin` (Zahl), `target` (Watt/Puls als Text),
  `fuel` (Verpflegung), `details[]` (kurze Zeilen = Anleitung), `optional` (true = optionale Einheit)
- Kurze Texte (Uhr hat ein rundes 416-px-Display): Titel ≤ 22 Zeichen, Detailzeilen ≤ 35 Zeichen.
- Größe: Ziel ≤ 6 KB, hart ≤ 8 KB. Vollständiges Beispiel: `example-plan.json`.

## Trainingskontext

<!-- Hier die Projektanweisungen aus dem claude.ai-Projekt einfügen:
     Ziele (Neusiedler See Radmarathon 04/2027, Ironman 70.3), FTP, Pulszonen, Workout-Katalog
     (Zwift-Nummern, R1…, K1/K2 mit Übungen), Wochentypen, Ernährungsregeln, feste Termine. -->

_Noch nicht befüllt._

## Technik (nur bei App-Änderungen relevant)

- Build: `monkeyc -d fr265 -f monkey.jungle -o bin/Trainingsplan.prg -y <developer_key>` (SDK 9.3.0)
- Developer Key liegt **nicht** im Repo.
- Siehe `README.md` für Setup, Simulator und Bedienung.
