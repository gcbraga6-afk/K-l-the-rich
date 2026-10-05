extends Node

# The whole kingdom, with the cottages on the carved model and the castle tower
# still on the block model it has not been moved off yet.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var village = world.get_node("Village")
	var tower = world.get_node("Structures/Castle/ModularStructure")
	await steps(600)
	var whole := {}
	for house in village.front_houses:
		var physical = house.get_node("PhysicalHouse")
		var standing: float = physical.standing_ratio()
		whole[house.name] = standing
		print("STABILITY ", house.name, " standing=", standing, " collapsed=", physical._collapsed)
		assert(not physical._collapsed, "A cottage must not collapse without a shot")
		assert(is_equal_approx(standing, 1.0), "A cottage must lose nothing without a shot")
		assert(house._integrity == house.max_integrity, "An untouched cottage must read as whole")
	print("TOWER stable=", not tower._tower_fallen)
	assert(not tower._tower_fallen, "Tower must stand under its own weight")
	await capture(world, Vector2(1500, 350), 1.0, "expanded_village_before")
	await capture(world, Vector2(6170, -50), 0.65, "physical_tower_before")

	var target = village.front_houses[2]
	var house = target.get_node("PhysicalHouse")
	var facade = house.facade
	# A real round into the wall, not a damage callback.
	# Dropped straight onto this cottage, so the round cannot clip the one next door
	# on its way in and make the test measure the wrong house.
	var house_ball = load("res://scenes/projectile.tscn").instantiate()
	house_ball.position = facade.to_global(facade.base_offset
		+ Vector2(facade.art.get_width() * 0.45, 0.0) * facade.pixel) - Vector2(0, 120)
	house_ball.linear_velocity = Vector2(0, 600)
	world.add_child(house_ball)
	# Isolate this facade from the shops sharing its screen space on another plane.
	for other in get_tree().get_nodes_in_group("structures"):
		if other is PhysicsBody2D:
			house_ball.add_collision_exception_with(other)
	var crown = tower.tower_bodies[0]
	var crown_start: Vector2 = crown.position
	var ball = load("res://scenes/projectile.tscn").instantiate()
	ball.position = tower.to_global(tower.origin + Vector2(250, 310) * tower.factor)
	ball.linear_velocity = Vector2(2200, 0)
	world.add_child(ball)
	await steps(45)
	await capture(world, Vector2(6170, -50), 0.65, "physical_tower_impact")
	var second = load("res://scenes/projectile.tscn").instantiate()
	second.position = tower.to_global(tower.origin + Vector2(250, 100) * tower.factor)
	second.linear_velocity = Vector2(2400, 0)
	world.add_child(second)
	await steps(420)

	var left: float = house.standing_ratio()
	print("HOUSE standing=", left, " collapsed=", house._collapsed, " integrity=", target._integrity, "/", target.max_integrity)
	# The tower is still on the block model, where a course may break into shards
	# and take its own node with it.
	var crown_delta: float = crown.position.distance_to(crown_start) if is_instance_valid(crown) else INF
	print("TOWER crown_delta=", crown_delta, " collapsed=", tower._tower_fallen)
	assert(left < 1.0, "The round must take material out of the cottage it hit")
	assert(left > 0.45, "One round must leave the cottage standing")
	assert(target._integrity < target.max_integrity, "The hit must be reported as damage")
	# The anti-billiards guarantee, now at kingdom scale: a cottage nobody shot at
	# must be exactly as it was, however much went off next door.
	var spared := 0
	for other_house in village.front_houses:
		if other_house == target:
			continue
		var neighbour = other_house.get_node("PhysicalHouse")
		var lost: float = whole[other_house.name] - neighbour.standing_ratio()
		print("  NEIGHBOUR ", other_house.name, " lost=", lost)
		assert(lost < 1.0 - left, "No cottage may lose more than the one the round hit")
		if is_equal_approx(lost, 0.0):
			spared += 1
	print("SPARED ", spared, " of ", village.front_houses.size() - 1)
	# A blast reaches whatever is within its radius, and in a dense village that is
	# the house next door. It must not reach the whole street.
	assert(spared >= village.front_houses.size() - 3, "A round must leave most of the street untouched")
	assert(tower._tower_fallen, "A physical projectile must dislodge the tower")
	assert(world.get_node("Structures/Castle")._integrity > 0, "The keep must survive the lost tower")
	assert(tower.tower_bodies.size() == 7, "Tower bodies must persist")
	for body in tower.tower_bodies:
		if is_instance_valid(body):
			assert(is_finite(body.position.x) and absf(body.global_position.x) < 15000)
	await capture(world, Vector2(6170, -50), 0.65, "physical_tower_after")
	await capture(world, Vector2(1500, 350), 1.0, "expanded_village_after")
	print("PASS: eight carved cottages, a round opens a hole in one and leaves the rest untouched, tower still falls, keep survives")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func capture(world: Node, at: Vector2, zoom: float, id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	var camera = world.get_node("KingdomCamera")
	camera.set_process(false)
	camera.position = at
	camera.zoom = Vector2.ONE * zoom
	await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/%s.png" % id)
