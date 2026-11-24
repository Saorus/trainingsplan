import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Tagesansicht: alle Einheiten eines Tages, vertikal scrollbar.
// Inhalt wird einmal pro Tag umgebrochen und dann nur noch verschoben.
class DayView extends WatchUi.View {

    const CONTENT_W = 290;   // passt im runden 416er-Display zwischen y = 58 und y = 358
    const TOP = 58;
    const BOTTOM = 358;

    const C_WHITE = 0xFFFFFF;
    const C_GRAY = 0xAAAAAA;
    const C_DIM = 0x777777;
    const C_TEXT2 = 0xDDDDDD;
    const C_FUEL = 0x88CCFF;
    const C_TODAY = 0xFFDD00;
    const C_WARN = 0xFF4444;
    const C_SYNC = 0xFFAA00;

    var model;
    var detailMode = false;   // true = Detailansicht mit Anleitung und Verpflegung
    var idx = 0;
    var scrollY = 0;
    var maxScroll = 0;
    var layout = null;    // Array von [y, art (0 = Text, 1 = Balken), text, font, farbe]

    var curKey = null;    // Datum (JJJJMMTT) des angezeigten Tages

    hidden var _y = 0;
    hidden var _items = null;

    function initialize(m, startIdx as Number, detail as Boolean) {
        View.initialize();
        model = m;
        idx = startIdx;
        detailMode = detail;
    }

    function setDay(i as Number) as Void {
        if (i < 0 || i >= model.days.size() || i == idx) { return; }
        idx = i;
        scrollY = 0;
        layout = null;
        WatchUi.requestUpdate();
    }

    function scroll(delta as Number) as Void {
        var n = scrollY + delta;
        if (n > maxScroll) { n = maxScroll; }
        if (n < 0) { n = 0; }
        if (n != scrollY) {
            scrollY = n;
            WatchUi.requestUpdate();
        }
    }

    // Status geändert: neu umbrechen, Position behalten
    function refresh() as Void {
        layout = null;
        WatchUi.requestUpdate();
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

    function onShow() as Void {
        layout = null;   // Einstellungen könnten sich geändert haben
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(C_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        if (layout == null) {
            buildLayout(dc);
        }

        // Inhalt nur zwischen den Scroll-Pfeilen zeichnen
        dc.setClip(0, 30, w, h - 60);
        var y0 = TOP - scrollY;
        for (var i = 0; i < layout.size(); i++) {
            var it = layout[i] as Array;
            var y = y0 + (it[0] as Number);
            if (y > h || y < -80) { continue; }
            dc.setColor(it[4] as Number, Graphics.COLOR_TRANSPARENT);
            if (it[1] == 1) {
                dc.fillRoundedRectangle(cx - 40, y, 80, 6, 3);
            } else {
                dc.drawText(cx, y, it[3], it[2] as String, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        dc.clearClip();

        // Scroll-Hinweise
        dc.setColor(C_GRAY, Graphics.COLOR_TRANSPARENT);
        if (scrollY < maxScroll) {
            dc.fillPolygon([[cx - 14, h - 24], [cx + 14, h - 24], [cx, h - 10]]);
        }
        if (scrollY > 0) {
            dc.fillPolygon([[cx - 14, 24], [cx + 14, 24], [cx, 10]]);
        }
    }

    // ---------- Layout ----------

    hidden function addText(dc as Graphics.Dc, text, font, color as Number) as Void {
        if (!(text instanceof String) || text.length() == 0) { return; }
        var lines = Fmt.wrap(dc, text, font, CONTENT_W);
        var fh = dc.getFontHeight(font);
        for (var i = 0; i < lines.size(); i++) {
            _items.add([_y, 0, lines[i], font, color]);
            _y += fh;
        }
    }

    hidden function addBar(color as Number) as Void {
        _items.add([_y, 1, null, null, color]);
        _y += 14;
    }

    hidden function buildLayout(dc as Graphics.Dc) as Void {
        _items = [];
        _y = 0;

        var warn = model.warningText();

        if (model.days.size() == 0) {
            curKey = null;
            addText(dc, "Kein aktueller Plan", Graphics.FONT_MEDIUM, C_WHITE);
            _y += 10;
            addText(dc, warn, Graphics.FONT_TINY, C_WARN);
            addStatus(dc);
            finishLayout();
            return;
        }

        if (idx >= model.days.size()) { idx = model.days.size() - 1; }
        var entry = model.days[idx] as Array;
        var key = entry[0] as Number;
        curKey = key;
        var day = entry[1] as Dictionary;

        // Kopf: relativer Tag + Datum
        var diff = Fmt.dayNum(key) - Fmt.dayNum(model.todayKey);
        var rel = (diff == 0) ? "HEUTE" : (diff == 1) ? "MORGEN" : "in " + diff + " Tagen";
        addText(dc, rel, Graphics.FONT_XTINY, (diff == 0) ? C_TODAY : C_GRAY);
        addText(dc, Fmt.weekdayShort(key) + " " + Fmt.date(key), Graphics.FONT_MEDIUM, C_WHITE);

        if (warn != null) {
            _y += 4;
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
            _y += 24;
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
                _y += 20;
                addText(dc, dayType, Graphics.FONT_XTINY, C_GRAY);
                addText(dc, nut, Graphics.FONT_XTINY, C_GRAY);
            }
        }

        addStatus(dc);
        finishLayout();
    }

    // "Stand: …" und ggf. Sync-Status (orange)
    hidden function addStatus(dc as Graphics.Dc) as Void {
        _y += 16;
        if (model.plan != null) {
            addText(dc, model.standText(), Graphics.FONT_XTINY, C_DIM);
        }
        var st = Application.Storage.getValue("syncStatus");
        if (st instanceof String) {
            addText(dc, st, Graphics.FONT_XTINY, C_SYNC);
        }
    }

    hidden function addSession(dc as Graphics.Dc, s as Dictionary) as Void {
        var color = TP.sportColor(s["sport"]);
        _y += 18;
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
            _y += 6;
            addText(dc, "Anleitung", Graphics.FONT_XTINY, C_GRAY);
            for (var i = 0; i < details.size(); i++) {
                var d = details[i];
                if (d instanceof String && d.length() > 0) {
                    addText(dc, "• " + d, Graphics.FONT_XTINY, C_WHITE);
                }
            }
        }
        if (fuel != null) {
            _y += 6;
            addText(dc, "Verpflegung", Graphics.FONT_XTINY, C_GRAY);
            addText(dc, fuel, Graphics.FONT_XTINY, C_FUEL);
        }
    }

    hidden function finishLayout() as Void {
        layout = _items;
        _items = null;
        maxScroll = TOP + _y - BOTTOM;
        if (maxScroll < 0) { maxScroll = 0; }
        if (scrollY > maxScroll) { scrollY = maxScroll; }
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
// Wischen hoch/runter = scrollen, START/Tippen = Detailansicht (mit Tasten scrollbar).
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
        WatchUi.pushView(v, new DetailDelegate(v), WatchUi.SLIDE_LEFT);
        return true;
    }
}

// Detailansicht: gleicher Inhalt, aber hoch/runter scrollt. Zurück = ESC oder nach rechts wischen.
class DetailDelegate extends WatchUi.BehaviorDelegate {

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
