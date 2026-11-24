import Toybox.Application;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.Time;
import Toybox.WatchUi;

// Lädt plan.json im Vordergrund (beim Öffnen und über „Aktualisieren“).
// Bei Fehlern bleibt der letzte gültige Plan aktiv und nur der Status ändert sich.
class PlanSync {

    var model;
    var view;
    var busy = false;
    var manual = false;   // per Menü ausgelöst → Ergebnis als Toast melden

    function initialize(m, v) {
        model = m;
        view = v;
    }

    function start(isManual as Boolean) as Void {
        if (busy) { return; }
        manual = isManual;
        var url = PlanData.planUrl();
        if (url == null) {
            setStatus("Plan-URL fehlt (Einstellungen)");
            toast("Plan-URL fehlt");
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
        var err = (code == 200) ? PlanData.checkPlan(data) : PlanData.errorText(code);
        if (err != null) {
            setStatus("Sync-Fehler: " + err);
            toast("Fehler: " + err);
            return;
        }
        model.save(data);
        model.setPlan(data);
        Application.Storage.setValue("lastSync", Time.now().value());
        setStatus(null);
        toast("Plan aktualisiert");
        if (view != null) { view.onPlanChanged(); }
    }

    hidden function toast(msg as String) as Void {
        if (manual && (WatchUi has :showToast)) {
            WatchUi.showToast(msg, null);
        }
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
