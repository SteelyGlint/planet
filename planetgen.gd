extends TextureFrame

var surfaceImage
var surfaceTexture
var imageSize = Vector2(100, 100)
var imageFormat = Image.FORMAT_RGBA

var planetsize = 27
var planetwidth = int(planetsize*1.6) 
var chamfer = floor(planetsize * 0.4)
var totalsquares = 0
var landspawns = []
var hillspawns = []
var landsquares = 0
var hillsquares = 0
var landfraction = .35
var hillfraction = landfraction * 0.5
var landspreadfactor = 0.5
var landstarts = ceil(planetsize*.45)
var display_scale = 8

var tiles = []
var Tile = preload("tile.gd")

var total_d = 0
var total_land = 0

func pix_on_surface(xx, yy):
	var offset = max( 0, max( chamfer-yy, chamfer-planetsize+yy+1) )
	var yy_end = floor(planetwidth - offset)
	if yy >= 0 and yy < planetsize and xx >= offset and xx < yy_end: return true
	else: return false

func _ready():
	randomize()
	surfaceImage = Image(imageSize.x, imageSize.y, false, imageFormat)
	surfaceTexture = ImageTexture.new()
	surfaceTexture.create(imageSize.x,imageSize.y, imageFormat, 0)    
	surfaceTexture.set_data(surfaceImage)
	set_texture(surfaceTexture)
	
	set_scale(Vector2(display_scale, display_scale))
	set_pos(Vector2(25, 25))
	
	set_process_input(true)
	set_process(true)
	
	for xx in range(planetwidth):
		tiles.append([])
		for yy in range(planetsize):
			tiles[xx].append(Tile.new())
	
	create_surface()

func get_adjacent(xx, yy):
	var adj_list = []
	if yy == 0: # north pole
		for x in range(chamfer, planetwidth-chamfer):
			if( x != xx ): adj_list.push_back( Vector2(x, 0))
		adj_list.push_back( Vector2(xx, yy+1))
		return adj_list
	
	if yy == planetsize-1: # south pole
		for x in range(chamfer, planetwidth-chamfer):
			if( x != xx ): adj_list.push_back( Vector2(x, planetsize-1))
		adj_list.push_back( Vector2(xx, yy-1))
		return adj_list
	
	if pix_on_surface(xx, yy-1): adj_list.push_back( Vector2(xx, yy-1))
	if pix_on_surface(xx, yy+1): adj_list.push_back( Vector2(xx, yy+1))
	
	if pix_on_surface(xx-1, yy):	adj_list.push_back( Vector2(xx-1, yy))
	else:	# wrap around the west edge
		var adj_x = planetwidth-max(0,max( chamfer-yy, chamfer-planetsize+yy+1))-1
		adj_list.push_back( Vector2(adj_x, yy))
	
	if pix_on_surface(xx+1, yy): adj_list.push_back( Vector2(xx+1, yy))
	else:	# wrap around the east edge
		var adj_x = max(0,max( chamfer-yy, chamfer-planetsize+yy+1))
		adj_list.push_back( Vector2(adj_x, yy))
	return adj_list

func step_east(xx, yy):
	if pix_on_surface(xx+1, yy): return Vector2(xx+1, yy)
	else:	# wrap around the east edge
		var adj_x = max(0,max( chamfer-yy, chamfer-planetsize+yy+1))
		return Vector2(adj_x, yy)

func try_insert_land(xx, yy):
	if pix_on_surface(xx, yy) and randf()<landspreadfactor and tiles[xx][yy].biome != Tile.land:
		landsquares += 1
		tiles[xx][yy].biome = Tile.land
		landspawns.push_back( Vector2(xx, yy) )

func try_insert_hill(xx, yy):
	if pix_on_surface(xx, yy) and randf()<0.8 and tiles[xx][yy].biome != Tile.hill:
		hillsquares += 1
		tiles[xx][yy].biome = Tile.hill
		
		var adj_list = get_adjacent( xx, yy )
		for adj in adj_list:
			if tiles[adj.x][adj.y].biome == Tile.ocean and randf()<0.5: return
		
		hillspawns.push_back( Vector2(xx, yy) )

func create_surface():
	# lay down the ocean
	for xx in range(planetwidth):
		for yy in range(planetsize):
			if pix_on_surface(xx, yy):
				totalsquares += 1
				tiles[xx][yy].biome = Tile.ocean
	
	# create points from which continents will grow
	while landsquares < landstarts:
		var xx = randi()%(planetwidth)
		var yy = 2 + randi()%(planetsize-4)
		if pix_on_surface(xx, yy):
			landspawns.push_back( Vector2(xx, yy) )
			hillspawns.push_back( Vector2(xx, yy) )
			landsquares += 1
			tiles[xx][yy].biome = Tile.land
	
	# grow initial landmasses
	while landsquares<landfraction*totalsquares and landspawns.size() > 0:
		var spread_land = landspawns[0]
		landspawns.pop_front()
		var adj_list = get_adjacent( spread_land.x, spread_land.y )
		for adj in adj_list:
			try_insert_land( adj.x, adj.y )
	
	# grow hills within the landmasses
	while hillsquares<hillfraction*totalsquares and hillspawns.size() > 0:
		var spread_land = hillspawns[0]
		hillspawns.pop_front()
		var adj_list = get_adjacent( spread_land.x, spread_land.y )
		for adj in adj_list:
			try_insert_hill( adj.x, adj.y )

	# set a few squares deep in the hills to mountains
	for xx in range(planetwidth):
		for yy in range(1, planetsize-1):
			if pix_on_surface(xx, yy):
				var mountain_chance = 0
				var adj_list = get_adjacent( xx, yy )
				for adj in adj_list:
					if tiles[adj.x][adj.y].biome == Tile.hill: mountain_chance += 8
					if tiles[adj.x][adj.y].biome == Tile.mount: mountain_chance += 30
					if tiles[adj.x][adj.y].biome == Tile.land: mountain_chance += -30
					if tiles[adj.x][adj.y].biome == Tile.ocean: mountain_chance += -100
					if tiles[adj.x][adj.y].biome == Tile.drybed: mountain_chance += -100
				if randi()%100 < mountain_chance:
					tiles[xx][yy].biome = Tile.mount
	
	# apply ice caps to the poles
	for xx in range(planetwidth):
		for yy in [0, 1, 2, 3, planetsize-4, planetsize-3, planetsize-2, planetsize-1]:
			if pix_on_surface(xx, yy):
				var icyness = 0
				if yy == 0 or yy == 1 or yy == planetsize-2 or yy == planetsize-1: icyness += 3
				if yy == 2 or yy == planetsize-3: icyness += 2
				if yy == 3 or yy == planetsize-4: icyness += 1
				if tiles[xx][yy].biome == Tile.mount: icyness += 2
				if tiles[xx][yy].biome == Tile.hill: icyness += 1
				if tiles[xx][yy].biome == Tile.ocean and randf()<0.5: icyness += -1
				if icyness >= 2:
					if tiles[xx][yy].biome == Tile.ocean:
						tiles[xx][yy].biome = Tile.seaice
					else:
						tiles[xx][yy].biome = Tile.ice
	
	add_moisture()
	create_texture()

func get_tile_dank(type):
	if type == Tile.ocean:	return 2
	else:					return 0

func add_moisture():
	var moist = []
	for xx in range(planetwidth):
		moist.append([])
		for yy in range(planetsize):
			moist[xx].append(0)
	
	for xx in range(planetwidth):
		for yy in range(planetsize):
			if pix_on_surface(xx, yy):
				var dank = 4 * get_tile_dank( tiles[xx][yy].biome )
				var adj_list = get_adjacent( xx, yy )
				for adj in adj_list:
					dank += get_tile_dank( tiles[adj.x][adj.y].biome )
				dank = dank / (2.0 + adj_list.size())
				moist[xx][yy] = dank
	
	for iter in range(5):
		for xx in range(planetwidth):
			for yy in range(planetsize):
				if pix_on_surface(xx, yy):
					# precipitate in this tile
					if tiles[xx][yy].biome == Tile.land:
						if tiles[xx][yy].moisture < 2:
							var precip = 0.5*(moist[xx][yy] - 0.4*tiles[xx][yy].moisture)
							tiles[xx][yy].moisture += precip
							moist[xx][yy] -= precip
					if tiles[xx][yy].biome == Tile.hill:
						if tiles[xx][yy].moisture < 2:
							var precip = 0.5*(moist[xx][yy] - 0.6*tiles[xx][yy].moisture)
							tiles[xx][yy].moisture += precip
							moist[xx][yy] -= precip
					if tiles[xx][yy].biome == Tile.mount:
						if tiles[xx][yy].moisture < 2:
							var precip = 0.5*(moist[xx][yy] - 0.8*tiles[xx][yy].moisture)
							tiles[xx][yy].moisture += precip
							moist[xx][yy] -= precip
					
					var target = step_east(xx,yy)
					var breeze = moist[xx][yy] *0.3
					moist[xx][yy] -= breeze
					moist[target.x][target.y] += breeze
					
					if (tiles[xx][yy].moisture > 0.1 and tiles[xx][yy].biome == Tile.land) or\
							(tiles[xx][yy].moisture > 0.5 and tiles[xx][yy].biome != Tile.mount): 
						tiles[xx][yy].biome = Tile.terran

func create_texture():
	for xx in range(planetwidth):
		for yy in range(planetsize):
			if pix_on_surface(xx, yy):
				surfaceImage.put_pixel(xx,yy, tiles[xx][yy].color())

var temp = true
func _process(d):
	total_d += d
	
	#if total_d > 0.5:
	#	for ii in range(50):
	#		drop_land_square()
	
	#if total_d > 2.5:
	#	create_texture()
	
	surfaceTexture.set_data(surfaceImage)

func _input(event):
	if event.type == InputEvent.MOUSE_MOTION:
		var xx = int((event.x-25)/display_scale)
		var yy = int((event.y-25)/display_scale)
#		if xx < planetwidth and yy < planetsize:
#			if pix_on_surface(int(xx), int(yy)):
#				var adj_list = get_adjacent( xx, yy )
#				for adj in adj_list:
#					surfaceImage.put_pixel(adj.x, adj.y, Color(0.9, 0.9, 0.9))
