extends Node

# A cottage in the actual village, shelled by the actual cannon. One round opens a
# hole and the house goes on standing; the far side of it is untouched; repeated
# rounds bring it down, and the kingdom hears about it.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var building = world.get_node("Structures/VillageHouse")
	var house = building.get_node("PhysicalHouse")
	var events: Array = []
	var impacts: Array = []
	EventBus.world_event.connect(func(event: Dictionary): events.append(event))
	EventBus.projectile_impacted.connect(func(event: Dictionary): impacts.append(event))
	await steps(240)
	assert(is_equal_approx(house.standing_ratio(), 1.0), "The cottage must stand whole in the actual village")
	assert(not house._collapsed, "Settling alone must not destroy a house")
	assert(building._integrity == building.max_integrity)
	await capture("village_physics_before")

	var facade = house.facade
	var far_side: Vector2 = facade.to_global(facade.base_offset
		+ Vector2(facade.art.get_width() * 0.88, facade.art.get_height() * 0.8) * facade.pixel)
	world.get_node("Knight")._fire(Vector2(800, 90))
	await steps(75)
	await capture("village_physics_impact")
	assert(not impacts.is_empty() and impacts[0].target == &"VillageHouse", "The real cannon must hit the cottage")
	assert(get_tree().get_nodes_in_group("active_projectiles").is_empty(), "The round must detonate, not drive through")
	await steps(120)
	await capture("village_physics_after")
	var left: float = house.standing_ratio()
	print("VILLAGE standing=", left, " integrity=", building._integrity, "/", building.max_integrity, " collapsed=", house._collapsed)
	assert(left < 1.0, "The round must take material out of the cottage")
	assert(left > 0.5, "One round must leave the cottage standing, not flatten it")
	assert(not house._collapsed, "A hole is damage, not destruction")
	assert(events.any(func(e): return e.type == "STRUCTURE_HIT" and e.target == "VillageHouse"), "The hole must be reported")
	assert(not events.any(func(e): return e.type == "STRUCTURE_DESTROYED" and e.target == "VillageHouse"))
	# Masonry the blast never reached is exactly as it was: the anti-billiards
	# guarantee, now on a facade rather than on a stack of blocks.
	assert(facade.closest_point(far_side).distance_to(far_side) < 40.0, "The far side of the cottage must still be there")

	# Rounds into the same cottage finish it.
	for shot in range(5):
		if house._collapsed:
			break
		var finisher = load("res://scenes/projectile.tscn").instantiate()
		finisher.position = facade.to_global(facade.base_offset
			+ Vector2(facade.art.get_width() * (0.2 + 0.15 * shot), 0.0) * facade.pixel) - Vector2(0, 130)
		finisher.linear_velocity = Vector2(0, 650)
		world.add_child(finisher)
		await steps(90)
	await steps(120)
	print("VILLAGE after finishers: standing=", house.standing_ratio(), " collapsed=", house._collapsed)
	assert(house._collapsed, "Enough rounds must bring the cottage down")
	assert(events.any(func(e): return e.type == "STRUCTURE_DESTROYED" and e.target == "VillageHouse"))
	assert(building._integrity == 0)
	for node in get_tree().get_nodes_in_group("stone_shards"):
		assert(is_finite(node.global_position.x) and node.global_position.y < 900, "Rubble must collide with the ground")
	print("PASS: a cottage in the village takes a hole from one round, stands, and falls to several; social events reported")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func capture(id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/%s.png" % id)
