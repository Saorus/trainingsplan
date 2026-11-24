import Toybox.Graphics;
import Toybox.Lang;

// Formatierung und Datumsrechnung (Haupt-App und Hintergrundprozess, nicht Glance)
(:background)
module Fmt {

    const WEEKDAYS = ["Mo", "Di", "Mi", "Do", "Fr", "Sa", "So"];

    // String-Feld aus Dictionary, leere Strings zählen als fehlend
    function str(d, key as String) as String or Null {
        if (!(d instanceof Dictionary)) { return null; }
        var v = d[key];
        if (v instanceof String && v.length() > 0) { return v; }
        return null;
    }

    // Zahl-Feld aus Dictionary (Float wird gerundet)
    function num(d, key as String) as Number or Null {
        if (!(d instanceof Dictionary)) { return null; }
        var v = d[key];
        if (v instanceof Number) { return v; }
        if (v instanceof Float || v instanceof Double || v instanceof Long) { return v.toNumber(); }
        return null;
    }

    // JJJJMMTT -> Tage seit 1970-01-01 (ohne Zeitzonen-Effekte)
    function dayNum(key as Number) as Number {
        var y = key / 10000;
        var m = (key / 100) % 100;
        var d = key % 100;
        if (m <= 2) { y -= 1; }
        var era = y / 400;
        var yoe = y - era * 400;
        var mp = (m + 9) % 12;
        var doy = (153 * mp + 2) / 5 + d - 1;
        var doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
        return era * 146097 + doe - 719468;
    }

    // Tage seit 1970-01-01 -> JJJJMMTT
    function keyFromDayNum(z as Number) as Number {
        z += 719468;
        var era = z / 146097;
        var doe = z - era * 146097;
        var yoe = (doe - doe / 1460 + doe / 36524 - doe / 146096) / 365;
        var y = yoe + era * 400;
        var doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
        var mp = (5 * doy + 2) / 153;
        var d = doy - (153 * mp + 2) / 5 + 1;
        var m = (mp < 10) ? mp + 3 : mp - 9;
        if (m <= 2) { y += 1; }
        return y * 10000 + m * 100 + d;
    }

    // 0 = Montag ... 6 = Sonntag
    function weekdayIndex(key as Number) as Number {
        return (dayNum(key) + 3) % 7;
    }

    function weekdayShort(key as Number) as String {
        return WEEKDAYS[weekdayIndex(key)];
    }

    // JJJJMMTT -> "TT.MM."
    function date(key as Number) as String {
        var m = (key / 100) % 100;
        var d = key % 100;
        return d.format("%02d") + "." + m.format("%02d") + ".";
    }

    // Minuten -> "70 min" bzw. "2:30 h"
    function duration(min) as String or Null {
        if (min == null || min <= 0) { return null; }
        if (min >= 120) {
            return (min / 60).toString() + ":" + (min % 60).format("%02d") + " h";
        }
        return min.toString() + " min";
    }

    // Nicht-leere Teile mit Trenner verbinden
    function join(parts as Array, sep as String) as String or Null {
        var out = null;
        for (var i = 0; i < parts.size(); i++) {
            var p = parts[i];
            if (p instanceof String && p.length() > 0) {
                out = (out == null) ? p : out + sep + p;
            }
        }
        return out;
    }

    // Text in Zeilen umbrechen, die höchstens maxW Pixel breit sind
    function wrap(dc as Graphics.Dc, text as String, font, maxW as Number) as Array<String> {
        var out = [] as Array<String>;
        var rest = text;
        var line = "";
        while (rest.length() > 0) {
            var sp = rest.find(" ");
            var word;
            if (sp == null) {
                word = rest;
                rest = "";
            } else {
                word = rest.substring(0, sp) as String;
                rest = rest.substring(sp + 1, rest.length()) as String;
            }
            if (word.length() == 0) { continue; }
            var cand = (line.length() == 0) ? word : line + " " + word;
            if (dc.getTextWidthInPixels(cand, font) <= maxW) {
                line = cand;
            } else {
                if (line.length() > 0) { out.add(line); }
                // Überlange Wörter hart trennen
                while (word.length() > 1 && dc.getTextWidthInPixels(word, font) > maxW) {
                    var n = word.length() - 1;
                    while (n > 1 && dc.getTextWidthInPixels(word.substring(0, n) as String, font) > maxW) {
                        n -= 1;
                    }
                    out.add(word.substring(0, n) as String);
                    word = word.substring(n, word.length()) as String;
                }
                line = word;
            }
        }
        if (line.length() > 0) { out.add(line); }
        return out;
    }
}
