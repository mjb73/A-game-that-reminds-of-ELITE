class_name EliteGalaxy
extends RefCounted

# Procedural galaxy identical in method to BBC Micro Elite (1984).
# Seeds are three 16-bit numbers in a Tribonacci sequence, "twisted" once per
# system. Verified against the original data for Tibedied (system 0) and Lave
# (system 7 of galaxy 1): names, economy, government, tech level, population,
# productivity, radius and chart position all match the published originals.

const SEED0 := 0x5A4A
const SEED1 := 0x0248
const SEED2 := 0xB753

const GALAXY_NAMES := [
	"Galaxy 1", "Galaxy 2", "Galaxy 3", "Galaxy 4",
	"Galaxy 5", "Galaxy 6", "Galaxy 7", "Galaxy 8"
]

# Two-letter tokens used to build system names (QQ16, token 128 onwards).
const TOKENS := [
	"AL", "LE", "XE", "GE", "ZA", "CE", "BI", "SO", "US", "ES", "AR", "MA",
	"IN", "DI", "RE", "A", "ER", "AT", "EN", "BE", "RA", "LA", "VE", "TI",
	"ED", "OR", "QU", "AN", "TE", "IS", "RI", "ON"
]

const ECONOMY_NAMES := [
	"Rich Industrial", "Average Industrial", "Poor Industrial", "Mainly Industrial",
	"Mainly Agricultural", "Rich Agricultural", "Average Agricultural", "Poor Agricultural"
]

const GOVERNMENT_NAMES := [
	"Anarchy", "Feudal", "Multi-Government", "Dictatorship",
	"Communist", "Confederacy", "Democracy", "Corporate State"
]

# QQ23: base price, economic factor, unit, base quantity, price/quantity mask.
# Unit letters: t = tonnes, k = kilograms, g = grams.
const ITEMS := [
	{"name": "Food",          "base": 19,  "adj": -2, "unit": "t", "qty": 6,   "mask": 0x01},
	{"name": "Textiles",      "base": 20,  "adj": -1, "unit": "t", "qty": 10,  "mask": 0x03},
	{"name": "Radioactives",  "base": 65,  "adj": -3, "unit": "t", "qty": 2,   "mask": 0x07},
	{"name": "Slaves",        "base": 40,  "adj": -5, "unit": "t", "qty": 226, "mask": 0x1F},
	{"name": "Liquor/Wines",  "base": 83,  "adj": -5, "unit": "t", "qty": 251, "mask": 0x0F},
	{"name": "Luxuries",      "base": 196, "adj": 8,  "unit": "t", "qty": 54,  "mask": 0x03},
	{"name": "Narcotics",     "base": 235, "adj": 29, "unit": "t", "qty": 8,   "mask": 0x78},
	{"name": "Computers",     "base": 154, "adj": 14, "unit": "t", "qty": 56,  "mask": 0x03},
	{"name": "Machinery",     "base": 117, "adj": 6,  "unit": "t", "qty": 40,  "mask": 0x07},
	{"name": "Alloys",        "base": 78,  "adj": 1,  "unit": "t", "qty": 17,  "mask": 0x1F},
	{"name": "Firearms",      "base": 124, "adj": 13, "unit": "t", "qty": 29,  "mask": 0x07},
	{"name": "Furs",          "base": 176, "adj": -9, "unit": "t", "qty": 220, "mask": 0x3F},
	{"name": "Minerals",      "base": 32,  "adj": -1, "unit": "t", "qty": 53,  "mask": 0x03},
	{"name": "Gold",          "base": 97,  "adj": -1, "unit": "k", "qty": 66,  "mask": 0x07},
	{"name": "Platinum",      "base": 171, "adj": -2, "unit": "k", "qty": 55,  "mask": 0x1F},
	{"name": "Gem-Stones",    "base": 45,  "adj": -1, "unit": "g", "qty": 250, "mask": 0x0F},
	{"name": "Alien Items",   "base": 53,  "adj": 15, "unit": "t", "qty": 192, "mask": 0x07}
]


static func tweak(seed: Array) -> Array:
	var total: int = (seed[0] + seed[1] + seed[2]) & 0xFFFF
	return [seed[1], seed[2], total]


static func twist4(seed: Array) -> Array:
	var s := [seed[0], seed[1], seed[2]]
	for i in 4:
		s = tweak(s)
	return s


# Galactic hyperdrive rotates each 16-bit seed one place to the left.
static func next_galaxy(seed: Array) -> Array:
	var out := []
	for v in seed:
		out.append(((v << 1) | (v >> 15)) & 0xFFFF)
	return out


static func system_name(seed: Array) -> String:
	var s := [seed[0], seed[1], seed[2]]
	var pairs := 4 if (s[0] & 0x40) != 0 else 3
	var out := ""
	for i in pairs:
		var v: int = (s[2] >> 8) & 0x1F
		if v != 0:
			out += TOKENS[v]
		s = tweak(s)
	return out


static func species(s0_hi: int, s1_hi: int, s2_hi: int, s2_lo: int) -> String:
	if (s2_lo & 0x80) == 0:
		return "Human Colonials"
	var out := ""
	var a: int = (s2_hi >> 2) & 0x07
	if a == 0: out += "Large "
	elif a == 1: out += "Fierce "
	elif a == 2: out += "Small "
	a = (s2_hi >> 5) & 0x07
	if a == 0: out += "Green "
	elif a == 1: out += "Red "
	elif a == 2: out += "Yellow "
	elif a == 3: out += "Blue "
	elif a == 4: out += "Black "
	elif a == 5: out += "Harmless "
	a = (s0_hi ^ s1_hi) & 0x07
	var adj_index := a
	if a == 0: out += "Slimy "
	elif a == 1: out += "Bug-Eyed "
	elif a == 2: out += "Horned "
	elif a == 3: out += "Bony "
	elif a == 4: out += "Fat "
	elif a == 5: out += "Furry "
	a = (adj_index + (s2_hi & 0x03)) & 0x07
	var species_words := ["Rodents", "Frogs", "Lizards", "Lobsters", "Birds", "Humanoids", "Felines", "Insects"]
	out += species_words[a]
	return out


static func make_system(seed: Array, index: int) -> Dictionary:
	var s0_hi: int = (seed[0] >> 8) & 0xFF
	var s0_lo: int = seed[0] & 0xFF
	var s1_hi: int = (seed[1] >> 8) & 0xFF
	var s1_lo: int = seed[1] & 0xFF
	var s2_hi: int = (seed[2] >> 8) & 0xFF
	var s2_lo: int = seed[2] & 0xFF

	var economy: int = s0_hi & 0x07
	var government: int = (s1_lo >> 3) & 0x07

	# Anarchy and feudal systems cannot be rich.
	if government <= 1:
		economy = economy | 0x02

	var flipped: int = economy ^ 0x07
	var tech: int = flipped + (s1_hi & 0x03) + int((government + 1) / 2)
	var population: int = tech * 4 + economy + government + 1
	var productivity: int = (flipped + 3) * (government + 4) * population * 8
	var radius: int = ((s2_hi & 0x0F) + 11) * 256 + s1_hi

	return {
		"index": index,
		"name": system_name(seed),
		"seed": [seed[0], seed[1], seed[2]],
		"x": s1_hi,
		"y": s0_hi >> 1,
		"economy": economy,
		"government": government,
		"tech": tech,
		"population": population,
		"productivity": productivity,
		"radius": radius,
		"species": species(s0_hi, s1_hi, s2_hi, s2_lo),
		"description": describe(seed),
		"economy_name": ECONOMY_NAMES[economy],
		"government_name": GOVERNMENT_NAMES[government]
	}


# A deterministic one-line travel-brochure description, in the spirit of the
# original's generated planet notes (the wording here is our own).
static func describe(seed: Array) -> String:
	var noted := ["reasonably noted", "justly famous", "notorious", "much admired", "widely feared", "little known"]
	var subject := [
		"its inhabitants' ancient loathing of casinos",
		"its exotic night life",
		"its vast mineral wealth",
		"the strange tides of its shallow oceans",
		"its excellent cuisine",
		"its endless civil wars",
		"the beauty of its crystal forests",
		"its poisonous rain",
		"the singing of its desert winds",
		"its stubborn independence"
	]
	var extra := [
		" Bring a warm coat.",
		" Visitors are advised to stay indoors after dark.",
		" The local ale is best avoided.",
		" Its moons are worth the trip alone.",
		"",
	]
	var a: int = (seed[0] + seed[2]) % noted.size()
	var b: int = (seed[1] + (seed[2] >> 4)) % subject.size()
	var c: int = (seed[0] + seed[1] + seed[2]) % extra.size()
	return "This planet is %s for %s.%s" % [noted[a], subject[b], extra[c]]


static func make_galaxy(galaxy_index: int) -> Array:
	var seed := [SEED0, SEED1, SEED2]
	for i in galaxy_index:
		seed = next_galaxy(seed)
	var systems := []
	for i in 256:
		systems.append(make_system(seed, i))
		seed = twist4(seed)
	return systems


# Market prices and availability, exactly the 8-bit formulae used by TT151/GVL.
# Prices come out in credits with one decimal place (decicredits / 10).
static func make_market(sys: Dictionary, market_rnd: int) -> Array:
	var market := []
	var economy: int = sys["economy"]
	for item in ITEMS:
		var adj: int = item["adj"]
		var mask: int = item["mask"]
		var p: int = (item["base"] + (market_rnd & mask) + economy * adj) & 0xFF
		var price: float = float(p) * 0.4
		var q: int = (item["qty"] + (market_rnd & mask) - economy * adj) & 0xFF
		if q > 127:
			q = 0
		q = q & 0x3F
		market.append({
			"name": item["name"],
			"unit": item["unit"],
			"price": price,
			"qty": q
		})
	return market


# Jump distance in light years: chart distance / 4 (Elite's scale).
static func distance_between(a: Dictionary, b: Dictionary) -> float:
	var dx: float = float(a["x"] - b["x"])
	var dy: float = float(a["y"] - b["y"])
	return sqrt(dx * dx + dy * dy) / 4.0
