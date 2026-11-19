extends Control

# Flight view: custom 3D-to-2D vector projection in the style of the BBC Micro
# original (flat white wireframes on black) plus the cockpit dashboard and the
# elliptical scanner.

signal docked
signal died
signal witchspace_ended

const FOCAL_RATIO := 0.62
const NEAR := 2.0
const SCANNER_RANGE := 25600.0
const LASER_RANGE := 15000.0
const STATION_SPIN := 0.12
const DOCK_CAPTURE := 650.0
const DOCK_SPEED := 220.0
const DOCK_ROLL_DOT := 0.86
const HULL_RADIUS := 470.0

# The four colours the BBC Micro cockpit used.
const C_WHITE := Color(0.98, 0.98, 0.98)
const C_YELLOW := Color(0.98, 0.98, 0.0)
const C_GREEN := Color(0.0, 0.98, 0.0)
const C_RED := Color(0.98, 0.0, 0.0)

var main = null
var game: Dictionary = {}
var system: Dictionary = {}
var objects: Array = []
var stars: Array = []

var player := {"pos": Vector3.ZERO, "basis": Basis.IDENTITY, "speed": 0.0}
var pitch_rate := 0.0
var roll_rate := 0.0
var laser_temp := 0.0
var laser_cd := 0.0
var laser_flash := 0.0
var autopilot := false
var autopilot_t := 0.0
var paused := false
var dead := false
var msg := ""
var msg_t := 0.0
var lock_index := -1
var missile: Dictionary = {}
var flight_time := 0.0
var shots := 0
var hits := 0
var hud_draws := 0
var starfield_on := true
var explosions: Array = []
var scripted_input := false
var view_index := 0
var witchspace := false
var witch_t := 0.0
var cabin_temp := 12.0
var hint_t := 0.0
var crash_cd := 0.0
var police_called := false
var dock_hint_t := 0.0
var ecm_t := 0.0
var sfx := {}
const VIEW_NAMES := ["Front View", "Rear View", "Left View", "Right View"]

var font: Font


func _ready() -> void:
	font = ThemeDB.fallback_font
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_stars()
	_build_sfx()


func _build_sfx() -> void:
	for key in ["laser", "boom", "beep", "dock"]:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0 if key == "laser" else -2.0
		add_child(p)
		var path := "res://audio/%s.wav" % key
		if ResourceLoader.exists(path):
			p.stream = load(path)
		sfx[key] = p


func play(key: String) -> void:
	var p: AudioStreamPlayer = sfx.get(key, null)
	if p != null and p.stream != null and not dead:
		p.play()


func _build_stars() -> void:
	stars.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = 1984
	for i in 260:
		var z := rng.randf_range(-1.0, 1.0)
		var a := rng.randf_range(0.0, TAU)
		var r := sqrt(max(0.0, 1.0 - z * z))
		stars.append({"dir": Vector3(cos(a) * r, z, sin(a) * r), "b": rng.randf_range(0.25, 1.0), "s": rng.randf_range(1.0, 2.2)})


func setup(sys: Dictionary, commander: Dictionary, arrival: bool) -> void:
	system = sys
	game = commander
	objects.clear()
	explosions.clear()
	laser_temp = 0.0
	laser_cd = 0.0
	witchspace = false
	witch_t = 0.0
	autopilot = false
	dead = false
	msg = ""
	msg_t = 0.0
	lock_index = -1
	player["pos"] = Vector3.ZERO
	player["basis"] = Basis.IDENTITY
	player["speed"] = 0.0
	pitch_rate = 0.0
	roll_rate = 0.0
	flight_time = 0.0
	hint_t = 20.0
	if arrival:
		player["pos"] = Vector3(0, 0, 0)
	_add_planet(arrival)
	_add_sun()
	_add_station(arrival)
	_spawn_traffic(arrival)
	show()
	queue_redraw()


func _add_planet(arrival: bool) -> void:
	var dist := 260000.0 if arrival else 300000.0
	var p := Vector3(60000.0, -20000.0, -dist)
	objects.append({
		"role": "planet", "pos": p, "radius": float(system["radius"]) * 7.0,
		"name": system["name"], "basis": Basis.IDENTITY, "spin": 0.0
	})


func _add_sun() -> void:
	objects.append({
		"role": "sun", "pos": Vector3(340000.0, 120000.0, 260000.0), "radius": 42000.0,
		"name": "Sun", "basis": Basis.IDENTITY, "spin": 0.0
	})


func _add_station(arrival: bool) -> void:
	var p: Vector3
	if arrival:
		p = Vector3(-180.0, 60.0, -14000.0)
	else:
		p = Vector3(620.0, 140.0, -3400.0)
	var b := Basis.looking_at(Vector3.ZERO - p, Vector3.UP)
	objects.append({
		"role": "station", "pos": p, "radius": 420.0, "size": 420.0,
		"name": system["name"] + " Station", "basis": b, "spin": 0.0,
		"model": EliteShapes.station()
	})


func _spawn_traffic(arrival: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = system["index"] * 7919 + int(flight_time) + 4241
	var gov: int = system["government"]
	var pirate_count := 0
	if system["index"] != 7 or arrival:
		pirate_count = clampi(3 - int(gov / 2.0) + rng.randi_range(0, 1), 0, 4)
	var trader_count := 2
	for i in pirate_count:
		_spawn_ship("pirate", rng)
	for i in trader_count:
		_spawn_ship("trader", rng)
	if gov >= 4:
		_spawn_ship("police", rng)
	if rng.randf() < 0.5:
		_spawn_asteroid(rng)


func _random_model(role: String) -> Dictionary:
	var choices := ["sidewinder", "krait", "mamba", "adder", "cobra"]
	if role == "trader":
		choices = ["python", "boa", "anaconda", "adder", "cobra"]
	elif role == "police":
		choices = ["viper"]
	elif role == "pirate":
		choices = ["sidewinder", "krait", "mamba", "gecko", "cobra_mk1", "asp", "fer_de_lance"]
	var pick: String = choices[randi() % choices.size()]
	match pick:
		"sidewinder": return {"m": EliteShapes.sidewinder(), "size": 70.0, "name": "Sidewinder", "speed": 370.0, "energy": 60.0, "bounty": 5.0}
		"krait": return {"m": EliteShapes.krait(), "size": 80.0, "name": "Krait", "speed": 300.0, "energy": 80.0, "bounty": 10.0}
		"mamba": return {"m": EliteShapes.mamba(), "size": 85.0, "name": "Mamba", "speed": 350.0, "energy": 90.0, "bounty": 15.0}
		"adder": return {"m": EliteShapes.adder(), "size": 75.0, "name": "Adder", "speed": 240.0, "energy": 70.0, "bounty": 4.0}
		"gecko": return {"m": EliteShapes.gecko(), "size": 80.0, "name": "Gecko", "speed": 300.0, "energy": 75.0, "bounty": 6.0}
		"cobra_mk1": return {"m": EliteShapes.cobra_mk1(), "size": 65.0, "name": "Cobra Mk I", "speed": 270.0, "energy": 70.0, "bounty": 8.0}
		"asp": return {"m": EliteShapes.asp(), "size": 95.0, "name": "Asp Mk II", "speed": 360.0, "energy": 120.0, "bounty": 25.0}
		"fer_de_lance": return {"m": EliteShapes.fer_de_lance(), "size": 110.0, "name": "Fer-de-Lance", "speed": 340.0, "energy": 140.0, "bounty": 30.0}
		"python": return {"m": EliteShapes.python(), "size": 150.0, "name": "Python", "speed": 200.0, "energy": 200.0, "bounty": 20.0}
		"boa": return {"m": EliteShapes.boa(), "size": 180.0, "name": "Boa", "speed": 170.0, "energy": 240.0, "bounty": 25.0}
		"anaconda": return {"m": EliteShapes.anaconda(), "size": 220.0, "name": "Anaconda", "speed": 150.0, "energy": 280.0, "bounty": 40.0}
		"viper": return {"m": EliteShapes.viper(), "size": 90.0, "name": "Viper", "speed": 320.0, "energy": 110.0, "bounty": 15.0}
	return {"m": EliteShapes.sidewinder(), "size": 70.0, "name": "Sidewinder", "speed": 350.0, "energy": 60.0, "bounty": 5.0}


func _spawn_police() -> void:
	var st := _find_station()
	var base: Vector3 = player["pos"] + (-player["basis"].z) * -900.0
	if not st.is_empty():
		base = st["pos"] + Vector3(randf_range(-500.0, 500.0), 200.0, randf_range(-500.0, 500.0))
	var d := _random_model("police")
	objects.append({
		"role": "police", "pos": base, "basis": Basis.looking_at(player["pos"] - base, Vector3.UP),
		"model": d["m"], "size": d["size"], "name": d["name"], "speed": 0.0,
		"max_speed": d["speed"], "energy": d["energy"], "max_energy": d["energy"],
		"bounty": d["bounty"], "hostile": true, "cd": 1.0, "hit_flash": 0.0, "aggression": 1.0
	})


func _spawn_ship(role: String, rng: RandomNumberGenerator) -> void:
	var d := _random_model(role)
	var ang := rng.randf_range(0.0, TAU)
	var dist := rng.randf_range(2200.0, 9000.0)
	var pos := Vector3(cos(ang) * dist, rng.randf_range(-900.0, 900.0), -abs(sin(ang)) * dist - 1500.0)
	if rng.randf() < 0.5:
		pos.z = -pos.z
	var look_target: Vector3 = player["pos"]
	objects.append({
		"role": role, "pos": pos, "basis": Basis.looking_at(look_target - pos, Vector3.UP),
		"model": d["m"], "size": d["size"], "name": d["name"], "speed": d["speed"] * 0.0,
		"max_speed": d["speed"], "energy": d["energy"], "max_energy": d["energy"],
		"bounty": d["bounty"], "hostile": role == "pirate", "cd": rng.randf_range(0.5, 3.0),
		"hit_flash": 0.0, "aggression": rng.randf_range(0.3, 1.0)
	})


func _spawn_asteroid(rng: RandomNumberGenerator) -> void:
	var pos := Vector3(rng.randf_range(-4000.0, 4000.0), rng.randf_range(-1500.0, 1500.0), -rng.randf_range(3000.0, 9000.0))
	objects.append({
		"role": "asteroid", "pos": pos, "basis": Basis.IDENTITY, "model": EliteShapes.asteroid(),
		"size": rng.randf_range(90.0, 160.0), "name": "Asteroid", "speed": rng.randf_range(20.0, 70.0),
		"max_speed": 70.0, "energy": 40.0, "max_energy": 40.0, "bounty": 0.5,
		"hostile": false, "cd": 0.0, "hit_flash": 0.0, "aggression": 0.0
	})


# Called by the self-test harness: a harmless target straight ahead.
func spawn_test_target() -> void:
	var pos: Vector3 = player["pos"] + (-player["basis"].z) * 700.0
	objects.append({
		"role": "target", "pos": pos, "basis": Basis.looking_at(player["pos"] - pos, Vector3.UP),
		"model": EliteShapes.sidewinder(), "size": 70.0, "name": "Test Drone", "speed": 0.0,
		"max_speed": 0.0, "energy": 100.0, "max_energy": 100.0, "bounty": 0.0,
		"hostile": false, "cd": 999.0, "hit_flash": 0.0, "aggression": 0.0
	})


func say(text: String, seconds: float = 3.0) -> void:
	msg = text
	msg_t = seconds


func _process(delta: float) -> void:
	if game.is_empty() or not is_visible_in_tree():
		return
	if paused or dead:
		queue_redraw()
		return
	delta = min(delta, 0.05)
	flight_time += delta
	hint_t = max(0.0, hint_t - delta)
	_handle_input(delta)
	_update_player(delta)
	_update_objects(delta)
	_update_systems(delta)
	_update_explosions(delta)
	if witchspace:
		witch_t -= delta
		var alive := false
		for o in objects:
			if o["role"] == "thargoid":
				alive = true
				break
		if witch_t <= 0.0 or not alive:
			witchspace = false
			witchspace_ended.emit()
	msg_t = max(0.0, msg_t - delta)
	queue_redraw()


func _handle_input(delta: float) -> void:
	var pitch_in := Input.get_axis("pitch_down", "pitch_up")
	var roll_in := Input.get_axis("roll_right", "roll_left")

	if Input.is_action_pressed("accelerate"):
		player["speed"] = min(350.0, player["speed"] + 140.0 * delta)
	if Input.is_action_pressed("decelerate"):
		player["speed"] = max(0.0, player["speed"] - 140.0 * delta)

	var target_pitch := pitch_in * 1.25
	var target_roll := roll_in * 2.0
	pitch_rate = lerp(pitch_rate, target_pitch, min(1.0, 5.0 * delta))
	roll_rate = lerp(roll_rate, target_roll, min(1.0, 6.0 * delta))

	var basis: Basis = player["basis"]
	basis = basis * Basis(Vector3(1, 0, 0), pitch_rate * delta)
	basis = basis * Basis(Vector3(0, 0, 1), roll_rate * delta)
	player["basis"] = basis.orthonormalized()

	if autopilot:
		_autopilot_flight(delta)

	if Input.is_action_pressed("fire"):
		try_fire()


func _autopilot_flight(delta: float) -> void:
	autopilot_t += delta
	var st := _find_station()
	if st.is_empty():
		autopilot = false
		return
	var to: Vector3 = st["pos"] - player["pos"]
	var dist := to.length()
	_dist = dist
	var up_hint: Vector3 = _slot_axis(st)
	var want := Basis.looking_at(to.normalized(), up_hint)
	player["basis"] = player["basis"].slerp(want, min(1.0, 2.5 * delta)).orthonormalized()
	# Roll into the slot before closing, then creep the last stretch so the
	# capture test (facing, roll, speed) is met rather than crashed through.
	var align: float = up_hint.dot(player["basis"].y)
	var target_speed := clampf((dist - 520.0) * 0.25, 18.0, 260.0)
	if align < 0.86:
		target_speed = minf(target_speed, 70.0)
	player["speed"] = move_toward(player["speed"], target_speed, 220.0 * delta)


var _dist := 0.0


func _update_player(delta: float) -> void:
	var fwd: Vector3 = -player["basis"].z
	player["pos"] += fwd * float(player["speed"]) * delta

	laser_temp = max(0.0, laser_temp - 42.0 * delta)
	laser_cd = max(0.0, laser_cd - delta)
	laser_flash = max(0.0, laser_flash - delta)
	ecm_t = max(0.0, ecm_t - delta)

	game["energy"] = min(game["energy_max"], float(game["energy"]) + 6.0 * delta)
	game["shield_f"] = min(255.0, float(game["shield_f"]) + 2.0 * delta)
	game["shield_a"] = min(255.0, float(game["shield_a"]) + 2.0 * delta)

	# sun skimming: a fuel scoop draws plasma from the star's corona
	if bool(game["equipment"]["fuel_scoop"]):
		var sun := _find_role("sun")
		if not sun.is_empty():
			var sd: float = (sun["pos"] - player["pos"]).length()
			if sd < float(sun["radius"]) * 1.35 and float(game["fuel"]) < 7.0:
				game["fuel"] = min(7.0, float(game["fuel"]) + 1.4 * delta)
				if msg_t <= 0.0:
					say("Fuel scoop engaged - skimming the corona", 2.0)

	_check_docking(delta)


func _check_docking(delta: float) -> void:
	crash_cd = max(0.0, crash_cd - delta)
	dock_hint_t = max(0.0, dock_hint_t - delta)
	var st := _find_station()
	if st.is_empty():
		return
	var b := _station_basis(st)
	var n: Vector3 = (b * Vector3(0, 0, -1)).normalized()   # out of the slot face
	var slot_axis: Vector3 = (b * Vector3(1, 0, 0)).normalized()
	var to: Vector3 = st["pos"] - player["pos"]
	var dist := to.length()
	var fwd: Vector3 = -player["basis"].z
	var up: Vector3 = player["basis"].y
	var infront: bool = (player["pos"] - st["pos"]).dot(n) > -0.15 * dist

	if dist > DOCK_CAPTURE:
		if dist < 3000.0 and msg_t <= 0.0 and infront:
			say("Station ahead - match your roll to the slot, then ease in", 3.0)
		return

	var into: bool = fwd.dot(n) < -0.9
	var roll_ok: bool = abs(up.dot(slot_axis)) > DOCK_ROLL_DOT
	var slow: bool = float(player["speed"]) < DOCK_SPEED
	if into and roll_ok and slow and infront:
		play("dock")
		docked.emit()
		return

	# the docking computer lines the ship up itself, so it never scrapes the hull
	if autopilot:
		return

	if dist < HULL_RADIUS and infront and crash_cd <= 0.0:
		var impact: float = clamp(float(player["speed"]) * 0.3 + 20.0, 20.0, 140.0)
		player["pos"] = st["pos"] + n * (HULL_RADIUS + 70.0)
		player["speed"] = 0.0
		crash_cd = 1.5
		play("boom")
		say("HULL DAMAGE - you struck the station", 2.5)
		_damage_player(impact, true)
		return

	if dock_hint_t <= 0.0:
		dock_hint_t = 2.0
		if not into:
			say("Turn into the slot face", 2.0)
		elif not roll_ok:
			say("Match your roll to the slot", 2.0)
		elif not slow:
			say("Too fast - brake below 0.22 LM", 2.0)


func _station_basis(st: Dictionary) -> Basis:
	return (st["basis"] * Basis(Vector3(0, 0, 1), float(st["spin"]))).orthonormalized()


func _slot_axis(st: Dictionary) -> Vector3:
	return (_station_basis(st) * Vector3(1, 0, 0)).normalized()


func _find_station() -> Dictionary:
	for o in objects:
		if o["role"] == "station":
			return o
	return {}


func try_fire() -> void:
	if view_index >= 2:
		say("No laser in this view", 1.0)
		return
	if view_index == 1 and not bool(game["equipment"]["rear_laser"]):
		say("No rear laser fitted", 1.0)
		return
	if laser_temp >= 240.0 or laser_cd > 0.0:
		return
	var weapon: String = game.get("laser", "pulse")
	var dmg := 10.0
	var cost := 2.0
	if weapon == "beam":
		dmg = 16.0
		cost = 4.0
	elif weapon == "military":
		dmg = 24.0
		cost = 6.0
	if float(game["energy"]) < cost:
		say("Energy low", 1.0)
		return
	game["energy"] = float(game["energy"]) - cost
	laser_cd = 0.11
	laser_temp += 9.0
	laser_flash = 0.06
	shots += 1
	play("laser")
	# firing inside the station's safe zone brings the police out
	var st0 := _find_station()
	if not st0.is_empty() and (st0["pos"] - player["pos"]).length() < 6000.0 and not police_called:
		police_called = true
		game["legal"] = "Offender"
		say("Weapons fire in the safe zone! Viper launched", 3.0)
		_spawn_police()
	var fwd: Vector3 = -_view_basis().z
	var best := -1
	var best_ang := 999.0
	for i in objects.size():
		var o: Dictionary = objects[i]
		if o["role"] in ["planet", "sun", "station"]:
			continue
		var rel: Vector3 = o["pos"] - player["pos"]
		var dist := rel.length()
		if dist < 20.0 or dist > LASER_RANGE:
			continue
		var ang: float = fwd.angle_to(rel.normalized())
		var apparent: float = float(o.get("size", 60.0)) / dist
		var limit: float = 0.075 + apparent * 0.9
		if ang < limit and ang < best_ang:
			best_ang = ang
			best = i
	if best >= 0:
		_hit_object(best, dmg)


func _hit_object(index: int, dmg: float) -> void:
	var o: Dictionary = objects[index]
	if o["role"] == "station" or o["role"] == "planet" or o["role"] == "sun":
		return
	if o["role"] == "asteroid" and bool(game["equipment"]["mining_laser"]):
		_fracture_asteroid(index)
		return
	o["energy"] = float(o["energy"]) - dmg
	o["hit_flash"] = 0.12
	hits += 1
	explosions.append({"pos": o["pos"], "t": 0.08, "size": 40.0})
	if float(o["energy"]) <= 0.0:
		_destroy_object(index)


func _fracture_asteroid(index: int) -> void:
	var o: Dictionary = objects[index]
	explosions.append({"pos": o["pos"], "t": 0.45, "size": float(o.get("size", 100.0))})
	for k in 2:
		_drop_canister(o["pos"] + Vector3(randf_range(-40, 40), randf_range(-40, 40), randf_range(-40, 40)), 12)
	say("Asteroid fractured - scoop the splinters")
	play("boom")
	objects.remove_at(index)
	if lock_index == index:
		lock_index = -1


func _drop_canister(pos: Vector3, cargo_index: int) -> void:
	objects.append({
		"role": "canister", "pos": pos, "basis": Basis.IDENTITY, "model": EliteShapes.canister(),
		"size": 20.0, "name": "Cargo canister", "speed": randf_range(5.0, 20.0),
		"max_speed": 20.0, "energy": 1.0, "max_energy": 1.0, "bounty": 0.0,
		"hostile": false, "cd": 0.0, "hit_flash": 0.0, "aggression": 0.0,
		"cargo": cargo_index, "drift": Vector3(randf_range(-8, 8), randf_range(-5, 5), randf_range(-8, 8))
	})


func _drop_pod(pos: Vector3) -> void:
	objects.append({
		"role": "pod", "pos": pos, "basis": Basis.IDENTITY, "model": EliteShapes.canister(),
		"size": 16.0, "name": "Escape capsule", "speed": 8.0,
		"max_speed": 8.0, "energy": 1.0, "max_energy": 1.0, "bounty": 0.0,
		"hostile": false, "cd": 0.0, "hit_flash": 0.0, "aggression": 0.0,
		"cargo": -1, "drift": Vector3(0, 0, 0)
	})


func _collect(o: Dictionary, index: int) -> void:
	if o["role"] == "pod":
		game["cash"] = float(game["cash"]) + 25.0
		say("Escape capsule recovered. 25 CR reward")
		play("beep")
		objects.remove_at(index)
		return
	var idx: int = int(o.get("cargo", 12))
	if int(game["cargo_used"]) >= int(game["cargo_capacity"]):
		say("Cargo bay full - cannot scoop", 2.0)
		return
	game["cargo"][idx] = int(game["cargo"][idx]) + 1
	game["cargo_used"] = int(game["cargo_used"]) + 1
	say("Scooped 1 t of " + str(EliteGalaxy.ITEMS[idx]["name"]))
	play("beep")
	objects.remove_at(index)


func _destroy_object(index: int) -> void:
	var o: Dictionary = objects[index]
	explosions.append({"pos": o["pos"], "t": 0.5, "size": float(o.get("size", 60.0)) * 1.6})
	if o["role"] in ["pirate", "trader", "police", "asteroid", "target", "thargoid", "thargon"]:
		var bounty: float = float(o.get("bounty", 0.0))
		if o["role"] == "pirate" or o["role"] == "target" or o["role"] == "thargoid" or o["role"] == "thargon":
			game["kills"] = int(game["kills"]) + 1
			game["cash"] = float(game["cash"]) + bounty
			say("Target destroyed. Bounty %.1f CR" % bounty)
		elif o["role"] == "trader":
			say("Trader destroyed. Legal status: OFFENDER")
			game["legal"] = "Offender"
			game["kills"] = int(game["kills"]) + 1
		elif o["role"] == "police":
			say("GalCop ship destroyed! Legal status: FUGITIVE")
			game["legal"] = "Fugitive"
		# wreckage: traders and pirates spill a canister
		if o["role"] == "trader" or o["role"] == "pirate":
			_drop_canister(o["pos"], randi() % 5)
			if randf() < 0.12:
				_drop_pod(o["pos"])
	objects.remove_at(index)
	if lock_index == index:
		lock_index = -1


func _update_objects(delta: float) -> void:
	var fwd: Vector3 = -player["basis"].z
	for i in range(objects.size() - 1, -1, -1):
		var o: Dictionary = objects[i]
		var role: String = o["role"]
		if role == "planet" or role == "sun":
			o["spin"] = float(o["spin"]) + 0.02 * delta
			continue
		if role == "station":
			o["spin"] = float(o["spin"]) + STATION_SPIN * delta
			continue

		var rel: Vector3 = o["pos"] - player["pos"]
		var dist := rel.length()

		if role == "missile":
			_update_missile(o, delta)
			continue

		if role == "canister" or role == "pod":
			if bool(game["equipment"]["fuel_scoop"]) and dist < 320.0:
				_collect(o, i)
				continue
			o["pos"] = o["pos"] + (o.get("drift", Vector3.ZERO)) * delta
			continue

		if role in ["pirate", "police", "thargoid", "thargon"]:
			var want := Basis.looking_at((player["pos"] - o["pos"]).normalized(), Vector3.UP)
			var turn := 0.9 if role == "pirate" else (0.6 if role == "thargoid" else (0.8 if role == "thargon" else 0.7))
			o["basis"] = o["basis"].slerp(want, min(1.0, turn * delta)).orthonormalized()
			if role == "pirate" or role == "thargoid" or role == "thargon" or (role == "police" and game["legal"] != "Clean"):
				o["speed"] = lerp(float(o["speed"]), float(o["max_speed"]), delta)
			else:
				o["speed"] = lerp(float(o["speed"]), float(o["max_speed"]) * 0.6, delta)
			o["cd"] = float(o["cd"]) - delta
			if o["hostile"] and dist < 4200.0 and float(o["cd"]) <= 0.0:
				var ang: float = (-o["basis"].z).angle_to((player["pos"] - o["pos"]).normalized())
				if ang < 0.16:
					_enemy_fire(o, dist)
		elif role == "trader":
			o["speed"] = lerp(float(o["speed"]), float(o["max_speed"]) * 0.7, delta * 0.5)
		elif role == "asteroid" or role == "target":
			o["speed"] = float(o["speed"])
		else:
			o["speed"] = 0.0

		o["hit_flash"] = max(0.0, float(o["hit_flash"]) - delta)
		var dir: Vector3 = -o["basis"].z
		o["pos"] = o["pos"] + dir * float(o["speed"]) * delta

		# Despawn ships that drift far away.
		if dist > 30000.0 and role != "trader":
			objects.remove_at(i)


func _enemy_fire(o: Dictionary, dist: float) -> void:
	o["cd"] = randf_range(0.7, 1.6) / max(0.35, float(o["aggression"]))
	explosions.append({"pos": o["pos"] + (-o["basis"].z) * 30.0, "t": 0.06, "size": 18.0})
	var chance := clamp(1.15 - dist / 6000.0, 0.25, 0.9)
	if randf() < chance:
		var dmg := randf_range(7.0, 16.0)
		var from_front: bool = (-player["basis"].z).dot((o["pos"] - player["pos"]).normalized()) > 0.0
		_damage_player(dmg, from_front)


func _damage_player(dmg: float, from_front: bool) -> void:
	var key := "shield_f" if from_front else "shield_a"
	var sh: float = float(game[key])
	if sh > 0.0:
		var absorbed := min(sh, dmg)
		game[key] = sh - absorbed
		dmg -= absorbed
		if dmg <= 0.0:
			return
	game["energy"] = float(game["energy"]) - dmg
	if float(game["energy"]) <= 0.0:
		game["energy"] = 0.0
		_player_died()


func _player_died() -> void:
	dead = true
	say("GAME OVER", 999.0)
	died.emit()


func _update_systems(delta: float) -> void:
	if lock_index >= objects.size():
		lock_index = -1


func _update_explosions(delta: float) -> void:
	for i in range(explosions.size() - 1, -1, -1):
		explosions[i]["t"] = float(explosions[i]["t"]) - delta
		if float(explosions[i]["t"]) <= 0.0:
			explosions.remove_at(i)


func _update_missile(o: Dictionary, delta: float) -> void:
	var target: Dictionary = {}
	if int(o["target"]) >= 0 and int(o["target"]) < objects.size():
		target = objects[int(o["target"])]
	if target.is_empty():
		o["life"] = float(o["life"]) - delta
		if float(o["life"]) <= 0.0:
			objects.erase(o)
		return
	var to: Vector3 = target["pos"] - o["pos"]
	if to.length() < 120.0:
		var t_index: int = objects.find(target)
		if t_index >= 0:
			_hit_object(t_index, 120.0)
		explosions.append({"pos": o["pos"], "t": 0.35, "size": 80.0})
		objects.erase(o)
		return
	o["basis"] = Basis.looking_at(to.normalized(), Vector3.UP)
	o["pos"] = o["pos"] + (-o["basis"].z) * 900.0 * delta


# ---------------------------------------------------------------- actions

func launch_missile() -> void:
	if int(game["missiles"]) <= 0:
		say("No missiles")
		return
	if lock_index < 0 or lock_index >= objects.size():
		say("No target locked")
		return
	game["missiles"] = int(game["missiles"]) - 1
	objects.append({
		"role": "missile", "pos": player["pos"] + (-player["basis"].z) * 60.0,
		"basis": player["basis"], "model": EliteShapes.missile(), "size": 25.0,
		"name": "Missile", "speed": 900.0, "max_speed": 900.0, "energy": 1.0,
		"max_energy": 1.0, "bounty": 0.0, "hostile": false, "cd": 0.0,
		"hit_flash": 0.0, "aggression": 0.0, "target": lock_index, "life": 9.0
	})
	say("Missile away")


func lock_target() -> void:
	var fwd: Vector3 = -player["basis"].z
	var best := -1
	var best_ang := 0.5
	for i in objects.size():
		var o: Dictionary = objects[i]
		if o["role"] in ["planet", "sun", "station"]:
			continue
		var rel: Vector3 = o["pos"] - player["pos"]
		var ang := fwd.angle_to(rel.normalized())
		if ang < best_ang:
			best_ang = ang
			best = i
	lock_index = best
	if best >= 0:
		say("Missile locked: " + str(objects[best]["name"]))
	else:
		say("No target")


func enter_witchspace() -> void:
	objects.clear()
	explosions.clear()
	witchspace = true
	witch_t = 30.0
	for i in 2:
		var pos: Vector3 = player["pos"] + Vector3(randf_range(-1300.0, 1300.0), randf_range(-300.0, 300.0), -randf_range(1600.0, 2600.0))
		objects.append({
			"role": "thargoid", "pos": pos, "basis": Basis.looking_at(player["pos"] - pos, Vector3.UP),
			"model": EliteShapes.thargoid(), "size": 170.0, "name": "Thargoid", "speed": 0.0,
			"max_speed": 300.0, "energy": 260.0, "max_energy": 260.0, "bounty": 100.0,
			"hostile": true, "cd": 1.5, "hit_flash": 0.0, "aggression": 0.8
		})
		for k in 2:
			var tp: Vector3 = pos + Vector3(randf_range(-260.0, 260.0), randf_range(-120.0, 120.0), randf_range(-260.0, 260.0))
			objects.append({
				"role": "thargon", "pos": tp, "basis": Basis.looking_at(player["pos"] - tp, Vector3.UP),
				"model": EliteShapes.thargon(), "size": 40.0, "name": "Thargon", "speed": 0.0,
				"max_speed": 420.0, "energy": 18.0, "max_energy": 18.0, "bounty": 0.5,
				"hostile": true, "cd": 2.0, "hit_flash": 0.0, "aggression": 0.9
			})
	say("WITCHSPACE - Thargoids!", 5.0)
	queue_redraw()


func engage_autopilot() -> void:
	autopilot = true
	autopilot_t = 0.0
	say("Docking computer engaged")


func ecm() -> void:
	game["energy"] = max(0.0, float(game["energy"]) - 40.0)
	ecm_t = 1.5
	# the pulse detonates every missile in scanner range
	for i in range(objects.size() - 1, -1, -1):
		if objects[i]["role"] == "missile":
			explosions.append({"pos": objects[i]["pos"], "t": 0.3, "size": 60.0})
			objects.remove_at(i)
	explosions.append({"pos": player["pos"] + (-player["basis"].z) * 200.0, "t": 0.4, "size": 300.0})
	say("E.C.M. active")
	play("beep")


func energy_bomb() -> void:
	if not bool(game["equipment"]["energy_bomb"]):
		say("No energy bomb fitted")
		return
	game["equipment"]["energy_bomb"] = false
	var hits_n := 0
	for i in range(objects.size() - 1, -1, -1):
		var o: Dictionary = objects[i]
		if o["role"] in ["planet", "sun", "station", "canister", "pod"]:
			continue
		if (o["pos"] - player["pos"]).length() < SCANNER_RANGE:
			hits_n += 1
			_destroy_object(i)
	explosions.append({"pos": player["pos"], "t": 0.6, "size": 1200.0})
	play("boom")
	say("Energy bomb detonated: %d ships destroyed" % hits_n)


func in_system_jump() -> void:
	var st := _find_station()
	if st.is_empty():
		return
	for o in objects:
		if bool(o.get("hostile", false)) and (o["pos"] - player["pos"]).length() < SCANNER_RANGE:
			say("Mass locked")
			return
	st["pos"] = player["pos"] + (-player["basis"].z) * 3200.0
	say("In-system jump")
	flight_time += 50.0


# ---------------------------------------------------------------- drawing

func _project(p: Vector3, origin: Vector3, basis: Basis, focal: float, w: float, h: float) -> Vector3:
	var local: Vector3 = basis.transposed() * (p - origin)
	if -local.z <= NEAR:
		return Vector3(0, 0, -1)
	var s: float = focal / (-local.z)
	return Vector3(w * 0.5 + local.x * s, h * 0.5 - local.y * s, -local.z)


func _draw() -> void:
	var w := size.x
	var h := size.y
	var focal := w * FOCAL_RATIO
	var dash_y := h * 0.775
	draw_rect(Rect2(0, 0, w, h), Color(0, 0, 0))

	_draw_stars(w, h, dash_y, focal)
	_draw_objects(w, h, dash_y, focal)
	_draw_flashes(w, h, focal)
	_draw_dashboard(w, h, dash_y)
	_draw_messages(w, h, dash_y)


func _view_basis() -> Basis:
	var b: Basis = player["basis"]
	match view_index:
		1:
			return (b * Basis(Vector3.UP, PI)).orthonormalized()
		2:
			return (b * Basis(Vector3.UP, PI * 0.5)).orthonormalized()
		3:
			return (b * Basis(Vector3.UP, -PI * 0.5)).orthonormalized()
	return b


func set_view(i: int) -> void:
	view_index = clampi(i, 0, 3)
	queue_redraw()


func _draw_stars(w: float, h: float, dash_y: float, focal: float) -> void:
	if not starfield_on:
		return
	var basis: Basis = _view_basis()
	var c := Vector2(w * 0.5, dash_y * 0.5)
	for s in stars:
		var local: Vector3 = basis.transposed() * s["dir"]
		if -local.z <= 0.08:
			continue
		var p := c + Vector2(local.x, -local.y) * (focal * 0.55) / (-local.z)
		if p.y < 4 or p.y > dash_y - 4:
			continue
		var col := Color(1.0, 1.0, 1.0, clamp(float(s["b"]) * 1.6, 0.25, 1.0))
		draw_circle(p, float(s["s"]), col)


func _draw_objects(w: float, h: float, dash_y: float, focal: float) -> void:
	var basis: Basis = _view_basis()
	var origin: Vector3 = player["pos"]
	var centre := Vector2(w * 0.5, dash_y * 0.5)
	var sorted := objects.duplicate()
	sorted.sort_custom(func(a, b):
		return (a["pos"] - origin).length_squared() > (b["pos"] - origin).length_squared())

	for o in sorted:
		var role: String = o["role"]
		if role == "planet":
			var p := _project(o["pos"], origin, basis, focal, w, h)
			if p.z <= 0.0:
				continue
			var pp := Vector2(p.x, p.y)
			var r: float = float(o["radius"]) * focal / p.z
			if r < 0.6:
				draw_circle(pp, 1.5, Color(0.8, 0.8, 0.9))
				continue
			var col := C_WHITE
			# the 1984 machine draws a planet as a bare circle with a meridian
			# and an equator laid across it: no surface fill at all
			draw_arc(pp, r, 0, TAU, 48, col, 1.6, true)
			if r > 6.0:
				var tilt := max(0.10, abs(sin(float(o.get("spin", 0.4)))))
				for i in 48:
					var a0 := TAU * float(i) / 48.0
					var a1 := TAU * float(i + 1) / 48.0
					var pts := [Vector2(cos(a0) * r, sin(a0) * r * tilt), Vector2(cos(a1) * r, sin(a1) * r * tilt)]
					if i % 2 == 0:
						draw_line(pp + pts[0], pp + pts[1], col, 1.2, true)
				# two meridians, drawn as narrow ellipses down the face of the globe
				for mx in [-0.55, 0.55]:
					for i in 24:
						var a0 := TAU * float(i) / 24.0
						var a1 := TAU * float(i + 1) / 24.0
						if i % 2 == 1:
							continue
						var p0 := Vector2(mx * r + cos(a0) * r * 0.42, sin(a0) * r)
						var p1 := Vector2(mx * r + cos(a1) * r * 0.42, sin(a1) * r)
						draw_line(pp + p0, pp + p1, col, 1.0, true)
			continue
		if role == "sun":
			var sp := _project(o["pos"], origin, basis, focal, w, h)
			if sp.z <= 0.0:
				continue
			var spp := Vector2(sp.x, sp.y)
			var sr: float = float(o["radius"]) * focal / sp.z
			if sr < 0.6:
				continue
			draw_circle(spp, sr, C_WHITE)
			continue
		if role == "station":
			var st_model: Dictionary = o.duplicate()
			st_model["basis"] = _station_basis(o)
			_draw_model(st_model, origin, basis, focal, w, h, Color(0.98, 0.98, 0.98), false)
			continue
		var col2 := Color(0.98, 0.98, 0.98)
		if float(o.get("hit_flash", 0.0)) > 0.0:
			col2 = Color(1, 1, 0.6)
		_draw_model(o, origin, basis, focal, w, h, col2, true)

	# explosion puffs
	for ex in explosions:
		var ep := _project(ex["pos"], origin, basis, focal, w, h)
		if ep.z <= 0.0:
			continue
		var er: float = float(ex["size"]) * focal / ep.z * 0.4
		draw_circle(Vector2(ep.x, ep.y), max(2.0, er), Color(1, 0.75, 0.3, clamp(float(ex["t"]) * 2.0, 0.2, 1.0)))

	# locked target box
	if lock_index >= 0 and lock_index < objects.size():
		var t: Dictionary = objects[lock_index]
		var tp := _project(t["pos"], origin, basis, focal, w, h)
		if tp.z > 0.0:
			var tpv := Vector2(tp.x, tp.y)
			var s: float = max(10.0, float(t.get("size", 60.0)) * focal / tp.z * 0.45)
			draw_rect(Rect2(tpv - Vector2(s, s), Vector2(s * 2, s * 2)), Color(1, 0.9, 0.3, 0.8), false, 1.0)


func _draw_model(o: Dictionary, origin: Vector3, cam: Basis, focal: float, w: float, h: float, col: Color, show_if_far: bool) -> void:
	var model: Dictionary = o.get("model", {})
	if model.is_empty():
		return
	var verts: Array = model["v"]
	var edges: Array = model["e"]
	var scale: float = float(o.get("size", 80.0))
	var obj_basis: Basis = o["basis"]
	var pos: Vector3 = o["pos"]
	var pts: Array = []
	var visible := false
	for v in verts:
		var wp: Vector3 = pos + obj_basis * (v * scale)
		var p := _project(wp, origin, cam, focal, w, h)
		pts.append(p)
		if p.z > 0.0:
			visible = true
	if not visible:
		return
	for e in edges:
		var a: Vector3 = pts[e.x]
		var b: Vector3 = pts[e.y]
		if a.z > 0.0 and b.z > 0.0:
			draw_line(Vector2(a.x, a.y), Vector2(b.x, b.y), col, 1.4, true)


func _draw_flashes(w: float, h: float, focal: float) -> void:
	if laser_flash <= 0.0:
		return
	var c := Vector2(w * 0.5, h * 0.35)
	var col := Color(1, 0.95, 0.6, 0.9)
	for dir in [Vector2(-1, -0.35), Vector2(1, -0.35), Vector2(-1, 0.35), Vector2(1, 0.35)]:
		draw_line(c + dir.normalized() * 16.0, c + dir.normalized() * 46.0, col, 2.0)


func _draw_crosshair(w: float, h: float, dash_y: float) -> void:
	var c := Vector2(w * 0.5, dash_y * 0.5)
	var col := Color(0.92, 0.96, 1.0)
	draw_line(c + Vector2(-26, 0), c + Vector2(-9, 0), col, 1.0)
	draw_line(c + Vector2(9, 0), c + Vector2(26, 0), col, 1.0)
	draw_line(c + Vector2(0, -22), c + Vector2(0, -8), col, 1.0)
	draw_line(c + Vector2(0, 8), c + Vector2(0, 22), col, 1.0)


func _draw_messages(w: float, h: float, dash_y: float) -> void:
	# the viewport is labelled top-centre, as the original does
	draw_string(font, Vector2(0, h * 0.05), VIEW_NAMES[view_index], HORIZONTAL_ALIGNMENT_CENTER,
		w, int(clamp(h * 0.028, 12.0, 22.0)), C_WHITE)

	if msg_t > 0.0 and msg != "":
		draw_string(font, Vector2(w * 0.5 - 400, dash_y - h * 0.022), msg,
			HORIZONTAL_ALIGNMENT_CENTER, 800, int(clamp(h * 0.026, 11.0, 20.0)), C_YELLOW)

	# mass lock warning sits on the canopy edge, where the original puts it
	var locked := false
	for o in objects:
		if bool(o.get("hostile", false)) and (o["pos"] - player["pos"]).length() < SCANNER_RANGE:
			locked = true
	if locked:
		draw_string(font, Vector2(w * 0.5 - 200, dash_y - h * 0.004), "MASS LOCKED",
			HORIZONTAL_ALIGNMENT_CENTER, 400, int(clamp(h * 0.022, 10.0, 16.0)), C_RED)



# One gauge of the cockpit, drawn the way the 1984 machine draws it: a two
# letter label in red, a solid yellow bar whose length is the level, and a
# dashed green tick line under it.
func _gauge(px: float, py: float, bw: float, rh: float, frac: float, label: String, label_left: bool) -> void:
	frac = clamp(frac, 0.0, 1.0)
	var bh: float = max(3.0, rh * 0.054)
	var fs := int(clamp(rh * 0.42, 8.0, 20.0))
	var ty: float = py + rh * 0.30
	if label_left:
		draw_string(font, Vector2(px - bw * 0.50, ty), label,
			HORIZONTAL_ALIGNMENT_RIGHT, bw * 0.47, fs, C_RED)
	else:
		draw_string(font, Vector2(px + bw + bw * 0.055, ty), label,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fs, C_RED)
	if frac > 0.001:
		draw_rect(Rect2(px, py + rh * 0.13, bw * frac, bh), C_YELLOW)
	# dashed green tick line along the bottom of the gauge
	var ty0: float = py + rh * 0.107
	var th: float = max(1.0, rh * 0.045)
	var dash: float = max(2.0, bw * 0.035)
	var x := px
	while x < px + bw:
		draw_rect(Rect2(x, ty0, min(dash, px + bw - x), th), C_GREEN)
		x += dash * 2.0


func _dash_line(x0: float, y0: float, x1: float, y1: float, seg: float, th: float) -> void:
	# alternating white / yellow blocks: the canopy edge of the original cockpit
	var horiz := absf(y1 - y0) < 0.5
	var len: float = absf(x1 - x0) if horiz else absf(y1 - y0)
	var n := int(ceil(len / seg))
	for i in n:
		var a: float = float(i) * seg
		var b: float = min(a + seg, len)
		var col := C_WHITE if i % 2 == 0 else C_YELLOW
		if horiz:
			draw_rect(Rect2(x0 + a, y0, b - a, th), col)
		else:
			draw_rect(Rect2(x0, y0 + a, th, b - a), col)


func _draw_dashboard(w: float, h: float, dash_y: float) -> void:
	hud_draws += 1
	var d := h - dash_y
	draw_rect(Rect2(0, dash_y, w, d), Color(0, 0, 0))
	# canopy edge: alternating white and yellow blocks, as in the original
	_dash_line(0.0, dash_y, w, dash_y, max(4.0, w * 0.0156), max(2.0, h * 0.0055))
	# bottom rail and the two instrument dividers, in solid yellow
	draw_rect(Rect2(0, h - max(2.0, h * 0.008), w, max(2.0, h * 0.008)), C_YELLOW)
	draw_rect(Rect2(0, dash_y, max(2.0, w * 0.004), d), C_YELLOW)
	draw_rect(Rect2(w - max(2.0, w * 0.004), dash_y, max(2.0, w * 0.004), d), C_YELLOW)
	for fx in [0.1875, 0.805]:
		draw_rect(Rect2(w * fx, dash_y + h * 0.008, max(2.0, w * 0.004), d - h * 0.011), C_YELLOW)

	# keep the first row clear of the canopy edge and the last clear of the rail
	var pad_top: float = max(4.0, h * 0.009)
	var pad_bot: float = max(2.0, h * 0.009)
	var rh := (d - pad_top - pad_bot) / 7.0
	var row0: float = dash_y + pad_top

	var sun := _find_role("sun")
	var pl := _find_role("planet")
	var sun_d := 999999.0
	if not sun.is_empty():
		sun_d = (sun["pos"] - player["pos"]).length()
	cabin_temp = clamp(600000.0 / max(40000.0, sun_d) * 42.0, 4.0, 255.0)
	var alt := 0.0
	if not pl.is_empty():
		var pd: float = (pl["pos"] - player["pos"]).length()
		alt = clamp(1.0 - (pd - float(pl["radius"])) / 400000.0, 0.0, 1.0)

	# ---- left column: the six flight gauges, then the missiles
	var lx := w * 0.0625
	var lw := w * 0.1135
	var labels := ["FS", "AS", "FU", "CT", "LT", "AL"]
	var fracs := [
		float(game["shield_f"]) / 255.0,
		float(game["shield_a"]) / 255.0,
		float(game["fuel"]) / 7.0,
		cabin_temp / 255.0,
		laser_temp / 240.0,
		alt
	]
	for i in 6:
		_gauge(lx, row0 + rh * i, lw, rh, fracs[i], labels[i], true)

	# missile blocks: solid green slots in the bottom row of the left column
	var mcount := int(game["missiles"])
	var mw := w * 0.0234
	var my := row0 + rh * 6.0 + rh * 0.12
	for i in 4:
		if i < mcount:
			draw_rect(Rect2(w * 0.09375 + i * w * 0.03125, my, mw, rh * 0.55), C_GREEN)

	# ---- right column: speed, roll, climb, four energy banks
	var rxb := w * 0.8125
	var rwb := w * 0.1255
	var en: float = float(game["energy"])
	var emax: float = max(1.0, float(game["energy_max"]))
	var bank := emax / 4.0
	var rlabels := ["SP", "RL", "DC", "1", "2", "3", "4"]
	var rfracs := [
		float(player["speed"]) / 350.0,
		clamp(0.5 + roll_rate / 4.0, 0.0, 1.0),
		clamp(0.5 + pitch_rate / 2.5, 0.0, 1.0),
		clamp(en / bank, 0.0, 1.0),
		clamp((en - bank) / bank, 0.0, 1.0),
		clamp((en - bank * 2.0) / bank, 0.0, 1.0),
		clamp((en - bank * 3.0) / bank, 0.0, 1.0)
	]
	for i in 7:
		_gauge(rxb, row0 + rh * i, rwb, rh, rfracs[i], rlabels[i], false)

	# ---- centre: scanner
	draw_scanner(w, h, dash_y)

	# the wordmark in the middle of the dashboard, as on the original cockpit
	draw_string(font, Vector2(0, h - max(1.0, d * 0.03)), "ELITE", HORIZONTAL_ALIGNMENT_CENTER,
		w, int(clamp(d * 0.105, 10.0, 26.0)), C_GREEN)


func _find_role(role: String) -> Dictionary:
	for o in objects:
		if o["role"] == role:
			return o
	return {}


func draw_scanner(w: float, h: float, dash_y: float) -> void:
	var cx := w * 0.498
	var cy := dash_y + (h - dash_y) * 0.527
	var rx := w * 0.268
	var ry := (h - dash_y) * 0.3125
	# the flat elliptical dish, drawn as dashes in red like the original
	var lw: float = max(1.5, h * 0.0035)
	for i in 48:
		if i % 2 == 1:
			continue
		var a0 := TAU * float(i) / 48.0
		var a1 := TAU * float(i + 1) / 48.0
		draw_line(Vector2(cx + cos(a0) * rx, cy + sin(a0) * ry),
			Vector2(cx + cos(a1) * rx, cy + sin(a1) * ry), C_RED, lw)
	# the two axes, also dashed
	var n := 15
	for i in n:
		if i % 2 == 1:
			continue
		var f0: float = -1.0 + 2.0 * float(i) / float(n)
		var f1: float = -1.0 + 2.0 * float(i + 1) / float(n)
		draw_line(Vector2(cx + rx * f0, cy), Vector2(cx + rx * f1, cy), C_RED, lw * 0.8)
		draw_line(Vector2(cx, cy + ry * f0), Vector2(cx, cy + ry * f1), C_RED, lw * 0.8)

	var cam: Basis = player["basis"]
	var origin: Vector3 = player["pos"]
	for o in objects:
		var role: String = o["role"]
		if role in ["planet", "sun"]:
			continue
		var rel: Vector3 = cam.transposed() * (o["pos"] - origin)
		if rel.length() > SCANNER_RANGE:
			continue
		var nx: float = float(rel.x) / SCANNER_RANGE
		var nz: float = float(rel.z) / SCANNER_RANGE
		var ny: float = float(rel.y) / SCANNER_RANGE
		var rr: float = sqrt(nx * nx + nz * nz)
		if rr > 0.97:
			nx = nx / rr * 0.97
			nz = nz / rr * 0.97
		var px: float = cx + nx * rx
		var py: float = cy + nz * ry
		var col := Color(0.98, 0.98, 0.98)
		if role == "station":
			col = Color(0.0, 1.0, 0.0)
		var stick: float = clamp(abs(ny) * 40.0, 3.0, ry * 0.95)
		if ny >= 0.0:
			draw_line(Vector2(px, py), Vector2(px, py - stick), col, 2.0)
		else:
			draw_line(Vector2(px, py), Vector2(px, py + stick), col, 2.0)
		draw_rect(Rect2(px - 1.5, py - 1.5, 3, 3), col)

	# station finder: the compass rose in the middle of the dish
	var st := _find_station()
	if not st.is_empty():
		var to: Vector3 = cam.transposed() * (st["pos"] - origin)
		draw_circle(Vector2(cx, cy), 4.0, Color(0.98, 0.98, 0.98))
		if to.length() > 1.0:
			var d := Vector2(to.x, -to.z).normalized()
			draw_line(Vector2(cx, cy), Vector2(cx, cy) + d * 16.0, Color(1.0, 1.0, 0.0), 2.0)

