extends Control

# Station interface: buy/sell cargo, equipment, galactic chart, status.
# White-on-black text screens with clickable rows, in the spirit of the
# original's keyboard-driven station screens (keys 1-6 also work).

var main = null
var page := "buy"
var font: Font
var note := ""
var note_t := 0.0

const TABS := ["BUY CARGO", "SELL CARGO", "EQUIP SHIP", "GALACTIC CHART", "LOCAL CHART", "STATUS", "LAUNCH"]
const TAB_KEYS := ["1", "2", "3", "4", "5", "6", "7"]

var tab_rects: Array = []
var row_rects: Array = []
var chart_rect := Rect2()
var chart_systems: Array = []
var launch_rect := Rect2()


func _ready() -> void:
	font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_preset(Control.PRESET_FULL_RECT)


func set_page(p: String) -> void:
	page = p
	queue_redraw()


func say(text: String) -> void:
	note = text
	note_t = 3.0


func _process(delta: float) -> void:
	if note_t > 0.0:
		note_t -= delta
		if note_t <= 0.0:
			note = ""
	queue_redraw()


func _text(p: Vector2, s: String, sz: int = 16, col: Color = Color(0.9, 1.0, 0.92)) -> void:
	draw_string(font, p, s, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.01, 0.02, 0.01))
	var c: Dictionary = main.commander
	var sys: Dictionary = main.systems[int(c["system"])]

	_text(Vector2(28, 34), sys["name"].to_upper() + " STATION", 22, Color(0.95, 1.0, 0.9))
	_text(Vector2(w - 300, 34), "CASH %.1f CR    FUEL %.1f LY" % [float(c["cash"]), float(c["fuel"])], 16,
		Color(0.8, 0.95, 0.75))
	_text(Vector2(28, 58), "%s · Tech %d · %s" % [sys["economy_name"], int(sys["tech"]) + 1, sys["government_name"]], 13,
		Color(0.55, 0.75, 0.6))
	draw_line(Vector2(20, 76), Vector2(w - 20, 76), Color(0.3, 0.6, 0.4), 1.0)

	# tabs
	tab_rects.clear()
	var tx := 28.0
	for i in TABS.size():
		var label: String = TAB_KEYS[i] + " " + TABS[i]
		var tw := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x + 24.0
		var r := Rect2(tx, 90, tw, 26)
		tab_rects.append(r)
		var active: bool = _page_of_tab(i) == page
		if active:
			draw_rect(r, Color(0.12, 0.3, 0.18))
			draw_rect(r, Color(0.4, 0.85, 0.5), false, 1.0)
		_text(Vector2(tx + 12, 108), label, 15, Color(0.95, 1.0, 0.9) if active else Color(0.55, 0.7, 0.6))
		tx += tw + 8.0

	row_rects.clear()
	launch_rect = Rect2()
	match page:
		"buy":
			_draw_market(w, h, true)
		"sell":
			_draw_market(w, h, false)
		"equip":
			_draw_equip(w, h)
		"chart":
			_draw_chart(w, h)
		"local":
			_draw_local_chart(w, h)
		"status":
			_draw_status(w, h)
		"launch":
			_draw_launch(w, h)

	if note != "":
		_text(Vector2(w * 0.5 - 200, h - 18), note, 15, Color(1.0, 0.85, 0.35))
	else:
		_text(Vector2(28, h - 18), "Click a row (right-click for all) · keys 1-7 change screen · C launch", 13,
			Color(0.4, 0.55, 0.45))


func _page_of_tab(i: int) -> String:
	return ["buy", "sell", "equip", "chart", "local", "status", "launch"][i]


func _draw_market(w: float, h: float, buying: bool) -> void:
	var c: Dictionary = main.commander
	var sys: Dictionary = main.systems[int(c["system"])]
	var market: Array = main.market
	var hold: Array = c["cargo"]
	_text(Vector2(52, 152), "COMMODITY", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(330, 152), "PRICE", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(460, 152), "UNIT", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(540, 152), "FOR SALE", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(680, 152), "IN HOLD", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(860, 152), "CARGO BAY %d / %d t" % [int(c["cargo_used"]), int(c["cargo_capacity"])], 14,
		Color(0.6, 0.85, 0.7))

	for i in market.size():
		var item: Dictionary = market[i]
		var y := 182.0 + i * 26.0
		var r := Rect2(44, y - 18, 1000, 24)
		row_rects.append(r)
		var hovered := r.has_point(get_local_mouse_position())
		if hovered:
			draw_rect(r, Color(0.1, 0.22, 0.14))
		_text(Vector2(52, y), str(item["name"]), 16)
		_text(Vector2(330, y), "%.1f" % float(item["price"]), 16, Color(0.85, 0.95, 0.6))
		_text(Vector2(460, y), str(item["unit"]), 14, Color(0.6, 0.75, 0.6))
		_text(Vector2(540, y), str(int(item["qty"])), 16, Color(0.8, 0.9, 0.85))
		_text(Vector2(680, y), str(int(hold[i])), 16, Color(0.8, 0.9, 0.85))

	if buying:
		_text(Vector2(52, h - 48), "Prices vary with each system's economy. Food is cheap in agricultural systems, computers in industrial ones.",
			13, Color(0.45, 0.6, 0.5))
	else:
		_text(Vector2(52, h - 48), "Sell here for the local price. Compare with the chart before you jump.",
			13, Color(0.45, 0.6, 0.5))


func _draw_equip(w: float, h: float) -> void:
	var c: Dictionary = main.commander
	var items: Array = main.equipment_list()
	_text(Vector2(52, 152), "EQUIPMENT", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(420, 152), "PRICE", 14, Color(0.55, 0.75, 0.6))
	_text(Vector2(560, 152), "STATUS", 14, Color(0.55, 0.75, 0.6))
	for i in items.size():
		var it: Dictionary = items[i]
		var y := 184.0 + i * 30.0
		var r := Rect2(44, y - 20, 900, 28)
		row_rects.append(r)
		if r.has_point(get_local_mouse_position()):
			draw_rect(r, Color(0.1, 0.22, 0.14))
		_text(Vector2(52, y), str(it["name"]), 16)
		_text(Vector2(420, y), ("%.1f CR" % float(it["price"])) if float(it["price"]) > 0.0 else "—", 16,
			Color(0.85, 0.95, 0.6))
		var status := "OWNED" if it["owned"] else ("unavailable" if not it["available"] else "available")
		var col := Color(0.5, 0.9, 0.55) if it["owned"] else (Color(0.5, 0.55, 0.5) if not it["available"] else Color(0.85, 0.9, 0.8))
		_text(Vector2(560, y), status, 15, col)


func _draw_chart(w: float, h: float) -> void:
	var area := Rect2(48, 140, 760, 380)
	chart_rect = area
	draw_rect(area, Color(0.02, 0.05, 0.03))
	draw_rect(area, Color(0.25, 0.55, 0.35), false, 1.0)
	chart_systems.clear()
	for s in main.systems:
		var px: float = area.position.x + 10.0 + float(s["x"]) / 255.0 * (area.size.x - 20.0)
		var py: float = area.position.y + 10.0 + float(s["y"]) / 127.0 * (area.size.y - 20.0)
		chart_systems.append(Vector2(px, py))
		var col := Color(0.75, 0.95, 0.8)
		if int(s["index"]) == int(main.commander["system"]):
			col = Color(1.0, 0.9, 0.3)
		draw_rect(Rect2(px - 1, py - 1, 2, 2), col)
	# known systems within 7 light years of the current one are named
	var cur: Dictionary = main.systems[int(main.commander["system"])]
	for s in main.systems:
		var d: float = EliteGalaxy.distance_between(cur, s)
		if d <= 7.0 and d > 0.0:
			var p: Vector2 = chart_systems[int(s["index"])]
			_text(p + Vector2(5, -4), str(s["name"]), 10, Color(0.45, 0.75, 0.55))
	var tgt: int = int(main.target_system)
	if tgt >= 0:
		var tp: Vector2 = chart_systems[tgt]
		draw_line(tp + Vector2(-9, 0), tp + Vector2(9, 0), Color(1, 0.85, 0.3), 1.5)
		draw_line(tp + Vector2(0, -9), tp + Vector2(0, 9), Color(1, 0.85, 0.3), 1.5)
		draw_arc(tp, 12.0, 0, TAU, 24, Color(1, 0.85, 0.3, 0.6), 1.0, true)

	var s2: Dictionary = cur if tgt < 0 else main.systems[tgt]
	var dist: float = EliteGalaxy.distance_between(cur, s2)
	var bx := 840.0
	_text(Vector2(bx, 160), s2["name"].to_upper(), 20, Color(0.95, 1.0, 0.9))
	_text(Vector2(bx, 190), s2["economy_name"], 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 212), s2["government_name"], 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 234), "Tech level %d" % (int(s2["tech"]) + 1), 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 256), "Population %.1f billion" % (float(s2["population"]) / 10.0), 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 278), "Radius %d km" % int(s2["radius"]), 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 300), "Productivity %d MCr" % int(s2["productivity"]), 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 322), s2["species"], 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 360), "Distance %.1f LY" % dist, 17,
		Color(0.95, 0.85, 0.4) if dist <= float(main.commander["fuel"]) else Color(1, 0.45, 0.35))
	_text(Vector2(bx, 386), "Fuel on board %.1f LY" % float(main.commander["fuel"]), 14, Color(0.7, 0.9, 0.75))
	_text(Vector2(bx, 420), "Click a star to select it.", 13, Color(0.45, 0.6, 0.5))
	_text(Vector2(bx, 440), "H in flight jumps there.", 13, Color(0.45, 0.6, 0.5))
	draw_multiline_string(font, Vector2(bx, 480), str(s2.get("description", "")), HORIZONTAL_ALIGNMENT_LEFT,
		380, 13, 3, Color(0.62, 0.8, 0.66))
	_text(Vector2(52, 552), "GALACTIC CHART · GALAXY %d · 256 systems" % (int(main.commander["galaxy"]) + 1), 15,
		Color(0.6, 0.85, 0.7))


func _draw_local_chart(w: float, h: float) -> void:
	# the short-range chart of the original: the local stars drawn around the
	# ship with the 7.0 light year fuel ring, so you can see what is reachable
	var cur: Dictionary = main.systems[int(main.commander["system"])]
	var centre := Vector2(430, 336)
	var radius := 196.0
	chart_rect = Rect2(centre - Vector2(radius, radius), Vector2(radius, radius) * 2.0)
	draw_circle(centre, radius + 4.0, Color(0.02, 0.05, 0.03))
	draw_arc(centre, radius + 4.0, 0, TAU, 96, Color(0.25, 0.55, 0.35), 1.0, true)
	draw_arc(centre, radius, 0, TAU, 96, Color(1.0, 0.85, 0.3), 1.0, true)
	draw_arc(centre, radius * 0.5, 0, TAU, 72, Color(0.2, 0.4, 0.28), 1.0, true)
	# cross through the ship's own position
	draw_line(centre - Vector2(radius + 10.0, 0), centre + Vector2(radius + 10.0, 0), Color(0.16, 0.32, 0.22), 1.0)
	draw_line(centre - Vector2(0, radius + 10.0), centre + Vector2(0, radius + 10.0), Color(0.16, 0.32, 0.22), 1.0)

	# 1 LY is 4 chart units, so the ring above is 7 LY across its radius
	var scale_px := radius / 28.0
	chart_systems.clear()
	for i in main.systems.size():
		chart_systems.append(Vector2(-1000, -1000))
	for s in main.systems:
		var d: float = EliteGalaxy.distance_between(cur, s)
		if d <= 0.0 or d > 9.5:
			continue
		var px: float = centre.x + float(int(s["x"]) - int(cur["x"])) * scale_px
		var py: float = centre.y + float(int(s["y"]) - int(cur["y"])) * scale_px
		chart_systems[int(s["index"])] = Vector2(px, py)
		var col := Color(0.75, 0.95, 0.8) if d <= float(main.commander["fuel"]) else Color(0.55, 0.6, 0.55)
		draw_line(Vector2(px - 4, py), Vector2(px + 4, py), col, 1.0)
		draw_line(Vector2(px, py - 4), Vector2(px, py + 4), col, 1.0)
		_text(Vector2(px + 7, py + 5), str(s["name"]), 11, col)
	draw_circle(centre, 3.0, Color(1.0, 0.9, 0.35))

	var tgt: int = int(main.target_system)
	if tgt >= 0 and chart_systems[tgt].x > -900.0:
		var tp: Vector2 = chart_systems[tgt]
		draw_arc(tp, 11.0, 0, TAU, 24, Color(1, 0.85, 0.3, 0.7), 1.0, true)

	_text(Vector2(680, 176), "SHORT RANGE CHART", 19, Color(0.95, 1.0, 0.9))
	_text(Vector2(680, 204), "Systems within reach of %.1f LY" % float(main.commander["fuel"]), 13,
		Color(0.7, 0.9, 0.75))
	_text(Vector2(680, 232), "Yellow ring: full 7.0 LY tank", 13, Color(0.85, 0.8, 0.45))
	_text(Vector2(680, 254), "Green cross: in range now", 13, Color(0.55, 0.85, 0.6))
	if tgt >= 0 and chart_systems[tgt].x < -900.0:
		var far: Dictionary = main.systems[tgt]
		_text(Vector2(680, 292), str(far["name"]).to_upper(), 18, Color(0.95, 1.0, 0.9))
		_text(Vector2(680, 318), "%.1f LY away, off this chart." % EliteGalaxy.distance_between(cur, far),
			14, Color(1.0, 0.6, 0.35))
		_text(Vector2(680, 340), "Use the galactic chart to pick a nearer star.", 13, Color(0.55, 0.72, 0.6))
	elif tgt >= 0:
		var s2: Dictionary = main.systems[tgt]
		var dist: float = EliteGalaxy.distance_between(cur, s2)
		_text(Vector2(680, 292), str(s2["name"]).to_upper(), 18, Color(0.95, 1.0, 0.9))
		_text(Vector2(680, 316), str(s2["economy_name"]), 13, Color(0.7, 0.9, 0.75))
		_text(Vector2(680, 338), str(s2["government_name"]), 13, Color(0.7, 0.9, 0.75))
		_text(Vector2(680, 360), "Tech level %d" % (int(s2["tech"]) + 1), 13, Color(0.7, 0.9, 0.75))
		_text(Vector2(680, 388), "Distance %.1f LY" % dist, 16,
			Color(0.95, 0.85, 0.4) if dist <= float(main.commander["fuel"]) else Color(1, 0.45, 0.35))
	_text(Vector2(680, 420), "Click a star to select it.", 13, Color(0.45, 0.6, 0.5))
	_text(Vector2(680, 440), "H in flight jumps there.", 13, Color(0.45, 0.6, 0.5))
	_text(Vector2(52, 552), "LOCAL CHART · %s · GALAXY %d" % [str(cur["name"]), int(main.commander["galaxy"]) + 1],
		15, Color(0.6, 0.85, 0.7))


func _draw_status(w: float, h: float) -> void:
	var c: Dictionary = main.commander
	var sys: Dictionary = main.systems[int(c["system"])]
	var lines := [
		["COMMANDER JAMESON", ""],
		["Present system", sys["name"]],
		["Hyperspace target", main.systems[int(main.target_system)]["name"] if int(main.target_system) >= 0 else "—"],
		["Galaxy", "Galaxy " + str(int(c["galaxy"]) + 1)],
		["Legal status", str(c["legal"])],
		["Rating", str(c["rank"])],
		["Kills", str(int(c["kills"]))],
		["Cash", "%.1f CR" % float(c["cash"])],
		["Fuel", "%.1f light years" % float(c["fuel"])],
		["Cargo capacity", "%d t" % int(c["cargo_capacity"])],
		["Missiles", str(int(c["missiles"]))],
		["Laser", str(c["laser"]).capitalize() + " laser"],
		["Equipment", ", ".join(main.owned_equipment())],
		["Distance travelled", "%.1f light years" % float(c.get("distance", 0.0))]
	]
	for i in lines.size():
		var y := 152.0 + i * 30.0
		_text(Vector2(52, y), lines[i][0], 15, Color(0.55, 0.75, 0.6))
		_text(Vector2(330, y), lines[i][1], 17, Color(0.92, 1.0, 0.92))


func _draw_launch(w: float, h: float) -> void:
	launch_rect = Rect2(48, 150, 420, 44)
	draw_rect(launch_rect, Color(0.1, 0.25, 0.15))
	draw_rect(launch_rect, Color(0.4, 0.9, 0.5), false, 1.0)
	_text(Vector2(76, 178), "LAUNCH FROM STATION  (C)", 18, Color(0.95, 1.0, 0.95))
	var lines := [
		"Press C or click above to leave the station and fly.",
		"",
		"Flight controls (as on the BBC Micro):",
		"  S / X        pitch down / pull up",
		"  , / .        roll left / roll right",
		"  Space        speed up      ?  slow down",
		"  A            fire lasers",
		"  T / M        lock / fire missile",
		"  E / B        E.C.M. / energy bomb",
		"  H            hyperspace to the chart target",
		"  J            in-system jump      C  docking computer",
		"  1 2 3 4      front / rear / left / right view",
		"",
		"To dock by hand, fly into the slot face and roll until your",
		"ship is level with the slot; keep the speed under 0.22 LM."
	]
	for i in lines.size():
		_text(Vector2(52, 226 + i * 24), lines[i], 15, Color(0.75, 0.9, 0.78))


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var pos: Vector2 = event.position
		for i in tab_rects.size():
			if tab_rects[i].has_point(pos):
				_activate_tab(i)
				return
		for i in row_rects.size():
			if row_rects[i].has_point(pos):
				_click_row(i, event.button_index == MOUSE_BUTTON_RIGHT)
				return
		if page == "launch" and launch_rect.has_point(pos):
			main.launch_ship()
			return
		if page == "chart" and chart_rect.has_point(pos):
			_chart_click(pos)
			return


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		for i in TABS.size():
			if k == KEY_1 + i:
				_activate_tab(i)
				get_viewport().set_input_as_handled()
				return
		if k == KEY_C:
			main.launch_ship()
			get_viewport().set_input_as_handled()


func _activate_tab(i: int) -> void:
	page = _page_of_tab(i)
	if page == "launch":
		pass
	queue_redraw()


func _click_row(i: int, all: bool) -> void:
	match page:
		"buy":
			main.buy_cargo(i, all)
		"sell":
			main.sell_cargo(i, all)
		"equip":
			main.buy_equipment_index(i)


func _chart_click(pos: Vector2) -> void:
	var best := -1
	var best_d := 14.0
	for i in chart_systems.size():
		var d: float = chart_systems[i].distance_to(pos)
		if d < best_d:
			best_d = d
			best = i
	if best >= 0:
		main.set_target(best)
