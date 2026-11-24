import Toybox.Application;
import Toybox.Background;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.WatchUi;

(:glance, :background)
class TrainingsplanApp extends Application.AppBase {

    const SYNC_INTERVAL = 6 * 3600;   // Hintergrund-Sync alle 6 Stunden

    var model = null;
    var view = null;
    var sync = null;

    function initialize() {
        AppBase.initialize();
    }

    function onStart(state as Dictionary?) as Void {
    }

    function onStop(state as Dictionary?) as Void {
    }

    // Haupt-App: gespeicherten Plan sofort zeigen, parallel neu laden
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        model = new PlanModel();
        model.load();
        view = new DayView(model, model.startIndex(), false);
        sync = new PlanSync(model, view);
        sync.start(false);
        registerBackgroundSync();
        return [view, new DayDelegate(view)];
    }

    // Glance im Glance-Loop der Uhr
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new TrainingsplanGlanceView()];
    }

    // Hintergrundprozess
    function getServiceDelegate() as [System.ServiceDelegate] {
        return [new PlanServiceDelegate()];
    }

    // Hintergrund-Sync hat einen neuen Plan gespeichert, während die App offen ist
    function onBackgroundData(data as Application.PersistableType) as Void {
        if (data == true && model != null) {
            model.load();
            if (view != null) { view.onPlanChanged(); }
        }
        WatchUi.requestUpdate();
    }

    // Einstellungen in Garmin Connect / Simulator geändert:
    // Plan neu laden (z. B. neue URL) und Anzeige auffrischen
    function onSettingsChanged() as Void {
        if (model == null) { return; }
        model.load();
        if (view != null) { view.onPlanChanged(); }
        if (sync != null) { sync.start(false); }
        registerBackgroundSync();
    }

    hidden function registerBackgroundSync() as Void {
        if (!(Toybox has :Background)) { return; }
        try {
            if (PlanData.planUrl() == null) {
                Background.deleteTemporalEvent();
            } else if (Background.getTemporalEventRegisteredTime() == null) {
                Background.registerForTemporalEvent(new Time.Duration(SYNC_INTERVAL));
            }
        } catch (e) {
        }
    }
}
