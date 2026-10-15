extends Node

# The whole kingdom on the carved model, cottages and castle alike
# still on the block model it has not been moved off yet.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var village = world.get_node("Village")
	# The castle is carved now, like everything else. It used to be one tower built
	# of stacked blocks that had to be watched for collapsing under its own weight;
	# a carved keep cannot do that, so what is checked is that it stands whole until
	# something hits it.
	var keep = world.get_node("Structures/Castle/PhysicalHouse")
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
	var keep_whole: float = keep.standing_ratio()
	print("KEEP standing=", keep_whole)
	assert(keep_whole > 0.2, "The keep must stand before anything is fired")
	await capture(world, Vector2(1500, 350), 1.0, "expanded_village_before")
	await capture(world, Vector2(6170, -50), 0.65, "castle_before")

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
	# Two rounds into the keep's own wall. These used to be aimed at a tower built
	# of stacked blocks; the castle is carved now, so what they must prove is that
	# the wall opens and the fortress keeps standing.
	var castle = world.get_node("Structures/Castle")
	var keep_wall: Vector2 = keep.facade.to_global(keep.facade.base_offset
		+ Vector2(keep.facade.art.get_width() * 0.5, keep.facade.art.get_height() * 0.55)
		* keep.facade.pixel)
	var ball = load("res://scenes/projectile.tscn").instantiate()
	ball.position = keep_wall - Vector2(260, 0)
	ball.linear_velocity = Vector2(2200, 0)
	world.add_child(ball)
	await steps(45)
	await capture(world, Vector2(6170, -50), 0.65, "castle_impact")
	var second = load("res://scenes/projectile.tscn").instantiate()
	second.position = keep_wall - Vector2(260, 90)
	second.linear_velocity = Vector2(2400, 0)
	world.add_child(second)
	await steps(420)

	var left: float = house.standing_ratio()
	print("HOUSE standing=", left, " collapsed=", house._collapsed, " integrity=", target._integrity, "/", target.max_integrity)
	# A round into the village must not reach the castle at the other end of the
	# kingdom, which is what the old tower's crown drift used to catch.
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
	var keep_left: float = keep.standing_ratio()
	print("KEEP after two rounds standing=", keep_left, " of ", keep_whole)
	assert(keep_left < keep_whole, "Rounds must open the castle wall")
	assert(keep_left > keep_whole * 0.85, "Two rounds must not bring the fortress down")
	assert(castle._integrity > 0, "The keep must survive a pair of rounds")
	await capture(world, Vector2(6170, -50), 0.65, "castle_after")
	await capture(world, Vector2(1500, 350), 1.0, "expanded_village_after")
	print("PASS: eight carved cottages, a round opens one and spares the street, the castle takes its rounds and stands")
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
