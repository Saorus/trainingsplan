import Toybox.Application;
import Toybox.Background;
import Toybox.Communications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;

// Hintergrund-Sync (alle 6 h): lädt plan.json und speichert sie direkt.
// Fehler bleiben still – der letzte gültige Plan bleibt aktiv, und beim
// nächsten Öffnen der App wird ohnehin neu geladen.
(:background)
class PlanServiceDelegate extends System.ServiceDelegate {

    function initialize() {
        ServiceDelegate.initialize();
    }

    function onTemporalEvent() as Void {
        var url = PlanData.planUrl();
        if (url == null) {
            Background.exit(false);
            return;
        }
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
        var ok = false;
        if (code == 200 && PlanData.checkPlan(data) == null) {
            try {
                PlanData.store(data);
                Application.Storage.setValue("lastSync", Time.now().value());
                Application.Storage.deleteValue("syncStatus");
                ok = true;
            } catch (e) {
                ok = false;
            }
        }
        Background.exit(ok);
    }
}
