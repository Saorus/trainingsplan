import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

// Hält den aktiven Plan (Vordergrund) und bereitet ihn für die Ansichten auf.
class PlanModel {

    var plan = null;        // Dictionary aus plan.json oder null
    var allDays = [];       // Array von [JJJJMMTT, Tag-Dictionary], sortiert, alle Tage
    var days = [];          // wie allDays, aber nur ab heute (für die Tagesansicht)
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
            if (PlanData.planUrl() == null) {
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

    function save(p) as Void {
        isExample = false;
        PlanData.store(p);
    }

    function setPlan(p) as Void {
        plan = p;
        allDays = [];
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
            if (k == null) { continue; }
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
        allDays = tmp;
        for (var i = 0; i < allDays.size(); i++) {
            var k = allDays[i][0] as Number;
            if (k >= todayKey) {          // vergangene Tage ausblenden
                if (k == todayKey) { todayIndex = days.size(); }
                days.add(allDays[i]);
            }
        }
    }

    function startIndex() as Number {
        return (todayIndex >= 0) ? todayIndex : 0;
    }

    // Tag-Dictionary für ein Datum oder null
    function dayFor(key as Number) as Dictionary or Null {
        for (var i = 0; i < allDays.size(); i++) {
            if (allDays[i][0] == key) { return allDays[i][1] as Dictionary; }
        }
        return null;
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
            } else if ((allDays[0][0] as Number) < todayKey) {
                parts.add("Heute nicht im Plan");
            } else {
                parts.add("Plan beginnt am " + Fmt.date(days[0][0] as Number));
            }
        }
        return Fmt.join(parts, " · ");
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
}
