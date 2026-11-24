import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Glance: liest nur die kleine Kurzfassung aus dem Speicher (64-KB-Limit),
// parst nie den ganzen Plan.
(:glance)
class TrainingsplanGlanceView extends WatchUi.GlanceView {

    function initialize() {
        GlanceView.initialize();
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        var w = dc.getWidth();
        var h = dc.getHeight();
        var font = Graphics.FONT_GLANCE;
        var lh = dc.getFontHeight(font);

        // Zeilen: [text, textfarbe, punktfarbe oder -1]
        var lines = [];
        var g = Application.Storage.getValue("glance");
        var data = null;
        if (g instanceof Dictionary) {
            data = g[TP.todayKey().toString()];
        }

        if (!(data instanceof Dictionary)) {
            lines.add(["TRAININGSPLAN", 0xAAAAAA, -1]);
            lines.add([(g == null) ? "App öffnen zum Laden" : "Heute nicht im Plan", 0xFFFFFF, -1]);
        } else {
            var s = data["s"] as Array;
            lines.add(["HEUTE", 0xAAAAAA, -1]);
            if (s.size() == 0) {
                lines.add(["Ruhetag", 0xFFFFFF, -1]);
            } else if (s.size() == 1) {
                var e = s[0] as Array;
                lines.add([e[1], 0xFFFFFF, e[0]]);
                if ((e[2] as String).length() > 0) {
                    lines.add([e[2], 0xAAAAAA, -1]);
                }
            } else {
                for (var i = 0; i < s.size(); i++) {
                    var e = s[i] as Array;
                    lines.add([e[3], 0xFFFFFF, e[0]]);
                }
            }
        }

        // Kopfzeile weglassen, wenn der Platz nicht reicht
        if (lines.size() * lh > h && lines.size() > 1) {
            lines = lines.slice(1, null);
        }

        var y = (h - lines.size() * lh) / 2;
        if (y < 0) { y = 0; }
        for (var i = 0; i < lines.size(); i++) {
            if (y + lh > h + lh / 3) { break; }
            var ln = lines[i] as Array;
            var x = 0;
            var dot = ln[2] as Number;
            if (dot >= 0) {
                dc.setColor(dot, Graphics.COLOR_TRANSPARENT);
                dc.fillCircle(8, y + lh / 2, 7);
                x = 22;
            }
            dc.setColor(ln[1] as Number, Graphics.COLOR_TRANSPARENT);
            dc.drawText(x, y, font, TP.fitText(dc, ln[0] as String, font, w - x), Graphics.TEXT_JUSTIFY_LEFT);
            y += lh;
        }
    }
}
