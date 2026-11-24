import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Lädt plan.json per HTTPS über das Handy. Bei Erfolg wird der Plan gespeichert,
// bei Fehlern bleibt der letzte gültige Plan aktiv und nur der Status ändert sich.
class PlanSync {

    var model;
    var view;
    var busy = false;

    function initialize(m, v) {
        model = m;
        view = v;
    }

    static function planUrl() as String or Null {
        try {
            var u = Application.Properties.getValue("planUrl");
            if (u instanceof String && u.length() > 8) { return u; }
        } catch (e) {
        }
        return null;
    }

    function start() as Void {
        if (busy) { return; }
        var url = planUrl();
        if (url == null) {
            setStatus("Plan-URL fehlt (Einstellungen)");
            return;
        }
        busy = true;
        setStatus("Aktualisiere …");
        // Cache-Buster, damit GitHub/Telefon keine alte Version liefern
        var sep = (url.find("?") == null) ? "?" : "&";
        Communications.makeWebRequest(
            url + sep + "t=" + Time.now().value(),
            null,
            {
                :method => Communications.HTTP_REQUEST_METHOD_GET,
                :responseType => Communications.HTTP_RESPONSE_CONTENT_TYPE_JSON
            },
            method(:onReceive)
        );
    }

    function onReceive(code as Number, data as Dictionary or String or Null) as Void {
        busy = false;
        if (code != 200) {
            setStatus("Sync-Fehler: " + errorText(code));
            return;
        }
        var err = checkPlan(data);
        if (err != null) {
            setStatus("Sync-Fehler: " + err);
            return;
        }
        model.save(data);
        model.setPlan(data);
        Application.Storage.setValue("lastSync", Time.now().value());
        setStatus(null);
        if (view != null) { view.onPlanChanged(); }
    }

    // Minimalprüfung; die ausführliche Prüfung macht validate_plan.py vor dem Upload
    static function checkPlan(p) as String or Null {
        if (!(p instanceof Dictionary)) { return "keine JSON-Struktur"; }
        var v = p["schemaVersion"];
        if (!(v instanceof Number)) { return "schemaVersion fehlt"; }
        if (v > 1) { return "Plan neuer als App"; }   // unterstützte schemaVersion: 1
        if (!(p["days"] instanceof Array)) { return "days fehlt"; }
        return null;
    }

    static function errorText(code as Number) as String {
        if (code == 404) { return "Datei nicht gefunden (404)"; }
        if (code >= 400 && code < 600) { return "Server " + code; }
        if (code == -104 || code == -2) { return "keine Verbindung zum Handy"; }
        if (code == -300) { return "Zeitüberschreitung"; }
        if (code == -400 || code == -1002) { return "ungültige Antwort (kein JSON)"; }
        if (code == -402 || code == -403) { return "Plan zu groß"; }
        if (code == -1001) { return "HTTPS erforderlich"; }
        return "Code " + code;
    }

    hidden function setStatus(s as String or Null) as Void {
        if (s == null) {
            Application.Storage.deleteValue("syncStatus");
        } else {
            Application.Storage.setValue("syncStatus", s);
        }
        if (view != null) { view.refresh(); }
    }
}
