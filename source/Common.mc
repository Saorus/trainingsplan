import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Time.Gregorian;

// Hilfsfunktionen, die auch in der Glance (64 KB) gebraucht werden.
// Alles hier muss klein bleiben.
(:glance)
module TP {

    // Farbe je Sportart (AMOLED, dunkler Hintergrund)
    function sportColor(sport) as Number {
        if ("rad".equals(sport)) { return 0xFF8800; }
        if ("lauf".equals(sport)) { return 0x33CC33; }
        if ("kraft".equals(sport)) { return 0x3399FF; }
        if ("pump".equals(sport)) { return 0xAA55FF; }
        if ("padel".equals(sport)) { return 0xFFDD00; }
        if ("schwimmen".equals(sport)) { return 0x00CCDD; }
        return 0x999999;
    }

    // Heutiges Datum (Ortszeit der Uhr) als Zahl JJJJMMTT.
    // Zum Testen im Simulator: versteckte Property "debugToday" = "JJJJ-MM-TT".
    function todayKey() as Number {
        try {
            var dbg = dateKey(Application.Properties.getValue("debugToday"));
            if (dbg != null) { return dbg; }
        } catch (e) {
        }
        var info = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        return (info.year as Number) * 10000 + (info.month as Number) * 100 + (info.day as Number);
    }

    // "2026-12-07" (oder "2026-12-07T18:30") -> 20261207, sonst null
    function dateKey(s) as Number or Null {
        if (!(s instanceof String) || s.length() < 10) { return null; }
        var y = (s.substring(0, 4) as String).toNumber();
        var m = (s.substring(5, 7) as String).toNumber();
        var d = (s.substring(8, 10) as String).toNumber();
        if (y == null || m == null || d == null) { return null; }
        if (m < 1 || m > 12 || d < 1 || d > 31) { return null; }
        return y * 10000 + m * 100 + d;
    }

    // Text kürzen, bis er in maxW Pixel passt
    function fitText(dc as Graphics.Dc, text as String, font, maxW as Number) as String {
        if (dc.getTextWidthInPixels(text, font) <= maxW) { return text; }
        var s = text;
        while (s.length() > 1) {
            s = s.substring(0, s.length() - 1) as String;
            var cand = s + "…";
            if (dc.getTextWidthInPixels(cand, font) <= maxW) { return cand; }
        }
        return s;
    }
}
