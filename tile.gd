
var biome = 0
var moisture = 0

const none = 0
const ocean = 1
const land = 2
const hill = 3
const mount = 4
const ice = 5

func color():
	if biome == none: return Color( 0, 0, 0, 0 )
	if biome == ocean: return Color( 0, 0, 0, 0 )
	if biome == land: return Color( 0, 0, 0, 0 )
	if biome == hill: return Color( 0, 0, 0, 0 )
	if biome == mount: return Color( 0, 0, 0, 0 )
	if biome == ice: return Color( 0, 0, 0, 0 )
	if biome == none: return Color( 0, 0, 0, 0 )

func _init():
	pass

func _ready():
	pass
