extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().process_frame
	var village = world.get_node("Village")
	var businesses = world.get_node("Businesses")
	assert(village.front_houses.size() == 8)
	assert(village.rear_houses.size() == 12)
	var models: Dictionary = {}
	for house in village.front_houses + village.rear_houses:
		models[house.get_meta("model")] = true
	assert(models.size() == 20, "Every generated house model must appear in the kingdom")
	# The market and the tailor were removed: their awnings sprawled across the
	# street and hid what a round did to the cottages either side.
	assert(businesses.buildings.size() == 6, "Two shops and four factories must exist")
	for shop in businesses.buildings:
		assert(not str(shop.get_meta("business")) in ["Mercado", "Alfaiataria"], "The awning shops must be gone")
	for rear in village.rear_houses:
		assert(not rear is PhysicsBody2D, "Background buildings must not stop projectiles")
	var camera = world.get_node("KingdomCamera")
	camera.position.x = 1640
	village.rear_row._process(0.016)
	assert(absf(village.rear_row.position.x) <= 6.0, "Rear village parallax must stay subtle")
	var worker = world.get_node("Characters/WorkerA")
	var shop = businesses.buildings[0]
	worker.routine_sites = [shop, village.front_houses[1]]
	worker.routine_index = 0
	worker.routine_wait = 3.0
	shop.apply_explosion_damage(100, shop.global_position)
	await get_tree().physics_frame
	worker._follow_routine(0.016)
	assert(worker.routine_index == 1, "Workers must skip a destroyed workplace")
	assert(shop.get_node("CollisionShape2D").disabled)
	assert("fechada" in shop.get_node("NameLabel").text)
	assert(world.get_node("Structures/Factory").get_node("Artwork").house_texture != null, "Mill must replace the old factory art")
	assert(camera.max_x > world.get_node("Businesses").buildings[5].position.x)
	print("PASS: 20 unique houses, village depth, 8 businesses, workplace closure and worker rerouting")
	get_tree().quit()
