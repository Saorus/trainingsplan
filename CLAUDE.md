# Trainingsplan – Arbeitsanweisungen für Claude

Dieses Repo enthält die Connect-IQ-App „Trainingsplan“ (Forerunner 265) **und** den aktuellen Wochenplan.
Die Uhr lädt `docs/plan.json` über GitHub Pages. **Das Repo ist öffentlich** – alles hier ist für jeden lesbar.

## Wochenplanung (Hauptaufgabe)

Wenn ich eine neue Woche planen will:

1. Plan gemeinsam mit mir besprechen (Kontext unten, letzte Woche in `docs/plan.json` bzw. `plans/`).
2. `docs/plan.json` neu schreiben – exakt nach `PLAN_SCHEMA.md`.
3. Prüfen: `python validate_plan.py docs/plan.json`.
4. Mir eine kurze Übersicht zeigen (Tag · Einheiten · Dauer) und auf mein OK warten.
5. Nach OK: Kopie als `plans/JJJJ-KWnn.json` ablegen, dann
   `git add docs/plan.json plans/` → `git commit -m "Plan KW nn"` → `git push`.
6. Melden: gepusht; die Uhr holt den Plan beim nächsten Öffnen der App (GitHub Pages braucht ca. 1–10 Minuten).

Nie ohne mein OK pushen. Nie App-Code ändern, wenn ich nur einen Plan will.

## Schema plan.json

Verbindlich ist **`PLAN_SCHEMA.md`** (Felder, erlaubte Werte, Längen, Größe ≤ 6 KB / max. 8 KB, Beispiel).
Prüfen mit `python validate_plan.py docs/plan.json` – bei FEHLER nicht pushen, WARNUNGEN mir nennen.

## Trainingskontext

<!-- Hier die Projektanweisungen aus dem claude.ai-Projekt einfügen:
     Ziele (Neusiedler See Radmarathon 04/2027, Ironman 70.3), FTP, Pulszonen, Workout-Katalog
     (Zwift-Nummern, R1…, K1/K2 mit Übungen), Wochentypen, Ernährungsregeln, feste Termine. -->

_Noch nicht befüllt._

## Technik (nur bei App-Änderungen relevant)

- Build: `monkeyc -d fr265 -f monkey.jungle -o bin/Trainingsplan.prg -y <developer_key>` (SDK 9.3.0)
- Developer Key liegt **nicht** im Repo.
- Siehe `README.md` für Setup, Simulator und Bedienung.
