extends Control

# Title screen: the wordmark in gold with a cool halo over black, a slowly
# rotating Cobra Mk III in white wireframe, and the two ways in.

var t := 0.0
var font: Font
var has_save := false
var hover_stars: Array = []


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng := RandomNumberGenerator.new()
	rng.seed = 1984
	for i in 180:
		hover_stars.append({"p": Vector2(rng.randf(), rng.randf()), "b": rng.randf_range(0.2, 0.85)})


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _centred(text: String, y: float, sz: int, col: Color, stretch: float = 1.0) -> void:
	var tw := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz).x * stretch
	draw_set_transform(Vector2(size.x * 0.5 - tw * 0.5, y), 0.0, Vector2(stretch, 1.0))
	draw_string(font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1, sz, col)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0))

	# a faint dust of stars, plus a cool haze behind the wordmark
	for s in hover_stars:
		var p: Vector2 = s["p"]
		draw_circle(Vector2(p.x * w, p.y * h), 1.0, Color(0.75, 0.85, 1.0, float(s["b"]) * 0.9))
	var glow_c := Vector2(w * 0.5, h * 0.30)
	for i in 5:
		var r := h * (0.20 + 0.055 * i)
		draw_circle(glow_c, r, Color(0.1, 0.35, 0.7, 0.045))

	var sz := int(min(w * 0.17, h * 0.22))
	var word := "ELITE"
	# halo: the same word drawn in cyan a few pixels around the gold
	for off in [Vector2(-4, 0), Vector2(4, 0), Vector2(0, -4), Vector2(0, 4), Vector2(-3, -3), Vector2(3, 3)]:
		_centred(word, h * 0.30 + off.y, sz, Color(0.25, 0.65, 1.0, 0.30), 1.18)
	# drop shadow, then the gold body, then the highlight along the top edge
	_centred(word, h * 0.30 + 7, sz, Color(0.14, 0.09, 0.02), 1.18)
	_centred(word, h * 0.30, sz, Color(0.72, 0.47, 0.10), 1.18)
	_centred(word, h * 0.30 - 3, sz, Color(0.98, 0.78, 0.28), 1.18)
	_centred(word, h * 0.30 - 6, sz, Color(1.0, 0.93, 0.62), 1.18)

	_centred("THE 1984 SPACE TRADING CLASSIC", h * 0.365, 15, Color(0.55, 0.82, 1.0))

	# the Cobra, turning slowly above the launch prompts
	var model := EliteShapes.cobra_mk3()
	var scale := h * 0.135
	var basis := Basis(Vector3(0, 1, 0), t * 0.55) * Basis(Vector3(1, 0, 0), 0.18) * Basis(Vector3(0, 0, 1), 0.12)
	var centre := Vector2(w * 0.5, h * 0.60)
	var pts: Array = []
	for v in model["v"]:
		var p: Vector3 = basis * (v * scale)
		var depth := p.z + scale * 2.4
		if depth < 1.0:
			pts.append(Vector3(0, 0, -1))
			continue
		pts.append(Vector3(centre.x + p.x * (h * 0.9) / depth, centre.y - p.y * (h * 0.9) / depth, depth))
	for e in model["e"]:
		var a: Vector3 = pts[e.x]
		var b: Vector3 = pts[e.y]
		if a.z > 0.0 and b.z > 0.0:
			var d := clamp((a.z + b.z) * 0.5 / (scale * 3.0), 0.0, 1.0)
			draw_line(Vector2(a.x, a.y), Vector2(b.x, b.y), Color(0.88, 0.96, 1.0, 0.5 + 0.5 * d), 1.6, true)

	var blink := 0.55 + 0.45 * sin(t * 3.0)
	_centred("PRESS ENTER TO START A NEW COMMANDER", h * 0.82, 20, Color(0.98, 0.9, 0.45, blink))
	if has_save:
		_centred("PRESS C TO CONTINUE YOUR LAST COMMANDER", h * 0.87, 16, Color(0.55, 0.95, 0.65))
	_centred("COBRA MK III   ·   8 GALAXIES   ·   256 SYSTEMS EACH", h * 0.94, 13, Color(0.35, 0.5, 0.55))
