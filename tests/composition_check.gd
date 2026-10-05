extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().process_frame
	var terrain = world.get_node("Terraces")
	var terrain_textures: Dictionary = {}
	for section in terrain.get_children():
		if section is Sprite2D:
			assert(section.scale == Vector2.ONE, "Terrain must stay at native resolution")
			assert("terrain_long_v2" in section.texture.resource_path, "Rejected terrain must not return")
			terrain_textures[section.texture.resource_path] = true
	assert(terrain_textures.size() == 4, "All four terrain sections must be independently authored")
	var knight = world.get_node("Knight")
	var cannon = knight.get_node("CannonArt")
	var castle = world.get_node("Structures/Castle")
	assert(castle.get_node("Artwork").house_width == 950)
	# Check the full silhouette's bottom edge against actual opaque plateau pixels.
	var castle_art = castle.get_node("Artwork")
	var castle_image: Image = castle_art.house_texture.get_image()
	var plateau_image: Image = terrain.CASTLE_PLATEAU.get_image()
	var factor: float = castle_art.house_width / castle_image.get_width()
	for x in range(0, castle_image.get_width(), 8):
		var base_y := -1
		for y in range(castle_image.get_height()-1,-1,-1):
			if castle_image.get_pixel(x,y).a > 0.8:
				base_y = y
				break
		if base_y < 0: continue
		var world_x: float = castle.position.x-castle_art.house_width/2+x*factor
		var world_y: float = castle_art.ground_y-(castle_image.get_height()-base_y)*factor+3
		var sample := Vector2i(int(world_x-5100),int(world_y))
		assert(Rect2i(Vector2i.ZERO,plateau_image.get_size()).has_point(sample))
		assert(plateau_image.get_pixelv(sample).a > 0.8, "Every castle base column must have opaque terrain below it")
	assert(world.get_node("Businesses").buildings.size() == 6)
	assert(world.get_node("Composition").noble_houses.size() == 4)
	knight._ammo = 1
	knight._fire(Vector2(2200,-1600))
	assert(cannon.recoil == 1.0)
	assert(cannon.flash > 0)
	await get_tree().create_timer(0.08).timeout
	assert(cannon.pivot.position.x < cannon.pivot_home.x)
	assert(cannon.wheel.rotation < 0)
	await get_tree().create_timer(0.6).timeout
	assert(is_zero_approx(cannon.recoil))
	assert(cannon.pivot.position.distance_to(cannon.pivot_home) < 0.01)
	assert(not knight._intervention_active)
	print("PASS: four factories, noble district, enlarged castle and last-shot cannon recoil/return")
	get_tree().quit()
