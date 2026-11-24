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
| ZURÜCK | Detailansicht schließen bzw. App beenden |

Tage vor heute werden ausgeblendet. Ist der Plan älter als 7 Tage oder fehlt heute, erscheint ein roter Hinweis.

## 4. Projektstruktur

```
manifest.xml                 App-Typ (watch-app mit Glance), Gerät fr265, Sprache
monkey.jungle                Build-Konfiguration
source/
  TrainingsplanApp.mc        Einstieg, liefert Glance und Tagesansicht
  TrainingsplanGlanceView.mc Glance (liest nur eine kleine Kurzfassung, 64-KB-Limit)
  PlanModel.mc               Plan laden/speichern, Tage filtern, Hinweise
  DayView.mc                 Tagesansicht, Detailansicht, Navigation
  Common.mc                  Farben je Sport, Datum (auch für die Glance)
  Fmt.mc                     Formatierung, Zeilenumbruch, Datumsrechnung
resources/
  jsonData/example-plan.json eingebetteter Beispielplan (MVP)
  settings/                  App-Einstellungen
example-plan.json            Beispielwoche (Kopie, für Validierung/Upload)
```

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
5. Plan-URL in die App eintragen: im Simulator über den App Settings Editor, auf der Uhr über Garmin Connect → Geräte → Forerunner 265 → Connect IQ-Apps → Trainingsplan → Einstellungen (nur bei Installation über den Store/Beta, siehe Schritt 4).

### Jede Woche
- **Am PC:** In der Claude-Desktop-App (Code-Tab) diesen Ordner öffnen und „Plane KW nn“ sagen. Claude schreibt `docs/plan.json`, prüft sie, zeigt die Übersicht und pusht nach deinem OK (siehe `CLAUDE.md`).
- **Am Handy:** <https://claude.ai/code> → Repo `trainingsplan` wählen → gleich wie am PC.
- **Manuell (Notfall):** auf github.com `docs/plan.json` öffnen → Stift → Inhalt ersetzen → „Commit changes“.

## 6. Noch offen (folgt)
- Schritt 4: Wochenübersicht, Menü „Aktualisieren“, Hintergrund-Sync, `PLAN_SCHEMA.md`, `validate_plan.py`, Sideload per USB, Beta-Upload.
