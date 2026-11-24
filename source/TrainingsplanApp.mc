import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;

(:glance)
class TrainingsplanApp extends Application.AppBase {

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

    // Haupt-App: gespeicherten Plan sofort zeigen, im Hintergrund neu laden
    function getInitialView() as [WatchUi.Views] or [WatchUi.Views, WatchUi.InputDelegates] {
        model = new PlanModel();
        model.load();
        view = new DayView(model, model.startIndex(), false);
        sync = new PlanSync(model, view);
        sync.start();
        return [view, new DayDelegate(view)];
    }

    // Glance im Glance-Loop der Uhr
    (:glance)
    function getGlanceView() as [WatchUi.GlanceView] or [WatchUi.GlanceView, WatchUi.GlanceViewDelegate] or Null {
        return [new TrainingsplanGlanceView()];
    }

    // Einstellungen in Garmin Connect / Simulator geändert:
    // Plan neu laden (z. B. neue URL) und Anzeige auffrischen
    function onSettingsChanged() as Void {
        if (model == null) { return; }
        model.load();
        if (view != null) { view.onPlanChanged(); }
        if (sync != null) { sync.start(); }
    }
}
