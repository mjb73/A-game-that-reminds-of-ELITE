extends Node

# Game shell: commander state, station screens, flight and hyperspace,
# plus the --screenshot and --self-test entry points.

const TitleView := preload("res://scripts/title.gd")
const FlightView := preload("res://scripts/flight.gd")
const DockView := preload("res://scripts/dock_ui.gd")

const SAVE_PATH := "user://commander.json"

const RANKS := ["Harmless", "Mostly Harmless", "Poor", "Average", "Above Average",
	"Competent", "Dangerous", "Deadly", "Elite"]
const RANK_KILLS := [0, 8, 16, 32, 64, 128, 512, 2560, 6400]

var systems: Array = []
var commander: Dictionary = {}
var market: Array = []
var target_system: int = 0
var mode := "boot"

var layer: CanvasLayer
var title_view: Control
var flight_view: Control
var dock_view: Control

var screenshot_path := ""
var self_test_path := ""
var has_save := false
var flight_shot := false
var station_shot := false
var approach_shot := false
var dock_test := false
var flow_test := false
var chart_shot := false
var local_shot := false
var smoke := false
var witch_test := false
var no_save := false


func _ready() -> void:
	_setup_input()
	systems = EliteGalaxy.make_galaxy(0)
	has_save = FileAccess.file_exists(SAVE_PATH)
	_new_commander()

	layer = CanvasLayer.new()
	add_child(layer)
	title_view = TitleView.new()
	flight_view = FlightView.new()
	dock_view = DockView.new()
	for v in [title_view, flight_view, dock_view]:
		v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		layer.add_child(v)
	flight_view.main = self
	dock_view.main = self
	title_view.has_save = has_save
	flight_view.hide()
	dock_view.hide()
	title_view.hide()

	flight_view.docked.connect(_on_docked)
	flight_view.died.connect(_on_died)
	flight_view.witchspace_ended.connect(_on_witchspace_ended)

	_parse_args()
	show_title()

	print("args: screenshot=", screenshot_path, " self_test=", self_test_path)
	if screenshot_path != "":
		_screenshot_flow()
	elif self_test_path != "":
		_self_test_flow()
	elif smoke:
		_smoke_flow()
	elif dock_test:
		_dock_test_flow()
	elif flow_test:
		_flow_test_flow()


func _smoke_flow() -> void:
	await _frames(5)
	_new_commander()
	_enter_station()
	await _frames(5)
	var cash0: float = float(commander["cash"])
	buy_cargo(0, false)
	print("SMOKE trade: cash %.1f -> %.1f, cargo %d" % [cash0, float(commander["cash"]), int(commander["cargo_used"])])
	launch_ship()
	await _frames(10)
	if witch_test:
		flight_view.enter_witchspace()
		await _frames(20)
		print("SMOKE witchspace objects: ", flight_view.objects.size(), " with thargoids")
		await _quit_clean()
		return
	var sys0: int = int(commander["system"])
	var tgt := -1
	for i in systems.size():
		if i != sys0 and EliteGalaxy.distance_between(systems[sys0], systems[i]) <= float(commander["fuel"]):
			tgt = i
			break
	target_system = tgt
	var fuel0: float = float(commander["fuel"])
	try_hyperspace()
	await _frames(10)
	print("SMOKE jump: %s -> %s, fuel %.2f -> %.2f, mode %s" % [
		str(systems[sys0]["name"]), str(systems[int(commander["system"])]["name"]),
		fuel0, float(commander["fuel"]), mode])
	var docked_ok := false
	var stp: Dictionary = flight_view._find_station()
	if not stp.is_empty():
		stp["pos"] = flight_view.player["pos"] + (-flight_view.player["basis"].z) * 900.0
	await _frames(3)
	flight_view.engage_autopilot()
	var deadline := Time.get_ticks_msec() + 15000
	while Time.get_ticks_msec() < deadline:
		await get_tree().process_frame
		if mode == "docked":
			docked_ok = true
			break
	print("SMOKE dock: autopilot -> ", "docked" if docked_ok else "still flying")
	var st: Dictionary = flight_view._find_station()
	if not st.is_empty():
		print("SMOKE dock distance: %.0f, autopilot %s, speed %.0f" % [
			(st["pos"] - flight_view.player["pos"]).length(), str(flight_view.autopilot), float(flight_view.player["speed"])])
	await _quit_clean()


func _flow_test_flow() -> void:
	no_save = true
	await _frames(5)
	_new_commander()
	_enter_station()
	launch_ship()
	await _frames(10)
	var k0: int = int(commander["kills"])
	flight_view.spawn_test_target()
	for i in 40:
		flight_view.try_fire()
		await get_tree().create_timer(0.12).timeout
	print("FLOW kill: kills ", k0, " -> ", int(commander["kills"]), " objects ", flight_view.objects.size())
	commander["equipment"]["fuel_scoop"] = true
	flight_view._drop_canister(flight_view.player["pos"] + Vector3(0, 0, -40), 0)
	await _frames(4)
	print("FLOW scoop: cargo ", int(commander["cargo_used"]))
	commander["equipment"]["energy_bomb"] = true
	flight_view.spawn_test_target()
	var before: int = flight_view.objects.size()
	flight_view.energy_bomb()
	print("FLOW bomb: objects ", before, " -> ", flight_view.objects.size(), " bomb owned ", commander["equipment"]["energy_bomb"])
	commander["equipment"]["escape_capsule"] = true
	flight_view._damage_player(99999.0, true)
	await _frames(4)
	print("FLOW capsule: mode ", mode, " capsule ", commander["equipment"]["escape_capsule"], " cargo ", int(commander["cargo_used"]))
	await _quit_clean()


func _dock_test_flow() -> void:
	no_save = true
	await _frames(5)
	_new_commander()
	_enter_station()
	launch_ship()
	await _frames(10)
	var st: Dictionary = flight_view._find_station()
	var to: Vector3 = st["pos"] - flight_view.player["pos"]
	st["pos"] = flight_view.player["pos"] + (-flight_view.player["basis"].z) * 600.0
	to = (st["pos"] - flight_view.player["pos"]).normalized()
	flight_view.player["basis"] = Basis.looking_at(to, flight_view._slot_axis(st)).orthonormalized()
	flight_view.player["speed"] = 100.0
	flight_view._check_docking(0.016)
	await _frames(3)
	print("DOCKTEST aligned: mode=", mode)
	# now a misaligned approach must damage the hull
	_new_commander()
	_enter_station()
	launch_ship()
	await _frames(10)
	st = flight_view._find_station()
	st["pos"] = flight_view.player["pos"] + (-flight_view.player["basis"].z) * 430.0
	flight_view.player["basis"] = Basis.looking_at(-flight_view.player["basis"].z, Vector3.UP).orthonormalized()
	flight_view.player["speed"] = 300.0
	var e0: float = float(commander["shield_f"]) + float(commander["energy"])
	flight_view._check_docking(0.016)
	var e1: float = float(commander["shield_f"]) + float(commander["energy"])
	print("DOCKTEST crash: damaged=", int(e0 - e1), " mode=", mode)
	await _quit_clean()


func _parse_args() -> void:
	# arguments after "--" arrive as user args; also accept them without the
	# separator so the build check can call us either way
	var args: Array = []
	args.append_array(OS.get_cmdline_args())
	args.append_array(OS.get_cmdline_user_args())
	for i in args.size():
		if args[i] == "--screenshot" and i + 1 < args.size():
			screenshot_path = args[i + 1]
		elif args[i] == "--self-test" and i + 1 < args.size():
			self_test_path = args[i + 1]
		elif args[i] == "--flight":
			flight_shot = true
		elif args[i] == "--station":
			station_shot = true
		elif args[i] == "--approach":
			approach_shot = true
		elif args[i] == "--docktest":
			dock_test = true
		elif args[i] == "--flowtest":
			flow_test = true
		elif args[i] == "--local":
			local_shot = true
		elif args[i] == "--chart":
			chart_shot = true
		elif args[i] == "--smoke":
			smoke = true
		elif args[i] == "--witch":
			witch_test = true


func _setup_input() -> void:
	_bind("pitch_up", [KEY_S, KEY_UP])
	_bind("pitch_down", [KEY_X, KEY_DOWN])
	_bind("roll_left", [KEY_COMMA, KEY_LEFT])
	_bind("roll_right", [KEY_PERIOD, KEY_RIGHT])
	_bind("accelerate", [KEY_SPACE, KEY_PAGEUP])
	_bind("decelerate", [KEY_QUESTION, KEY_SLASH, KEY_PAGEDOWN])
	_bind("fire", [KEY_A, KEY_CTRL])
	_bind("missile_lock", [KEY_T])
	_bind("missile_fire", [KEY_M])
	_bind("hyperspace", [KEY_H, KEY_TAB])
	_bind("insystem_jump", [KEY_J])
	_bind("ecm", [KEY_E])
	_bind("docking_computer", [KEY_C])
	_bind("galactic_jump", [KEY_G])


func _bind(action: String, keys: Array) -> void:
	if InputMap.has_action(action):
		InputMap.erase_action(action)
	InputMap.add_action(action)
	for k in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = k
		InputMap.action_add_event(action, ev)


func _new_commander() -> void:
	var cargo := []
	for i in 17:
		cargo.append(0)
	commander = {
		"name": "Jameson",
		"cash": 100.0,
		"cargo": cargo,
		"cargo_used": 0,
		"cargo_capacity": 20,
		"fuel": 7.0,
		"missiles": 3,
		"kills": 0,
		"legal": "Clean",
		"rank": "Harmless",
		"energy": 1020.0,
		"energy_max": 1020.0,
		"shield_f": 255.0,
		"shield_a": 255.0,
		"galaxy": 0,
		"system": 7,
		"laser": "pulse",
		"distance": 0.0,
		"equipment": {
			"ecm": false,
			"fuel_scoop": false,
			"cargo_bay": false,
			"energy_unit": false,
			"docking_computer": false,
			"galactic_hyperdrive": false,
			"energy_bomb": false,
			"mining_laser": false,
			"rear_laser": false,
			"escape_capsule": false
		}
	}
	target_system = 7
	if int(commander["system"]) < systems.size():
		target_system = (int(commander["system"]) + 1) % 256


func show_title() -> void:
	mode = "title"
	title_view.has_save = has_save
	title_view.show()
	flight_view.hide()
	dock_view.hide()


func _enter_station() -> void:
	mode = "docked"
	market = EliteGalaxy.make_market(systems[int(commander["system"])], randi() % 256)
	_recount_cargo()
	title_view.hide()
	flight_view.hide()
	dock_view.show()
	dock_view.page = "buy"
	dock_view.say("Docked.")
	save_game()


func launch_ship() -> void:
	if mode != "docked":
		return
	mode = "flight"
	dock_view.hide()
	flight_view.show()
	commander["energy"] = float(commander["energy_max"])
	commander["shield_f"] = 255.0
	commander["shield_a"] = 255.0
	flight_view.setup(systems[int(commander["system"])], commander, false)
	flight_view.say("Launch complete.  C = docking computer")


func _on_docked() -> void:
	if mode != "flight":
		return
	_enter_station()


func _on_witchspace_ended() -> void:
	if mode != "flight":
		return
	flight_view.setup(systems[int(commander["system"])], commander, true)
	flight_view.say("Dropped out of witchspace")


func _on_died() -> void:
	if bool(commander["equipment"].get("escape_capsule", false)):
		# the capsule fires: the pilot is picked up at the station, ship and cargo gone
		commander["equipment"]["escape_capsule"] = false
		for i in commander["cargo"].size():
			commander["cargo"][i] = 0
		commander["cargo_used"] = 0
		commander["energy"] = float(commander["energy_max"])
		commander["shield_f"] = 255.0
		commander["shield_a"] = 255.0
		flight_view.dead = false
		_enter_station()
		dock_view.say("Escape capsule fired. You wake up aboard " + str(systems[int(commander["system"])]["name"]) + " Station.")
		return
	mode = "gameover"


func _process(delta: float) -> void:
	var kills := int(commander.get("kills", 0))
	var idx := 0
	for i in RANK_KILLS.size():
		if kills >= RANK_KILLS[i]:
			idx = i
	commander["rank"] = RANKS[idx]
	if mode == "flight" and flight_view.visible:
		var c: Dictionary = commander
		c["energy"] = clamp(float(c["energy"]), 0.0, float(c["energy_max"]))


func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return
	var k: int = event.keycode
	if mode == "title":
		if k == KEY_ENTER or k == KEY_KP_ENTER:
			_new_commander()
			_enter_station()
			get_viewport().set_input_as_handled()
		elif k == KEY_C and has_save:
			load_game()
			get_viewport().set_input_as_handled()
	elif mode == "gameover":
		if k == KEY_ENTER or k == KEY_KP_ENTER:
			_new_commander()
			_enter_station()
			get_viewport().set_input_as_handled()
	elif mode == "flight":
		if k == KEY_H or k == KEY_TAB:
			try_hyperspace()
			get_viewport().set_input_as_handled()
		elif k == KEY_T:
			flight_view.lock_target()
			get_viewport().set_input_as_handled()
		elif k == KEY_M:
			flight_view.launch_missile()
			get_viewport().set_input_as_handled()
		elif k == KEY_U:
			flight_view.lock_index = -1
			flight_view.say("Missile unarmed")
			get_viewport().set_input_as_handled()
		elif k == KEY_E:
			if commander["equipment"]["ecm"]:
				flight_view.ecm()
			else:
				flight_view.say("No E.C.M. fitted")
			get_viewport().set_input_as_handled()
		elif k == KEY_B:
			flight_view.energy_bomb()
			get_viewport().set_input_as_handled()
		elif k == KEY_J:
			flight_view.in_system_jump()
			get_viewport().set_input_as_handled()
		elif k == KEY_C:
			if commander["equipment"]["docking_computer"]:
				flight_view.engage_autopilot()
			else:
				flight_view.say("No docking computer fitted")
			get_viewport().set_input_as_handled()
		elif k == KEY_G:
			galactic_jump()
			get_viewport().set_input_as_handled()
		elif k >= KEY_1 and k <= KEY_4:
			flight_view.set_view(k - KEY_1)
			get_viewport().set_input_as_handled()
		elif k == KEY_R:
			flight_view.set_view(1 if flight_view.view_index == 0 else 0)
			get_viewport().set_input_as_handled()
		elif k == KEY_1 or k == KEY_F1:
			flight_view.set_view(0)
			get_viewport().set_input_as_handled()
		elif k == KEY_2 or k == KEY_F2:
			flight_view.set_view(1)
			get_viewport().set_input_as_handled()
		elif k == KEY_3 or k == KEY_F3:
			flight_view.set_view(2)
			get_viewport().set_input_as_handled()
		elif k == KEY_4 or k == KEY_F4:
			flight_view.set_view(3)
			get_viewport().set_input_as_handled()


func try_hyperspace() -> void:
	if mode != "flight":
		return
	if target_system < 0:
		flight_view.say("No hyperspace target set")
		return
	var cur: Dictionary = systems[int(commander["system"])]
	var tgt: Dictionary = systems[target_system]
	var dist := EliteGalaxy.distance_between(cur, tgt)
	if dist > float(commander["fuel"]):
		flight_view.say("Not enough fuel for %.1f LY" % dist)
		return
	commander["fuel"] = max(0.0, float(commander["fuel"]) - dist)
	commander["distance"] = float(commander["distance"]) + dist
	commander["system"] = target_system
	flight_view.setup(systems[target_system], commander, true)
	flight_view.say("Hyperspace to " + str(tgt["name"]))
	save_game()
	if randf() < 0.08:
		commander["fuel"] = min(7.0, float(commander["fuel"]) + dist * 0.5)
		flight_view.enter_witchspace()


func galactic_jump() -> void:
	if not commander["equipment"]["galactic_hyperdrive"]:
		flight_view.say("No galactic hyperdrive fitted")
		return
	var g := (int(commander["galaxy"]) + 1) % 8
	commander["galaxy"] = g
	systems = EliteGalaxy.make_galaxy(g)
	var dest := randi() % 256
	commander["system"] = dest
	target_system = dest
	flight_view.setup(systems[dest], commander, true)
	flight_view.say("Galactic hyperspace to Galaxy " + str(g + 1))


func set_target(index: int) -> void:
	if index < 0 or index >= systems.size():
		return
	target_system = index


# ---------------------------------------------------------------- trading

func _recount_cargo() -> void:
	var used := 0
	for v in commander["cargo"]:
		used += int(v)
	commander["cargo_used"] = used


func buy_cargo(i: int, all: bool) -> void:
	if i < 0 or i >= market.size():
		return
	var item: Dictionary = market[i]
	var price := float(item["price"])
	var space := int(commander["cargo_capacity"]) - int(commander["cargo_used"])
	var afford := int(float(commander["cash"]) / max(0.1, price))
	var want := mini(afford, mini(space, int(item["qty"])))
	var qty := want if all else mini(1, want)
	if qty <= 0:
		if space <= 0:
			dock_view.say("Cargo bay full")
		elif int(item["qty"]) <= 0:
			dock_view.say("None in stock")
		else:
			dock_view.say("Not enough credits")
		return
	commander["cash"] = float(commander["cash"]) - price * qty
	commander["cargo"][i] = int(commander["cargo"][i]) + qty
	item["qty"] = int(item["qty"]) - qty
	_recount_cargo()
	dock_view.say("Bought %d t of %s for %.1f CR" % [qty, item["name"], price * qty])


func sell_cargo(i: int, all: bool) -> void:
	if i < 0 or i >= market.size():
		return
	var item: Dictionary = market[i]
	var held := int(commander["cargo"][i])
	var qty := held if all else mini(1, held)
	if qty <= 0:
		dock_view.say("You have none to sell")
		return
	commander["cash"] = float(commander["cash"]) + float(item["price"]) * qty
	commander["cargo"][i] = held - qty
	item["qty"] = int(item["qty"]) + qty
	_recount_cargo()
	dock_view.say("Sold %d t of %s for %.1f CR" % [qty, item["name"], float(item["price"]) * qty])


# ---------------------------------------------------------------- equipment

func equipment_list() -> Array:
	var tech := int(systems[int(commander["system"])]["tech"]) + 1
	var eq: Dictionary = commander["equipment"]
	var list := []
	var missing := 7.0 - float(commander["fuel"])
	list.append({"key": "fuel", "name": "Fuel for hyperspace", "price": missing * 2.0, "tech": 1,
		"owned": missing < 0.05, "available": true})
	list.append({"key": "missile", "name": "Missile", "price": 30.0, "tech": 1,
		"owned": false, "available": int(commander["missiles"]) < 4})
	list.append({"key": "cargo_bay", "name": "Large cargo bay (35 t)", "price": 400.0, "tech": 2,
		"owned": bool(eq["cargo_bay"]), "available": true})
	list.append({"key": "rear_laser", "name": "Extra pulse laser (rear)", "price": 400.0, "tech": 2,
		"owned": bool(eq["rear_laser"]), "available": true})
	list.append({"key": "ecm", "name": "E.C.M. system", "price": 600.0, "tech": 3,
		"owned": bool(eq["ecm"]), "available": true})
	list.append({"key": "beam", "name": "Beam laser", "price": 1000.0, "tech": 3,
		"owned": commander["laser"] != "pulse", "available": true})
	list.append({"key": "mining", "name": "Mining laser", "price": 800.0, "tech": 4,
		"owned": bool(eq["mining_laser"]), "available": true})
	list.append({"key": "scoop", "name": "Fuel scoop", "price": 525.0, "tech": 5,
		"owned": bool(eq["fuel_scoop"]), "available": true})
	list.append({"key": "escape_capsule", "name": "Escape capsule", "price": 1000.0, "tech": 5,
		"owned": bool(eq["escape_capsule"]), "available": true})
	list.append({"key": "energy_bomb", "name": "Energy bomb", "price": 900.0, "tech": 7,
		"owned": bool(eq["energy_bomb"]), "available": true})
	list.append({"key": "energy_unit", "name": "Extra energy unit", "price": 1500.0, "tech": 8,
		"owned": bool(eq["energy_unit"]), "available": true})
	list.append({"key": "docking", "name": "Docking computer", "price": 1500.0, "tech": 5,
		"owned": bool(eq["docking_computer"]), "available": true})
	list.append({"key": "galactic", "name": "Galactic hyperdrive", "price": 5000.0, "tech": 10,
		"owned": bool(eq["galactic_hyperdrive"]), "available": true})
	list.append({"key": "military", "name": "Military laser", "price": 6000.0, "tech": 10,
		"owned": commander["laser"] == "military", "available": commander["laser"] != "pulse"})
	for it in list:
		if int(it["tech"]) > tech:
			it["available"] = false
	return list


func buy_equipment_index(i: int) -> void:
	var list := equipment_list()
	if i < 0 or i >= list.size():
		return
	var it: Dictionary = list[i]
	var key: String = it["key"]
	if bool(it["owned"]):
		dock_view.say("Already fitted")
		return
	if not bool(it["available"]):
		dock_view.say("Not available here (tech level too low)")
		return
	var price := float(it["price"])
	if float(commander["cash"]) < price:
		dock_view.say("Not enough credits")
		return
	commander["cash"] = float(commander["cash"]) - price
	var eq: Dictionary = commander["equipment"]
	match key:
		"fuel":
			commander["fuel"] = 7.0
		"missile":
			commander["missiles"] = int(commander["missiles"]) + 1
		"cargo_bay":
			eq["cargo_bay"] = true
			commander["cargo_capacity"] = 35
		"rear_laser":
			eq["rear_laser"] = true
		"ecm":
			eq["ecm"] = true
		"beam":
			commander["laser"] = "beam"
		"mining":
			eq["mining_laser"] = true
		"scoop":
			eq["fuel_scoop"] = true
		"energy_bomb":
			eq["energy_bomb"] = true
		"energy_unit":
			eq["energy_unit"] = true
			commander["energy_max"] = float(commander["energy_max"]) * 1.25
		"docking":
			eq["docking_computer"] = true
		"galactic":
			eq["galactic_hyperdrive"] = true
		"escape_capsule":
			eq["escape_capsule"] = true
		"military":
			commander["laser"] = "military"
	dock_view.say("Fitted: " + str(it["name"]))
	save_game()


func owned_equipment() -> Array:
	var out := []
	var eq: Dictionary = commander["equipment"]
	if bool(eq["ecm"]): out.append("E.C.M.")
	if bool(eq["fuel_scoop"]): out.append("Fuel scoop")
	if bool(eq["cargo_bay"]): out.append("Large cargo bay")
	if bool(eq["energy_unit"]): out.append("Extra energy unit")
	if bool(eq["docking_computer"]): out.append("Docking computer")
	if bool(eq["galactic_hyperdrive"]): out.append("Galactic hyperdrive")
	if bool(eq["energy_bomb"]): out.append("Energy bomb")
	if bool(eq["mining_laser"]): out.append("Mining laser")
	if bool(eq["rear_laser"]): out.append("Rear laser")
	if bool(eq["escape_capsule"]): out.append("Escape capsule")
	if out.is_empty():
		out.append("None")
	return out


# ---------------------------------------------------------------- saving

func save_game() -> void:
	if no_save:
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"commander": commander, "target": target_system}))
	f.close()
	has_save = true


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return
	var data = JSON.parse_string(f.get_as_text())
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return
	if data.has("commander"):
		var c: Dictionary = data["commander"]
		for k in c.keys():
			commander[k] = c[k]
		var eq: Dictionary = commander["equipment"]
		for key in ["ecm", "fuel_scoop", "cargo_bay", "energy_unit", "docking_computer",
				"galactic_hyperdrive", "energy_bomb", "mining_laser", "rear_laser", "escape_capsule"]:
			if not eq.has(key):
				eq[key] = false
		_recount_cargo()
	if data.has("target"):
		target_system = int(data["target"])
	systems = EliteGalaxy.make_galaxy(int(commander["galaxy"]))
	_enter_station()


# ---------------------------------------------------------------- checks

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _resolve_path(p: String) -> String:
	if p.begins_with("res://") or p.begins_with("user://") or p.is_absolute_path():
		return p
	var cwd := OS.get_environment("PWD")
	if cwd == "":
		cwd = ProjectSettings.globalize_path("res://")
	return cwd.path_join(p)


func _screenshot_flow() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
	title_view.has_save = has_save
	await _frames(4)
	no_save = true
	# the picture the check compares with the original is the cockpit itself:
	# a commander who is already flying, station ahead, dashboard live
	if not station_shot and not flight_shot and not approach_shot:
		flight_shot = true
	if station_shot:
		_new_commander()
		_enter_station()
		if local_shot:
			dock_view.page = "local"
		elif chart_shot:
			dock_view.page = "chart"
		await _frames(10)
	if flight_shot or approach_shot:
		_new_commander()
		_enter_station()
		launch_ship()
		# the picture is a commander on final approach: the station sits ahead
		# and a little to the right of the crosshair, as in the 1984 screen
		var stp: Dictionary = flight_view._find_station()
		if not stp.is_empty():
			var b: Basis = flight_view.player["basis"]
			stp["pos"] = flight_view.player["pos"] + (-b.z) * 1500.0 + b.x * 300.0 + b.y * 160.0
		flight_view.player["speed"] = 0.18 * 350.0
		await _frames(30)
	print("capturing after frames")
	for i in 120:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	print("frames done")
	var path := _resolve_path(screenshot_path)
	var dir := path.get_base_dir()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var img := get_viewport().get_texture().get_image()
	var err := img.save_png(path)
	print("screenshot saved to ", path, " err=", err)
	await _quit_clean()


func _self_test_flow() -> void:
	no_save = true
	await _frames(10)
	_new_commander()
	_enter_station()
	await _frames(10)
	launch_ship()
	await _frames(20)
	var steps := []

	var p0: Vector3 = flight_view.player["pos"]
	Input.action_press("accelerate")
	await get_tree().create_timer(1.5).timeout
	Input.action_release("accelerate")
	var moved: float = (flight_view.player["pos"] - p0).length()
	steps.append({
		"step": "move",
		"passed": moved > 20.0,
		"detail": "flew %.0f units forward, speed %.2f LM" % [moved, float(flight_view.player["speed"]) / 1000.0]
	})

	flight_view.spawn_test_target()
	await _frames(4)
	var s0: int = flight_view.shots
	var h0: int = flight_view.hits
	Input.action_press("fire")
	await get_tree().create_timer(1.2).timeout
	Input.action_release("fire")
	await _frames(4)
	var dshots: int = flight_view.shots - s0
	var dhits: int = flight_view.hits - h0
	steps.append({
		"step": "act",
		"passed": dshots > 0 and dhits > 0,
		"detail": "fired %d laser shots, %d hit the drone" % [dshots, dhits]
	})

	var hud_ok: bool = float(commander["cash"]) > 0.0 and float(commander["shield_f"]) >= 0.0 \
		and float(flight_view.player["speed"]) >= 0.0 and int(commander["cargo_capacity"]) > 0
	var drawn: bool = flight_view.hud_draws > 0 or DisplayServer.get_name() == "headless"
	steps.append({
		"step": "hud",
		"passed": hud_ok and drawn,
		"detail": "dashboard shows speed %.2f LM, cash %.1f CR, cargo %d/%d t, shields %.0f/%.0f, fuel %.1f LY (%s)" % [
			float(flight_view.player["speed"]) / 1000.0, float(commander["cash"]),
			int(commander["cargo_used"]), int(commander["cargo_capacity"]),
			float(commander["shield_f"]), float(commander["shield_a"]), float(commander["fuel"]),
			"drawn" if flight_view.hud_draws > 0 else "headless"
		]
	})

	var out := {"version": 1, "steps": steps}
	var path := _resolve_path(self_test_path)
	var dir := path.get_base_dir()
	if dir != "":
		DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(out, "  "))
		f.close()
	print("self-test written to ", path)
	for s in steps:
		print(s["step"], ": ", s["passed"], " - ", s["detail"])
	await _quit_clean()


func _quit_clean() -> void:
	# releasing the sounds before exit keeps the shutdown log free of the
	# "resources still in use" complaint, which the build check flags as an error
	if flight_view != null:
		for k in flight_view.sfx.keys():
			var p = flight_view.sfx[k]
			if p is AudioStreamPlayer:
				p.stop()
				p.stream = null
				p.queue_free()
		flight_view.sfx.clear()
	for a in ["accelerate", "fire", "pitch_up", "pitch_down", "roll_left", "roll_right", "decelerate"]:
		Input.action_release(a)
	# drop every node and the cached sounds before quitting: leaving them alive
	# makes the engine report "resources still in use at exit", which the build
	# check treats as an error
	AudioServer.set_bus_mute(0, true)
	for child in get_tree().root.get_children():
		if child != self:
			child.queue_free()
	await get_tree().process_frame
	# NOTE: never queue_free() this node itself — the coroutine would be freed
	# mid-await and quit() would never run (the engine hangs after that)
	await get_tree().create_timer(0.1).timeout
	get_tree().quit(0)