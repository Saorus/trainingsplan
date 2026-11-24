import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;

// Basis für scrollbare Textansichten auf dem runden 416er-Display.
// Unterklassen füllen in buildLayout() Zeilen über addText/addBar/addRow;
// der Inhalt wird einmal umgebrochen und beim Scrollen nur verschoben.
class ScrollView extends WatchUi.View {

    const CONTENT_W = 290;   // passt zwischen y = 58 und y = 358 in den Kreis
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
    const C_ROWBG = 0x333300;

    var scrollY = 0;
    var maxScroll = 0;
    // Einträge: [y, art, text, font, farbe, (Zeile:) label, punkte, markiert]
    // art: 0 = Text zentriert, 1 = Farbbalken, 2 = Tabellenzeile
    var layout = null;

    hidden var _y = 0;
    hidden var _items = null;

    function initialize() {
        View.initialize();
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

    // Inhalt neu aufbauen, Scrollposition behalten
    function refresh() as Void {
        layout = null;
        WatchUi.requestUpdate();
    }

    function onShow() as Void {
        layout = null;   // Einstellungen oder Plan könnten sich geändert haben
    }

    // von Unterklassen überschrieben
    function buildLayout(dc as Graphics.Dc) as Void {
    }

    function onUpdate(dc as Graphics.Dc) as Void {
        dc.setColor(C_WHITE, Graphics.COLOR_BLACK);
        dc.clear();
        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;

        if (layout == null) {
            _items = [];
            _y = 0;
            buildLayout(dc);
            layout = _items;
            _items = null;
            maxScroll = TOP + _y - BOTTOM;
            if (maxScroll < 0) { maxScroll = 0; }
            if (scrollY > maxScroll) { scrollY = maxScroll; }
        }

        // Inhalt nur zwischen den Scroll-Pfeilen zeichnen
        dc.setClip(0, 30, w, h - 60);
        var y0 = TOP - scrollY;
        for (var i = 0; i < layout.size(); i++) {
            var it = layout[i] as Array;
            var y = y0 + (it[0] as Number);
            if (y > h || y < -80) { continue; }
            var kind = it[1] as Number;
            if (kind == 1) {
                dc.setColor(it[4] as Number, Graphics.COLOR_TRANSPARENT);
                dc.fillRoundedRectangle(cx - 40, y, 80, 6, 3);
            } else if (kind == 2) {
                drawRow(dc, cx, y, it);
            } else {
                dc.setColor(it[4] as Number, Graphics.COLOR_TRANSPARENT);
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

    // Tabellenzeile: "Mo" links, farbige Punkte, Text
    hidden function drawRow(dc as Graphics.Dc, cx as Number, y as Number, it as Array) as Void {
        var font = it[3];
        var fh = dc.getFontHeight(font);
        var left = cx - 140;
        var right = cx + 140;
        if (it[7] == true) {
            dc.setColor(C_ROWBG, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(left - 8, y, right - left + 16, fh, 8);
        }
        dc.setColor(it[4] as Number, Graphics.COLOR_TRANSPARENT);
        dc.drawText(left, y, font, it[5] as String, Graphics.TEXT_JUSTIFY_LEFT);
        var x = left + 52;
        var dots = it[6] as Array;
        for (var i = 0; i < dots.size() && i < 3; i++) {
            dc.setColor(dots[i] as Number, Graphics.COLOR_TRANSPARENT);
            dc.fillCircle(x + 6, y + fh / 2, 6);
            x += 15;
        }
        x += 6;
        dc.setColor(it[4] as Number, Graphics.COLOR_TRANSPARENT);
        dc.drawText(x, y, font, TP.fitText(dc, it[2] as String, font, right - x), Graphics.TEXT_JUSTIFY_LEFT);
    }

    // ---------- Bausteine für buildLayout ----------

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

    hidden function addRow(dc as Graphics.Dc, label as String, dots as Array, text as String,
                           color as Number, marked as Boolean) as Void {
        var font = Graphics.FONT_XTINY;
        _items.add([_y, 2, text, font, color, label, dots, marked]);
        _y += dc.getFontHeight(font) + 6;
    }

    hidden function addGap(px as Number) as Void {
        _y += px;
    }
}
