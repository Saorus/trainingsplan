import Toybox.Application;
import Toybox.Lang;

// Plan-Logik, die auch der Hintergrundprozess (64 KB) braucht:
// URL lesen, Plan prüfen, Glance-Kurzfassung erzeugen, speichern.
(:background)
module PlanData {

    function planUrl() as String or Null {
        try {
            var u = Application.Properties.getValue("planUrl");
            if (u instanceof String && u.length() > 8) { return u; }
        } catch (e) {
        }
        return null;
    }

    // Minimalprüfung; die ausführliche Prüfung macht validate_plan.py vor dem Upload
    function checkPlan(p) as String or Null {
        if (!(p instanceof Dictionary)) { return "keine JSON-Struktur"; }
        var v = p["schemaVersion"];
        if (!(v instanceof Number)) { return "schemaVersion fehlt"; }
        if (v > 1) { return "Plan neuer als App"; }   // unterstützte schemaVersion: 1
        if (!(p["days"] instanceof Array)) { return "days fehlt"; }
        return null;
    }

    function errorText(code as Number) as String {
        if (code == 404) { return "Datei nicht gefunden (404)"; }
        if (code >= 400 && code < 600) { return "Server " + code; }
        if (code == -104 || code == -2) { return "keine Verbindung zum Handy"; }
        if (code == -300) { return "Zeitüberschreitung"; }
        if (code == -400 || code == -1002) { return "ungültige Antwort (kein JSON)"; }
        if (code == -402 || code == -403) { return "Plan zu groß"; }
        if (code == -1001) { return "HTTPS erforderlich"; }
        return "Code " + code;
    }

    // Gültigen Plan samt Glance-Kurzfassung speichern
    function store(p) as Void {
        Application.Storage.setValue("plan", p);
        Application.Storage.setValue("glance", buildGlance(p));
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
