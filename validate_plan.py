#!/usr/bin/env python3
"""Prüft eine plan.json für die Trainingsplan-App (Forerunner 265), bevor sie hochgeladen wird.

Aufruf:  python validate_plan.py [pfad/zur/plan.json ...]   (Standard: docs/plan.json)
Exit-Code 0 = in Ordnung (Warnungen möglich), 1 = Fehler.
"""
import datetime as dt
import json
import re
import sys
from pathlib import Path

MAX_BYTES = 8 * 1024     # hartes Limit (Hintergrundprozess der Uhr: 64 KB)
WARN_BYTES = 6 * 1024    # Zielgröße
SCHEMA_VERSION = 1
WEEK_TYPES = {"normal", "plus", "minimum", "entlastung", "reise", "taper"}
SPORTS = {"rad", "lauf", "kraft", "pump", "padel", "schwimmen", "sonstiges"}
TOP_FIELDS = {"schemaVersion", "updated", "week", "weekType", "weekNote", "days"}
DAY_FIELDS = {"date", "dayType", "kcal", "protein", "sessions"}
SESSION_FIELDS = {"sport", "title", "workout", "durationMin", "target", "fuel", "details", "optional"}
# Zeichen, die die Uhr-Schrift sicher kann: Latin-1 plus einige typografische Zeichen.
# Pfeile (→ ⟷), Emojis usw. erscheinen auf der Uhr als Kästchen.
EXTRA_CHARS = set("–—‘’‚“”„•…′€")
MAX_TITLE = 22
MAX_DETAIL = 35
MAX_TEXT = 90


class Report:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def err(self, where, msg):
        self.errors.append(f"{where}: {msg}")

    def warn(self, where, msg):
        self.warnings.append(f"{where}: {msg}")


def is_int(v):
    return isinstance(v, int) and not isinstance(v, bool)


def bad_chars(text):
    return sorted({c for c in text
                   if not (" " <= c <= "~" or " " <= c <= "ÿ" or c in EXTRA_CHARS)})


def check_text(r, where, value, required=False, max_len=MAX_TEXT):
    if value is None:
        if required:
            r.err(where, "fehlt")
        return
    if not isinstance(value, str) or not value.strip():
        r.err(where, "muss ein nicht-leerer Text sein")
        return
    bad = bad_chars(value)
    if bad:
        shown = ", ".join(f"'{c}' (U+{ord(c):04X})" for c in bad)
        r.err(where, f"Zeichen {shown} kann die Uhr nicht anzeigen (Kästchen) – z. B. '/' oder '->' verwenden")
    if len(value) > max_len:
        r.warn(where, f"{len(value)} Zeichen – auf der Uhr besser ≤ {max_len}")


def check_unknown(r, where, obj, allowed):
    for key in obj:
        if key not in allowed:
            r.warn(where, f"unbekanntes Feld '{key}' (wird von der App ignoriert)")


def parse_date(r, where, value):
    if not isinstance(value, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}", value):
        r.err(where, f"Datum '{value}' muss JJJJ-MM-TT sein")
        return None
    try:
        return dt.date.fromisoformat(value)
    except ValueError:
        r.err(where, f"Datum '{value}' gibt es nicht")
        return None


def check_session(r, where, s):
    if not isinstance(s, dict):
        r.err(where, "Einheit muss ein Objekt sein")
        return
    check_unknown(r, where, s, SESSION_FIELDS)
    sport = s.get("sport")
    if sport not in SPORTS:
        r.err(f"{where}.sport", f"'{sport}' ist nicht erlaubt ({', '.join(sorted(SPORTS))})")
    check_text(r, f"{where}.title", s.get("title"), required=True, max_len=MAX_TITLE)
    check_text(r, f"{where}.workout", s.get("workout"), max_len=12)
    dur = s.get("durationMin")
    if dur is None:
        r.warn(f"{where}.durationMin", "fehlt (Dauer wird nicht angezeigt)")
    elif not is_int(dur) or dur <= 0:
        r.err(f"{where}.durationMin", "muss eine ganze Zahl > 0 sein")
    elif dur > 600:
        r.warn(f"{where}.durationMin", f"{dur} min wirkt unplausibel")
    check_text(r, f"{where}.target", s.get("target"), max_len=40)
    check_text(r, f"{where}.fuel", s.get("fuel"))
    details = s.get("details")
    if details is not None:
        if not isinstance(details, list):
            r.err(f"{where}.details", "muss eine Liste von Texten sein")
        else:
            if len(details) > 8:
                r.warn(f"{where}.details", f"{len(details)} Zeilen – auf der Uhr besser ≤ 8")
            for j, line in enumerate(details):
                check_text(r, f"{where}.details[{j}]", line, required=True, max_len=MAX_DETAIL)
    opt = s.get("optional")
    if opt is not None and not isinstance(opt, bool):
        r.err(f"{where}.optional", "muss true oder false sein")


def check_plan(plan, r):
    if not isinstance(plan, dict):
        r.err("plan", "oberste Ebene muss ein Objekt sein")
        return []
    check_unknown(r, "plan", plan, TOP_FIELDS)

    sv = plan.get("schemaVersion")
    if not is_int(sv):
        r.err("schemaVersion", "fehlt oder ist keine Zahl")
    elif sv != SCHEMA_VERSION:
        r.err("schemaVersion", f"muss {SCHEMA_VERSION} sein (App kennt nur diese Version)")

    updated = plan.get("updated")
    upd = None
    if not isinstance(updated, str) or not re.fullmatch(r"\d{4}-\d{2}-\d{2}T\d{2}:\d{2}", updated):
        r.err("updated", f"'{updated}' muss JJJJ-MM-TTTHH:MM sein (z. B. 2026-12-06T18:30)")
    else:
        try:
            upd = dt.datetime.fromisoformat(updated)
        except ValueError:
            r.err("updated", f"'{updated}' ist kein gültiger Zeitpunkt")

    check_text(r, "week", plan.get("week"), required=True, max_len=12)
    wt = plan.get("weekType")
    if wt not in WEEK_TYPES:
        r.err("weekType", f"'{wt}' ist nicht erlaubt ({', '.join(sorted(WEEK_TYPES))})")
    check_text(r, "weekNote", plan.get("weekNote"), max_len=60)

    days = plan.get("days")
    if not isinstance(days, list):
        r.err("days", "fehlt oder ist keine Liste")
        return []
    if not 7 <= len(days) <= 14:
        r.err("days", f"{len(days)} Tage – erlaubt sind 7 bis 14")

    dates = []
    for i, d in enumerate(days):
        where = f"days[{i}]"
        if not isinstance(d, dict):
            r.err(where, "Tag muss ein Objekt sein")
            continue
        check_unknown(r, where, d, DAY_FIELDS)
        date = parse_date(r, f"{where}.date", d.get("date"))
        if date:
            where = f"{where} ({date:%d.%m.})"
            dates.append(date)
        check_text(r, f"{where}.dayType", d.get("dayType"), required=True, max_len=20)
        for key, lo, hi in (("kcal", 1000, 5000), ("protein", 50, 300)):
            v = d.get(key)
            if v is None:
                continue
            if not is_int(v) or v <= 0:
                r.err(f"{where}.{key}", "muss eine ganze Zahl > 0 sein")
            elif not lo <= v <= hi:
                r.warn(f"{where}.{key}", f"{v} wirkt unplausibel")
        sessions = d.get("sessions")
        if not isinstance(sessions, list):
            r.err(f"{where}.sessions", "fehlt oder ist keine Liste (Ruhetag = [])")
            continue
        if len(sessions) > 3:
            r.warn(f"{where}.sessions", f"{len(sessions)} Einheiten – Glance zeigt nur 2–3")
        for j, s in enumerate(sessions):
            check_session(r, f"{where}.sessions[{j}]", s)

    # Datumslogik
    for a, b in zip(dates, dates[1:]):
        if b <= a:
            r.err("days", f"Daten nicht aufsteigend oder doppelt: {a:%d.%m.} → {b:%d.%m.}")
        elif (b - a).days > 1:
            r.warn("days", f"Lücke zwischen {a:%d.%m.} und {b:%d.%m.}")
    if dates:
        first, last = dates[0], dates[-1]
        if first.weekday() != 0:
            r.warn("days", f"erster Tag {first:%d.%m.} ist kein Montag")
        kw = first.isocalendar()[1]
        week = plan.get("week")
        if isinstance(week, str):
            m = re.search(r"\d+", week)
            if m and int(m.group()) != kw:
                r.warn("week", f"'{week}' passt nicht zur ISO-KW {kw} des ersten Tages")
        if upd and upd.date() > last:
            r.warn("updated", "liegt nach dem letzten Plantag")
        today = dt.date.today()
        if last < today:
            r.warn("days", "alle Tage liegen in der Vergangenheit")
    return dates


def summary(plan):
    lines = []
    for d in plan.get("days", []):
        if not isinstance(d, dict):
            continue
        parts = []
        for s in d.get("sessions") or []:
            if isinstance(s, dict):
                label = s.get("workout") or s.get("title") or "?"
                dur = s.get("durationMin")
                txt = f"{label} {dur}′" if dur else label
                parts.append(f"({txt})" if s.get("optional") else txt)
        try:
            day = dt.date.fromisoformat(d.get("date", ""))
            head = f"{'MoDiMiDoFrSaSo'[day.weekday()*2:day.weekday()*2+2]} {day:%d.%m.}"
        except (ValueError, TypeError):
            head = str(d.get("date"))
        lines.append(f"  {head}  {d.get('dayType', ''):<14} {' · '.join(parts) or '–'}")
    return "\n".join(lines)


def validate(path):
    r = Report()
    p = Path(path)
    print(f"== {p}")
    try:
        raw = p.read_bytes()
    except OSError as e:
        print(f"FEHLER: Datei nicht lesbar: {e}")
        return False
    size = len(raw)
    if size > MAX_BYTES:
        r.err("Größe", f"{size} Bytes > {MAX_BYTES} (hartes Limit) – Details/Texte kürzen")
    elif size > WARN_BYTES:
        r.warn("Größe", f"{size} Bytes > {WARN_BYTES} (Zielgröße)")
    try:
        text = raw.decode("utf-8")
    except UnicodeDecodeError:
        print("FEHLER: Datei ist nicht UTF-8")
        return False
    if text.startswith("﻿"):
        r.err("Datei", "beginnt mit BOM – als UTF-8 ohne BOM speichern")
        text = text[1:]
    try:
        plan = json.loads(text)
    except json.JSONDecodeError as e:
        print(f"FEHLER: kein gültiges JSON (Zeile {e.lineno}, Spalte {e.colno}): {e.msg}")
        return False

    check_plan(plan, r)
    print(f"Größe: {size} Bytes")
    if isinstance(plan, dict):
        print(f"{plan.get('week', '?')} · {plan.get('weekType', '?')} · {plan.get('weekNote', '')}")
        print(summary(plan))
    for w in r.warnings:
        print(f"WARNUNG  {w}")
    for e in r.errors:
        print(f"FEHLER   {e}")
    ok = not r.errors
    print("OK" if ok else f"{len(r.errors)} Fehler")
    return ok


def main(argv):
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    paths = argv[1:] or ["docs/plan.json"]
    results = [validate(p) for p in paths]
    return 0 if all(results) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
