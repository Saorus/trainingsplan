import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Tagesansicht: alle Einheiten eines Tages, vertikal scrollbar.
// detailMode = true zeigt zusätzlich Anleitung und Verpflegung.
class DayView extends ScrollView {

    var model;
    var detailMode = false;
    var idx = 0;
    var curKey = null;    // Datum (JJJJMMTT) des angezeigten Tages

    function initialize(m, startIdx as Number, detail as Boolean) {
        ScrollView.initialize();
        model = m;
        idx = startIdx;
        detailMode = detail;
    }

    function setDay(i as Number) as Void {
        if (i < 0 || i >= model.days.size() || i == idx) { return; }
        idx = i;
        scrollY = 0;
        refresh();
    }

    // Neuer Plan geladen: gleichen Tag wieder anzeigen, sonst heute
    function onPlanChanged() as Void {
        var newIdx = model.startIndex();
        if (curKey != null) {
            for (var i = 0; i < model.days.size(); i++) {
                if (model.days[i][0] == curKey) { newIdx = i; }
            }
        }
        if (newIdx != idx) { scrollY = 0; }
        idx = newIdx;
        refresh();
    }

    function buildLayout(dc as Graphics.Dc) as Void {
        var warn = model.warningText();

        if (model.days.size() == 0) {
            curKey = null;
            addText(dc, "Kein aktueller Plan", Graphics.FONT_MEDIUM, C_WHITE);
            addGap(10);
            addText(dc, warn, Graphics.FONT_TINY, C_WARN);
            addStatus(dc);
            return;
        }

        if (idx >= model.days.size()) { idx = model.days.size() - 1; }
        var entry = model.days[idx] as Array;
        var key = entry[0] as Number;
        var day = entry[1] as Dictionary;
        curKey = key;

        // Kopf: relativer Tag + Datum
        var diff = Fmt.dayNum(key) - Fmt.dayNum(model.todayKey);
        var rel = (diff == 0) ? "HEUTE" : (diff == 1) ? "MORGEN" : "in " + diff + " Tagen";
        addText(dc, rel, Graphics.FONT_XTINY, (diff == 0) ? C_TODAY : C_GRAY);
        addText(dc, Fmt.weekdayShort(key) + " " + Fmt.date(key), Graphics.FONT_MEDIUM, C_WHITE);

        if (warn != null) {
            addGap(4);
            addText(dc, warn, Graphics.FONT_TINY, C_WARN);
        }

        // Einheiten
        var sessions = day["sessions"];
        var count = 0;
        if (sessions instanceof Array) {
            for (var i = 0; i < sessions.size(); i++) {
                var s = sessions[i];
                if (!(s instanceof Dictionary)) { continue; }
                count += 1;
                addSession(dc, s);
            }
        }
        if (count == 0) {
            addGap(24);
            addText(dc, "Ruhetag", Graphics.FONT_LARGE, C_GRAY);
        }

        // Fuß: Tagestyp, kcal, Protein (abschaltbar)
        if (showNutrition()) {
            var kcal = Fmt.num(day, "kcal");
            var protein = Fmt.num(day, "protein");
            var nut = Fmt.join([
                (kcal != null) ? kcal.toString() + " kcal" : null,
                (protein != null) ? protein.toString() + " g Protein" : null
            ], " · ");
            var dayType = Fmt.str(day, "dayType");
            if (count == 0 && "Ruhetag".equals(dayType)) {
                dayType = null;   // steht schon groß in der Mitte
            }
            if (dayType != null || nut != null) {
                addGap(20);
                addText(dc, dayType, Graphics.FONT_XTINY, C_GRAY);
                addText(dc, nut, Graphics.FONT_XTINY, C_GRAY);
            }
        }

        addStatus(dc);
    }

    hidden function addSession(dc as Graphics.Dc, s as Dictionary) as Void {
        var color = TP.sportColor(s["sport"]);
        addGap(18);
        addBar(color);
        if (s["optional"] == true) {
            addText(dc, "OPTIONAL", Graphics.FONT_XTINY, C_GRAY);
        }
        var title = Fmt.str(s, "title");
        addText(dc, (title != null) ? title : "Training", Graphics.FONT_SMALL, color);
        addText(dc, Fmt.join([Fmt.str(s, "workout"), Fmt.duration(Fmt.num(s, "durationMin"))], " · "),
                Graphics.FONT_TINY, C_WHITE);
        addText(dc, Fmt.str(s, "target"), Graphics.FONT_TINY, C_TEXT2);

        var details = s["details"];
        var hasDetails = details instanceof Array && details.size() > 0;
        var fuel = Fmt.str(s, "fuel");

        if (!detailMode) {
            // Übersicht: nur Hinweis, dass es mehr gibt
            if (hasDetails || fuel != null) {
                addText(dc, "Anleitung", Graphics.FONT_XTINY, C_DIM);
            }
            return;
        }

        // Detailansicht: erst Anleitung/Notizen, dann Verpflegung
        if (hasDetails) {
            addGap(6);
            addText(dc, "Anleitung", Graphics.FONT_XTINY, C_GRAY);
            for (var i = 0; i < details.size(); i++) {
                var d = details[i];
                if (d instanceof String && d.length() > 0) {
                    addText(dc, "• " + d, Graphics.FONT_XTINY, C_WHITE);
                }
            }
        }
        if (fuel != null) {
            addGap(6);
            addText(dc, "Verpflegung", Graphics.FONT_XTINY, C_GRAY);
            addText(dc, fuel, Graphics.FONT_XTINY, C_FUEL);
        }
    }

    // "Stand: …" und ggf. Sync-Status (orange)
    hidden function addStatus(dc as Graphics.Dc) as Void {
        addGap(16);
        if (model.plan != null) {
            addText(dc, model.standText(), Graphics.FONT_XTINY, C_DIM);
        }
        var st = Application.Storage.getValue("syncStatus");
        if (st instanceof String) {
            addText(dc, st, Graphics.FONT_XTINY, C_SYNC);
        }
    }

    hidden function showNutrition() as Boolean {
        try {
            var v = Application.Properties.getValue("showNutrition");
            return v != false;
        } catch (e) {
            return true;
        }
    }
}

// Hauptansicht: Tasten hoch/runter und Wischen links/rechts = Tag wechseln,
// Wischen hoch/runter = scrollen, START/Tippen = Detailansicht, MENU = Menü.
class DayDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.setDay(view.idx + 1);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.setDay(view.idx - 1);
        return true;
    }

    function onSwipe(evt as WatchUi.SwipeEvent) as Boolean {
        var d = evt.getDirection();
        if (d == WatchUi.SWIPE_UP) { view.scroll(140); return true; }
        if (d == WatchUi.SWIPE_DOWN) { view.scroll(-140); return true; }
        if (d == WatchUi.SWIPE_LEFT) { view.setDay(view.idx + 1); return true; }
        if (d == WatchUi.SWIPE_RIGHT) { view.setDay(view.idx - 1); return true; }
        return false;
    }

    function onSelect() as Boolean {
        if (view.model.days.size() == 0) { return true; }
        var v = new DayView(view.model, view.idx, true);
        WatchUi.pushView(v, new ScrollDelegate(v), WatchUi.SLIDE_LEFT);
        return true;
    }

    function onMenu() as Boolean {
        var menu = new WatchUi.Menu2({ :title => "Trainingsplan" });
        menu.addItem(new WatchUi.MenuItem("Wochenübersicht", null, :week, null));
        menu.addItem(new WatchUi.MenuItem("Aktualisieren", null, :refresh, null));
        WatchUi.pushView(menu, new MainMenuDelegate(view), WatchUi.SLIDE_UP);
        return true;
    }
}

// Detail- und Wochenansicht: hoch/runter scrollt, ZURÜCK schließt.
class ScrollDelegate extends WatchUi.BehaviorDelegate {

    var view;

    function initialize(v) {
        BehaviorDelegate.initialize();
        view = v;
    }

    function onNextPage() as Boolean {
        view.scroll(120);
        return true;
    }

    function onPreviousPage() as Boolean {
        view.scroll(-120);
        return true;
    }

    function onBack() as Boolean {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
        return true;
    }
}

class MainMenuDelegate extends WatchUi.Menu2InputDelegate {

    var dayView;

    function initialize(v) {
        Menu2InputDelegate.initialize();
        dayView = v;
    }

    function onSelect(item as WatchUi.MenuItem) as Void {
        var id = item.getId();
        WatchUi.popView(WatchUi.SLIDE_IMMEDIATE);
        if (id == :week) {
            var wv = new WeekView(dayView.model);
            WatchUi.pushView(wv, new ScrollDelegate(wv), WatchUi.SLIDE_LEFT);
        } else if (id == :refresh) {
            var app = Application.getApp() as TrainingsplanApp;
            if (app.sync != null) { app.sync.start(true); }
        }
    }
}
