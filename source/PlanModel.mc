import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Hält den aktiven Plan, filtert vergangene Tage und erzeugt die Glance-Kurzfassung.
class PlanModel {

    var plan = null;        // Dictionary aus plan.json oder null
    var days = [];          // Array von [JJJJMMTT, Tag-Dictionary], sortiert, nur ab heute
    var todayKey = 0;
    var todayIndex = -1;    // Index von heute in days, -1 wenn heute fehlt
    var isExample = false;  // true = eingebetteter Beispielplan (noch keine URL)

    function initialize() {
    }

    // Letzten gültigen Plan aus dem Speicher laden. Gibt es keinen und ist noch
    // keine Plan-URL eingestellt, wird der eingebettete Beispielplan angezeigt.
    function load() as Void {
        isExample = false;
        var p = Application.Storage.getValue("plan");
        if (!isValid(p)) {
            p = null;
            if (PlanSync.planUrl() == null) {
                p = WatchUi.loadResource(Rez.JsonData.ExamplePlan);
                if (isValid(p)) {
                    isExample = true;
                } else {
                    p = null;
                }
            }
        }
        setPlan(p);
    }

    static function isValid(p) as Boolean {
        if (!(p instanceof Dictionary)) { return false; }
        return p["days"] instanceof Array;
    }

    // Plan speichern und Glance-Kurzfassung neu erzeugen
    function save(p) as Void {
        isExample = false;
        Application.Storage.setValue("plan", p);
        Application.Storage.setValue("glance", buildGlance(p));
    }

    function setPlan(p) as Void {
        plan = p;
        days = [];
        todayKey = TP.todayKey();
        todayIndex = -1;
        if (p == null) { return; }

        var src = p["days"] as Array;
        var tmp = [];
        for (var i = 0; i < src.size(); i++) {
            var d = src[i];
            if (!(d instanceof Dictionary)) { continue; }
            var k = TP.dateKey(d["date"]);
            if (k == null || k < todayKey) { continue; }   // vergangene Tage ausblenden
            tmp.add([k, d]);
        }
        // nach Datum sortieren (Insertion Sort, max. 14 Einträge)
        for (var i = 1; i < tmp.size(); i++) {
            var x = tmp[i];
            var j = i - 1;
            while (j >= 0 && (tmp[j][0] as Number) > (x[0] as Number)) {
                tmp[j + 1] = tmp[j];
                j -= 1;
            }
            tmp[j + 1] = x;
        }
        days = tmp;
        for (var i = 0; i < days.size(); i++) {
            if (days[i][0] == todayKey) { todayIndex = i; }
        }
    }

    function startIndex() as Number {
        return (todayIndex >= 0) ? todayIndex : 0;
    }

    // Deutlicher Hinweis, wenn der Plan veraltet ist oder heute fehlt; sonst null
    function warningText() as String or Null {
        if (plan == null) { return "Kein Plan geladen"; }
        var parts = [];
        if (isExample) { parts.add("Beispielplan"); }
        var u = TP.dateKey(plan["updated"]);
        if (u != null && Fmt.dayNum(todayKey) - Fmt.dayNum(u) > 7) {
            parts.add("Plan älter als 7 Tage");
        }
        if (todayIndex < 0) {
            if (days.size() == 0) {
                parts.add("Plan abgelaufen");
            } else if (hasPastDays()) {
                parts.add("Heute nicht im Plan");
            } else {
                parts.add("Plan beginnt am " + Fmt.date(days[0][0] as Number));
            }
        }
        return Fmt.join(parts, " · ");
    }

    // true, wenn der Plan Tage vor heute enthält (dann ist heute eine Lücke)
    hidden function hasPastDays() as Boolean {
        var src = plan["days"] as Array;
        for (var i = 0; i < src.size(); i++) {
            var d = src[i];
            if (d instanceof Dictionary) {
                var k = TP.dateKey(d["date"]);
                if (k != null && k < todayKey) { return true; }
            }
        }
        return false;
    }

    // "Stand: 22.11., 18:30"
    function standText() as String {
        var u = Fmt.str(plan, "updated");
        var k = TP.dateKey(u);
        if (u == null || k == null) { return "Stand: unbekannt"; }
        var s = "Stand: " + Fmt.date(k);
        if (u.length() >= 16) {
            s += ", " + u.substring(11, 16);
        }
        return s;
    }

    // Kurzfassung je Tag für die Glance:
    // { "JJJJMMTT" => { "s" => [[farbe, titel, untertitel, kurz], ...] } }
    function buildGlance(p) as Dictionary {
        var out = {};
        var today = TP.todayKey();
        var src = p["days"] as Array;
        for (var i = 0; i < src.size(); i++) {
            var d = src[i];
            if (!(d instanceof Dictionary)) { continue; }
            var k = TP.dateKey(d["date"]);
            if (k == null || k < today) { continue; }
            var list = [];
            var ss = d["sessions"];
            if (ss instanceof Array) {
                for (var j = 0; j < ss.size(); j++) {
                    var s = ss[j];
                    if (!(s instanceof Dictionary)) { continue; }
                    var title = Fmt.str(s, "title");
                    if (title == null) { title = "Training"; }
                    var wo = Fmt.str(s, "workout");
                    var dur = Fmt.duration(Fmt.num(s, "durationMin"));
                    var sub = Fmt.join([wo, dur], " · ");
                    var shortTxt = Fmt.join([(wo != null) ? wo : title, dur], " · ");
                    if (s["optional"] == true) {
                        title = "(opt.) " + title;
                        shortTxt = "(opt.) " + shortTxt;
                    }
                    list.add([TP.sportColor(s["sport"]), title, (sub == null) ? "" : sub, shortTxt]);
                }
            }
            out[k.toString()] = { "s" => list };
        }
        return out;
    }
}
