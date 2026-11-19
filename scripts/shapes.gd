class_name EliteShapes
extends RefCounted

# Wireframe models, in the flat white-line style of the BBC Micro original.
# Each model is a list of vertices and a list of edges (pairs of indices),
# scaled so that "size" is roughly the ship's length in game units.

static func cobra_mk3() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.6),        # 0 nose
		Vector3(0, 0.45, -0.3),     # 1 cabin top
		Vector3(-1.5, 0.1, 0.5),    # 2 left wing tip
		Vector3(1.5, 0.1, 0.5),     # 3 right wing tip
		Vector3(0, -0.45, -0.3),    # 4 cabin bottom
		Vector3(0, 0.35, 0.9),      # 5 rear top
		Vector3(0, -0.35, 0.9),     # 6 rear bottom
		Vector3(-1.0, 0.0, 0.95),   # 7 left rear
		Vector3(1.0, 0.0, 0.95),    # 8 right rear
		Vector3(-0.45, 0.32, 0.2),  # 9 engine left
		Vector3(0.45, 0.32, 0.2)    # 10 engine right
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 4), Vector2i(3, 4),
		Vector2i(1, 5), Vector2i(2, 7), Vector2i(3, 8), Vector2i(4, 6),
		Vector2i(5, 7), Vector2i(5, 8), Vector2i(6, 7), Vector2i(6, 8),
		Vector2i(7, 8), Vector2i(5, 6),
		Vector2i(9, 10), Vector2i(9, 1), Vector2i(10, 1), Vector2i(9, 5), Vector2i(10, 5)
	]
	return {"v": v, "e": e}


static func sidewinder() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.0),
		Vector3(-1.0, 0, 0.55),
		Vector3(1.0, 0, 0.55),
		Vector3(0, 0.5, 0.0),
		Vector3(0, -0.4, 0.0),
		Vector3(0, 0.2, 0.65)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3),
		Vector2i(1, 4), Vector2i(2, 4), Vector2i(1, 5), Vector2i(2, 5),
		Vector2i(3, 5), Vector2i(4, 5)
	]
	return {"v": v, "e": e}


static func python() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.8),
		Vector3(-0.75, 0.55, 0.4),
		Vector3(0.75, 0.55, 0.4),
		Vector3(-0.75, -0.55, 0.4),
		Vector3(0.75, -0.55, 0.4),
		Vector3(0, 0.45, 0.95),
		Vector3(0, -0.45, 0.95),
		Vector3(-0.55, 0.0, 1.0),
		Vector3(0.55, 0.0, 1.0)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(3, 4), Vector2i(1, 3), Vector2i(2, 4),
		Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 6), Vector2i(4, 6),
		Vector2i(5, 7), Vector2i(5, 8), Vector2i(6, 7), Vector2i(6, 8),
		Vector2i(7, 8)
	]
	return {"v": v, "e": e}


static func viper() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.3),
		Vector3(-1.1, -0.1, 0.55),
		Vector3(1.1, -0.1, 0.55),
		Vector3(-0.35, 0.4, -0.2),
		Vector3(0.35, 0.4, -0.2),
		Vector3(0, 0.15, 0.75),
		Vector3(0, -0.4, 0.3)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(3, 4), Vector2i(1, 3), Vector2i(2, 4), Vector2i(1, 6),
		Vector2i(2, 6), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5),
		Vector2i(4, 5), Vector2i(5, 6)
	]
	return {"v": v, "e": e}


static func krait() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.0),
		Vector3(-1.2, 0.0, 0.4),
		Vector3(1.2, 0.0, 0.4),
		Vector3(0, 0.45, 0.1),
		Vector3(0, -0.35, 0.1),
		Vector3(0, 0.1, 0.6)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4),
		Vector2i(2, 4), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5)
	]
	return {"v": v, "e": e}


static func mamba() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.35),
		Vector3(-1.3, 0.0, 0.5),
		Vector3(1.3, 0.0, 0.5),
		Vector3(0, 0.5, 0.15),
		Vector3(0, -0.4, 0.15),
		Vector3(0, 0.25, 0.7),
		Vector3(0, -0.25, 0.7)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4),
		Vector2i(2, 4), Vector2i(3, 5), Vector2i(4, 6), Vector2i(5, 6),
		Vector2i(1, 5), Vector2i(2, 5), Vector2i(1, 6), Vector2i(2, 6)
	]
	return {"v": v, "e": e}


static func adder() -> Dictionary:
	var v := [
		Vector3(0, 0, -0.9),
		Vector3(-1.0, 0.0, 0.4),
		Vector3(1.0, 0.0, 0.4),
		Vector3(0, 0.4, 0.2),
		Vector3(0, -0.35, 0.2),
		Vector3(0, 0.0, 0.8)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 3), Vector2i(1, 4),
		Vector2i(2, 4), Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 5), Vector2i(4, 5)
	]
	return {"v": v, "e": e}


static func asp() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.5),
		Vector3(-1.15, 0.0, 0.35),
		Vector3(1.15, 0.0, 0.35),
		Vector3(-0.55, 0.42, 0.55),
		Vector3(0.55, 0.42, 0.55),
		Vector3(0, -0.35, 0.45),
		Vector3(0, 0.0, 0.95)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 4), Vector2i(3, 4),
		Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 6), Vector2i(4, 6),
		Vector2i(5, 6), Vector2i(1, 6), Vector2i(2, 6)
	]
	return {"v": v, "e": e}


static func fer_de_lance() -> Dictionary:
	var v := [
		Vector3(0, 0, -2.0),
		Vector3(-0.9, 0.15, 0.1),
		Vector3(0.9, 0.15, 0.1),
		Vector3(-0.9, -0.2, 0.1),
		Vector3(0.9, -0.2, 0.1),
		Vector3(0, 0.55, 0.75),
		Vector3(0, -0.3, 0.8)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(3, 4), Vector2i(1, 5), Vector2i(2, 5),
		Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6), Vector2i(1, 3),
		Vector2i(2, 4)
	]
	return {"v": v, "e": e}


static func gecko() -> Dictionary:
	var v := [
		Vector3(0, 0, -0.95),
		Vector3(-1.25, -0.1, 0.15),
		Vector3(1.25, -0.1, 0.15),
		Vector3(-0.5, 0.45, 0.25),
		Vector3(0.5, 0.45, 0.25),
		Vector3(0, -0.4, 0.5),
		Vector3(0, 0.15, 0.8)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 4), Vector2i(3, 4),
		Vector2i(1, 5), Vector2i(2, 5), Vector2i(3, 6), Vector2i(4, 6),
		Vector2i(5, 6)
	]
	return {"v": v, "e": e}


static func cobra_mk1() -> Dictionary:
	var m := cobra_mk3()
	return m


static func boa() -> Dictionary:
	var v := [
		Vector3(0, 0, -2.2),
		Vector3(-0.9, 0.5, -0.6), Vector3(0.9, 0.5, -0.6),
		Vector3(-0.9, -0.5, -0.6), Vector3(0.9, -0.5, -0.6),
		Vector3(-0.9, 0.5, 1.2), Vector3(0.9, 0.5, 1.2),
		Vector3(-0.9, -0.5, 1.2), Vector3(0.9, -0.5, 1.2)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(3, 4), Vector2i(1, 3), Vector2i(2, 4),
		Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7), Vector2i(4, 8),
		Vector2i(5, 6), Vector2i(7, 8), Vector2i(5, 7), Vector2i(6, 8)
	]
	return {"v": v, "e": e}


static func anaconda() -> Dictionary:
	var v := [
		Vector3(0, 0, -2.8),
		Vector3(-1.3, 0.6, -0.9), Vector3(1.3, 0.6, -0.9),
		Vector3(-1.3, -0.6, -0.9), Vector3(1.3, -0.6, -0.9),
		Vector3(-1.5, 0.7, 1.4), Vector3(1.5, 0.7, 1.4),
		Vector3(-1.5, -0.7, 1.4), Vector3(1.5, -0.7, 1.4),
		Vector3(0, 0.9, 0.4)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(3, 4), Vector2i(1, 3), Vector2i(2, 4),
		Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7), Vector2i(4, 8),
		Vector2i(5, 6), Vector2i(7, 8), Vector2i(5, 7), Vector2i(6, 8),
		Vector2i(1, 9), Vector2i(2, 9), Vector2i(5, 9), Vector2i(6, 9)
	]
	return {"v": v, "e": e}


static func thargon() -> Dictionary:
	var v := []
	for i in 8:
		var a := TAU * float(i) / 8.0
		v.append(Vector3(cos(a) * 0.45, sin(a) * 0.45, 0.0))
	v.append(Vector3(0, 0, -0.7))
	v.append(Vector3(0, 0, 0.7))
	var e := []
	for i in 8:
		e.append(Vector2i(i, (i + 1) % 8))
		e.append(Vector2i(i, 8))
		e.append(Vector2i(i, 9))
	return {"v": v, "e": e}


static func thargoid() -> Dictionary:
	var v := [
		Vector3(0, 0, -1.2),
		Vector3(-1.2, 0.2, 0.0),
		Vector3(1.2, 0.2, 0.0),
		Vector3(-0.7, -0.5, 0.4),
		Vector3(0.7, -0.5, 0.4),
		Vector3(0, 0.7, 0.5),
		Vector3(0, -0.2, 0.9)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(1, 3), Vector2i(2, 4), Vector2i(1, 5),
		Vector2i(2, 5), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6),
		Vector2i(1, 6), Vector2i(2, 6)
	]
	return {"v": v, "e": e}


static func asteroid() -> Dictionary:
	var v := [
		Vector3(0.0, 0.85, -0.3), Vector3(0.75, 0.4, 0.1), Vector3(0.8, -0.35, -0.2),
		Vector3(0.0, -0.8, 0.2), Vector3(-0.75, -0.3, -0.1), Vector3(-0.7, 0.45, 0.2),
		Vector3(0.1, 0.1, 0.95)
	]
	var e := [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4),
		Vector2i(4, 5), Vector2i(5, 0), Vector2i(0, 6), Vector2i(1, 6),
		Vector2i(2, 6), Vector2i(3, 6), Vector2i(4, 6), Vector2i(5, 6)
	]
	return {"v": v, "e": e}


static func canister() -> Dictionary:
	var s := 0.35
	var v := [
		Vector3(-s, -s, -s), Vector3(s, -s, -s), Vector3(s, s, -s), Vector3(-s, s, -s),
		Vector3(-s, -s, s), Vector3(s, -s, s), Vector3(s, s, s), Vector3(-s, s, s)
	]
	var e := [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7)
	]
	return {"v": v, "e": e}


static func missile() -> Dictionary:
	var v := [
		Vector3(0, 0, -0.9),
		Vector3(-0.12, 0.12, 0.2), Vector3(0.12, 0.12, 0.2),
		Vector3(0.12, -0.12, 0.2), Vector3(-0.12, -0.12, 0.2),
		Vector3(-0.3, 0, 0.45), Vector3(0.3, 0, 0.45)
	]
	var e := [
		Vector2i(0, 1), Vector2i(0, 2), Vector2i(0, 3), Vector2i(0, 4),
		Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 1),
		Vector2i(1, 5), Vector2i(4, 5), Vector2i(2, 6), Vector2i(3, 6)
	]
	return {"v": v, "e": e}


static func station() -> Dictionary:
	# Coriolis: a cuboctahedron (12 corners, 8 triangular + 6 square faces),
	# with the rectangular docking slot cut into the square face at -Z.
	var v := []
	var edges := []
	var d := 0.78
	for axis in 3:
		for a in [1.0, -1.0]:
			for b in [1.0, -1.0]:
				var p := Vector3.ZERO
				p[axis] = 0.0
				p[(axis + 1) % 3] = a * d
				p[(axis + 2) % 3] = b * d
				v.append(p)
	# every pair of corners one edge-length apart is an edge
	var edge_len := sqrt(2.0) * d
	for i in v.size():
		for j in range(i + 1, v.size()):
			if abs((v[i] - v[j]).length() - edge_len) < 0.01:
				edges.append(Vector2i(i, j))
	# docking slot, centred on the -Z square face (its corners are a diamond)
	var sx := 0.52
	var sy := 0.19
	var sz := -d - 0.01
	var sa := v.size()
	v.append(Vector3(-sx, sy, sz))
	v.append(Vector3(sx, sy, sz))
	v.append(Vector3(sx, -sy, sz))
	v.append(Vector3(-sx, -sy, sz))
	edges.append(Vector2i(sa, sa + 1))
	edges.append(Vector2i(sa + 1, sa + 2))
	edges.append(Vector2i(sa + 2, sa + 3))
	edges.append(Vector2i(sa + 3, sa))
	# a few detail lines on the face, in the spirit of the original's faceting
	var sa2 := v.size()
	v.append(Vector3(-sx * 0.75, -d * 0.5, sz))
	v.append(Vector3(sx * 0.75, -d * 0.5, sz))
	edges.append(Vector2i(sa2, sa2 + 1))
	return {"v": v, "e": edges}


static func cobra() -> Dictionary:
	return cobra_mk3()
