# Trainingsplan – Connect-IQ-App für die Forerunner 265

Zeigt auf der Uhr, was heute und in den nächsten Tagen geplant ist. Die App zeigt nur an, sie zeichnet nichts auf.

> Stand: Schritt 3. Die App lädt `plan.json` per HTTPS (GitHub Pages). Ohne eingestellte Plan-URL zeigt sie den eingebetteten Beispielplan.

---

## 1. Einmalige Einrichtung unter Windows

### 1.1 Java installieren
Der Monkey-C-Compiler braucht Java.
1. <https://adoptium.net> öffnen und **Temurin 21 (LTS)** für Windows x64 als `.msi` herunterladen.
2. Installieren. Im Installer bei **„Set JAVA_HOME variable“** „Will be installed on local hard drive“ wählen.
3. Prüfen: PowerShell öffnen und `java -version` eingeben. Es sollte eine Version 21 erscheinen.

### 1.2 Visual Studio Code installieren
1. <https://code.visualstudio.com> → „Download for Windows“ → installieren (Standardoptionen reichen).

### 1.3 Connect IQ SDK Manager
1. <https://developer.garmin.com/connect-iq/sdk/> öffnen, Lizenz akzeptieren, **SDK Manager für Windows** herunterladen.
2. ZIP entpacken (z. B. nach `C:\Garmin\sdkmanager`) und `sdk-manager.exe` starten.
3. Mit deinem **Garmin-Konto** anmelden (dasselbe wie für Garmin Connect).
4. Reiter **SDK**: die neueste Version (aktuell **9.3.0**) herunterladen und **„Use as Active SDK“** wählen.
5. Reiter **Devices**: nach **Forerunner 265** suchen und herunterladen.

### 1.4 Monkey-C-Extension in VS Code
1. VS Code öffnen → links das Erweiterungen-Symbol (oder `Strg+Umschalt+X`).
2. Nach **„Monkey C“** suchen (Herausgeber: **Garmin**) → Installieren.
3. `Strg+Umschalt+P` → **„Monkey C: Verify Installation“** ausführen. Es sollte „SDK OK“ o. ä. melden.

### 1.5 Developer Key erzeugen
Jede App wird mit deinem persönlichen Schlüssel signiert. **Gut aufheben** – ohne denselben Schlüssel lassen sich spätere Updates nicht über die alte Version installieren.
1. Ordner anlegen, z. B. `C:\Users\<du>\garmin-key`.
2. `Strg+Umschalt+P` → **„Monkey C: Generate a Developer Key“** → diesen Ordner wählen.
3. Die Datei `developer_key` **nicht** ins GitHub-Repo legen (die `.gitignore` schließt sie aus).

## 2. App im Simulator starten

1. VS Code → **Datei → Ordner öffnen** → diesen Ordner `Trainingsplan` wählen.
2. `Strg+F5` (Ausführen ohne Debugging). Beim ersten Mal **Forerunner 265** als Gerät wählen.
3. Der Simulator öffnet sich und startet die App.

### Tipps im Simulator
- **Einstellungen:** Im Simulator **File → Edit Persistent Storage → Edit Application.Properties data** öffnet den **App Settings Editor** (wie später in Garmin Connect). Wert ändern → **Save** → App neu starten.
- **Datum ändern:** „Time Simulation“ ist für Apps ausgegraut. Stattdessen im App Settings Editor bei **„Testdatum JJJJ-MM-TT“** z. B. `2026-12-01` eintragen, **Save**, App neu starten. Leer = echtes Datum. (Beispielplan: 23.–29.11.2026.) Diese Einstellung wird vor dem Beta-Upload entfernt.
- **Gespeicherten Plan löschen:** **File → Reset All App Data**, danach lädt die App den Beispielplan neu.
- **Tasten:** Pfeiltasten hoch/runter = Tasten der Uhr; Mausziehen = Wischen; Enter = START; Esc/Backspace = ZURÜCK.

## 3. Bedienung

| Aktion | Wirkung |
|---|---|
| Taste hoch / runter | vorheriger / nächster Tag |
| Wischen nach links / rechts | nächster / vorheriger Tag |
| Wischen nach oben / unten | Tagesansicht scrollen |
| START oder Tippen | Detailansicht mit Anleitung und Verpflegung – dort scrollen hoch/runter den Inhalt |
| MENU (Taste hoch lang drücken) | Menü: **Wochenübersicht** · **Aktualisieren** |
| ZURÜCK | Detail-/Wochenansicht schließen bzw. App beenden |

- Tage vor heute werden ausgeblendet. Ist der Plan älter als 7 Tage, fehlt heute oder beginnt er erst später, erscheint ein roter Hinweis.
- **Wochenübersicht:** laufende Kalenderwoche Mo–So mit Wochentyp, Notiz und einem Kurzlabel pro Tag; heute ist gelb markiert, vergangene Tage grau, optionale Einheiten in Klammern.
- **Aktualisieren:** lädt den Plan sofort neu und meldet das Ergebnis kurz.
- **Automatisch:** beim Öffnen der App und im Hintergrund alle 6 Stunden (sofern das Handy verbunden ist).

## 4. Projektstruktur

```
manifest.xml                 App-Typ (watch-app mit Glance), Gerät fr265, Sprache
monkey.jungle                Build-Konfiguration
source/
  TrainingsplanApp.mc        Einstieg: Glance, Tagesansicht, Hintergrund-Registrierung
  TrainingsplanGlanceView.mc Glance (liest nur eine kleine Kurzfassung, 64-KB-Limit)
  PlanModel.mc               Plan im Vordergrund: Tage filtern, Hinweise, Stand
  PlanData.mc                Plan prüfen/speichern, Glance-Daten (auch im Hintergrund)
  PlanSync.mc                Laden beim Öffnen und per Menü „Aktualisieren“
  PlanServiceDelegate.mc     Hintergrund-Sync alle 6 h
  ScrollView.mc              Basis für scrollbare Ansichten (rundes Display)
  DayView.mc                 Tages-/Detailansicht, Menü, Tastensteuerung
  WeekView.mc                Wochenübersicht
  Common.mc                  Farben je Sport, Datum (Glance + Hintergrund)
  Fmt.mc                     Formatierung, Zeilenumbruch, Datumsrechnung
resources/
  jsonData/example-plan.json eingebetteter Beispielplan (wenn keine URL gesetzt)
  settings/                  App-Einstellungen (Plan-URL, kcal/Protein, Testdatum)
docs/plan.json               aktueller Plan – wird über GitHub Pages ausgeliefert
plans/                       Archiv der Wochenpläne
PLAN_SCHEMA.md               Spezifikation für Claude
validate_plan.py             Prüfskript vor dem Upload
example-plan.json            Beispielwoche
CLAUDE.md                    Arbeitsanweisungen für Claude (Wochenplanung)
```

### Plan prüfen
```
python validate_plan.py docs/plan.json
```
Prüft JSON, Pflichtfelder, erlaubte Werte, Textlängen, Datumslogik (aufsteigend, ohne Lücken, Montag, KW) und Größe (Ziel ≤ 6 KB, max. 8 KB). FEHLER = nicht hochladen, WARNUNG = ansehen.

## 5. Hosting und wöchentliches Update

### Wie der Plan auf die Uhr kommt
```
Claude (Planung) ──git push──▶ GitHub-Repo  docs/plan.json
                                   │ GitHub Pages (1–10 min)
                                   ▼
        https://<github-name>.github.io/trainingsplan/plan.json
                                   │ Garmin Connect App (Handy, HTTPS)
                                   ▼
                     Forerunner 265: speichert, zeigt auch offline
```
- GitHub Pages liefert `.json` als `application/json` – das verlangt Garmins `makeWebRequest`. (Ein Gist-Raw-Link liefert `text/plain` und funktioniert deshalb nicht zuverlässig.)
- **Privatsphäre:** Repo und Plan sind öffentlich (kostenloser GitHub-Plan). Keine sensiblen Daten in den Plan schreiben.
- Die App lädt beim Öffnen. Schlägt das fehl (kein Handy, kein Internet, ungültige Datei), bleibt der letzte gültige Plan aktiv und unten steht orange „Sync-Fehler: …“.

### Einmalig einrichten
1. Git und GitHub CLI installieren (`winget install Git.Git` und `winget install GitHub.cli`).
2. In PowerShell `gh auth login` → GitHub.com → HTTPS → „Login with a web browser“ → Code im Browser bestätigen.
3. Repo anlegen und pushen (macht Claude): `gh repo create trainingsplan --public --source . --push`.
4. Pages aktivieren (macht Claude per `gh api`): Branch `main`, Ordner `/docs`.
5. Plan-URL: ist als Standard in der App eingebaut (`https://saorus.github.io/trainingsplan/plan.json`). Ändern nur nötig, wenn sich die Adresse ändert – im Simulator über den App Settings Editor, auf der Uhr über Garmin Connect (nur bei Installation als Beta-App, siehe Abschnitt 7).

### Jede Woche
- **Am PC:** In der Claude-Desktop-App (Code-Tab) diesen Ordner öffnen und „Plane KW nn“ sagen. Claude schreibt `docs/plan.json`, prüft sie, zeigt die Übersicht und pusht nach deinem OK (siehe `CLAUDE.md`).
- **Am Handy:** <https://claude.ai/code> → Repo `trainingsplan` wählen → gleich wie am PC.
- **Manuell (Notfall):** auf github.com `docs/plan.json` öffnen → Stift → Inhalt ersetzen → „Commit changes“.

## 6. Auf die Uhr bringen (USB-Sideload)

1. In VS Code `Strg+Umschalt+P` → **„Monkey C: Build for Device“** → **Forerunner 265** → einen Ausgabeordner wählen (z. B. `bin`). Ergebnis: `Trainingsplan.prg`.
   (Alternativ liegt nach jedem Build von Claude eine aktuelle `bin\Trainingsplan.prg` bereit.)
2. Uhr per USB-Kabel am PC anschließen. Im Explorer erscheint **„Forerunner 265“** (ggf. am Handy/Uhr „Datenübertragung“ bestätigen).
3. Öffnen: **Forerunner 265 → Internal Storage → GARMIN → APPS**.
4. `Trainingsplan.prg` in diesen Ordner kopieren.
5. Uhr vom PC trennen (im Explorer „Auswerfen“). Die Uhr installiert die App beim Trennen.
6. Auf der Uhr: Glance-Loop öffnen (vom Zifferblatt hoch/runter) → ganz unten **Bearbeiten/Hinzufügen** → **Trainingsplan** hinzufügen. Die App ist außerdem über START → Apps/Aktivitäten-Liste bzw. das Apps-Menü erreichbar.
7. Das Handy muss mit der Uhr gekoppelt und Garmin Connect aktiv sein – darüber lädt die App den Plan.

**Update:** neue `Trainingsplan.prg` einfach erneut in `GARMIN\APPS` kopieren (gleicher Developer Key nötig).
**Hinweis:** Bei Sideload sind die App-Einstellungen in Garmin Connect nicht verfügbar – daher ist die Plan-URL als Standard eingebaut.

## 7. Optional: private Beta-App (Einstellungen in Garmin Connect)

Nur nötig, wenn du die Einstellungen (Plan-URL, kcal/Protein ein/aus) am Handy ändern willst.
1. In VS Code: **„Monkey C: Export Project“** → erzeugt eine `.iq`-Datei.
2. <https://apps.garmin.com/developer/upload> öffnen (mit Garmin-Konto anmelden) → `.iq` hochladen → als **Beta-App** markieren. Beta-Apps sind nur für dein eigenes Konto sichtbar.
3. Am Handy in der Garmin Connect App / Connect IQ Store die Beta-App installieren; vorher die per USB installierte Version von der Uhr löschen.
4. Vor dem Upload die Test-Einstellung „Testdatum“ aus `resources/settings/settings.xml` entfernen (Claude erledigt das auf Zuruf).
