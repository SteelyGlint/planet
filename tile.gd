
var biome = 0
var moisture = 0

const none = 0
const ocean = 1
const drybed = 2
const land = 3
const hill = 4
const mount = 5
const ice = 6
const seaice = 7
const terran = 8
const xeno = 9

# green versions
#var color_land = Color(.21, .64, .23)
#var color_hill = Color(.26, .54, .23)
#var color_mount = Color(.29, .46, .21)

func color():
	if biome == none: return Color(0, 0, 0, 0)
	if biome == ocean: return Color(.15, .45, .70)
	if biome == drybed: return Color(.88, .68, .28)
	if biome == land: return Color(.80, .60, .20)
	if biome == hill: return Color(.70, .51, .21)
	if biome == mount: return Color(.55, .31, .18)
	if biome == ice: return Color(.89, .96, .99)
	if biome == seaice: return Color(.68, .89, .99)
	if biome == terran: return  Color(0.4, 0.5, 0.15)
	if biome == xeno: return Color(.38, .18, .63)

func _init():
	pass

func _ready():
	pass
