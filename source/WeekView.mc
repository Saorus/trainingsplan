import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Wochenübersicht: laufende Kalenderwoche Mo–So, Kurzlabel je Tag, heute markiert,
// darüber Wochentyp und Notiz.
class WeekView extends ScrollView {

    var model;

    function initialize(m) {
        ScrollView.initialize();
        model = m;
    }

    function buildLayout(dc as Graphics.Dc) as Void {
        var p = model.plan;
        var today = model.todayKey;
        var todayNum = Fmt.dayNum(today);
        var monday = todayNum - Fmt.weekdayIndex(today);

        addText(dc, Fmt.date(Fmt.keyFromDayNum(monday)) + "–" + Fmt.date(Fmt.keyFromDayNum(monday + 6)),
                Graphics.FONT_XTINY, C_GRAY);
        var week = Fmt.str(p, "week");
        addText(dc, (week != null) ? week : "Woche", Graphics.FONT_MEDIUM, C_WHITE);
        addText(dc, weekTypeLabel(Fmt.str(p, "weekType")), Graphics.FONT_TINY, C_TODAY);
        addText(dc, Fmt.str(p, "weekNote"), Graphics.FONT_XTINY, C_TEXT2);
        addGap(14);

        for (var n = monday; n < monday + 7; n++) {
            var key = Fmt.keyFromDayNum(n);
            var day = model.dayFor(key);
            var dots = [];
            var label = "–";
            if (day != null) {
                label = dayLabel(day, dots);
            }
            var color = (n < todayNum) ? C_DIM : (n == todayNum) ? C_TODAY : C_WHITE;
            addRow(dc, Fmt.weekdayShort(key), dots, label, color, n == todayNum);
        }

        addGap(14);
        if (p != null) {
            addText(dc, model.standText(), Graphics.FONT_XTINY, C_DIM);
        }
    }

    // "Lauf · K2", "Zwift 05", "Ruhetag"; sammelt die Sportfarben in dots
    hidden function dayLabel(day as Dictionary, dots as Array) as String {
        var ss = day["sessions"];
        var parts = [];
        if (ss instanceof Array) {
            for (var i = 0; i < ss.size(); i++) {
                var s = ss[i];
                if (!(s instanceof Dictionary)) { continue; }
                dots.add(TP.sportColor(s["sport"]));
                var t = Fmt.str(s, "workout");
                if (t == null) { t = Fmt.str(s, "title"); }
                if (t == null) { t = "Training"; }
                if (s["optional"] == true) { t = "(" + t + ")"; }
                parts.add(t);
            }
        }
        if (parts.size() == 0) {
            var dt = Fmt.str(day, "dayType");
            return (dt != null) ? dt : "Ruhetag";
        }
        return Fmt.join(parts, " · ") as String;
    }

    hidden function weekTypeLabel(t as String or Null) as String or Null {
        if (t == null) { return null; }
        if (t.equals("normal")) { return "Normale Woche"; }
        if (t.equals("plus")) { return "Plus-Woche"; }
        if (t.equals("minimum")) { return "Minimum-Woche"; }
        if (t.equals("entlastung")) { return "Entlastungswoche"; }
        if (t.equals("reise")) { return "Reisewoche"; }
        if (t.equals("taper")) { return "Taper"; }
        return t;
    }
}
