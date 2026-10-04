extends Node

# Fracture replaces struck masonry with shards, so a piece is no longer a node
# that lives for the whole intervention. This checks the behaviour instead of the
# survival of particular bodies: one round opens a hole and the cottage sags onto
# what is left, and only repeated hits bring it down.

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
	assert(not house.region("LoadBeam").is_empty(),"The cottage must be built from physical stones")
	assert(house.region_centre("LoadBeam").distance_to(house.beam_baseline)<6,"House must stand in the actual village")
	for body in house.region("LoadBeam"):
		assert(absf(body.rotation)<0.06,"Roof supports must remain level before a shot")
	assert(not house._collapsed,"Settlement alone must not destroy a house")
	for piece in house.pieces:
		assert(not piece.released and piece.has_node("Skin"))
	await capture("village_physics_before")
	var roof_y: float = house.region_centre("RoofLeft").y
	world.get_node("Knight")._fire(Vector2(800,90))
	await steps(75)
	await capture("village_physics_impact")
	assert(not impacts.is_empty() and impacts[0].target == &"VillageHouse","Real cannon must hit the physical house")
	assert(get_tree().get_nodes_in_group("active_projectiles").is_empty(),"The round must detonate on the masonry, not drive through it")
	await steps(300)
	await capture("village_physics_after")
	var shards := get_tree().get_nodes_in_group("stone_shards").size()
	var roof_left: Array = house.region("RoofLeft")
	var drop: float = (house.region_centre("RoofLeft").y-roof_y) if not roof_left.is_empty() else INF
	print("VILLAGE_PHYSICS shards=",shards," roof_drop=",drop," standing=",house.masonry.standing(),"/",house.pieces.size()," collapsed=",house._collapsed)
	# The struck side must be gone: either broken into shards or sunk into the hole.
	for row in range(1,5):
		for struck in house.region("LeftWall%d" % row):
			assert(struck.released,"The struck courses must come out of the wall")
	assert(shards >= 6,"Cratered stone must break into shards, not leave as slabs")
	# The anti-billiards guarantee: masonry the blast never reached, and that kept
	# its support, must not have budged at all.
	for row in range(5):
		var standing_far: Array = house.region("RightWall%d" % row)
		assert(not standing_far.is_empty(),"The far wall must survive a hit it never took")
		for far in standing_far:
			assert(not far.released,"The far wall must not come loose")
			assert(far.position.is_equal_approx(house.initial[far.name]),"The far wall must not be shoved aside")
	# The far wall and the door still carry the beam, so the roof stays up. That is
	# the approved rule: a round opens a hole, it does not flatten the cottage.
	assert(drop < 40.0,"One round must leave the roof carried by what is left")
	assert(not house._collapsed,"One round must leave the cottage standing, not flatten it")
	assert(not events.any(func(e):return e.type=="STRUCTURE_DESTROYED" and e.target=="VillageHouse"),"A hole is damage, not destruction")
	assert(events.any(func(e):return e.type=="STRUCTURE_HIT" and e.target=="VillageHouse"),"The hole must still report damage")
	# Taking out the surviving support finishes the cottage off.
	for shot in range(4):
		var wall: Array = house.region("RightWall%d" % (4-shot)) if shot < 4 else []
		if wall.is_empty():
			wall = house.region("LoadBeam")
		if wall.is_empty():
			continue
		var target: RigidBody2D = wall[0]
		var finisher = load("res://scenes/projectile.tscn").instantiate()
		finisher.position = target.global_position+Vector2(140,0)
		finisher.linear_velocity = Vector2(-1700,0)
		world.add_child(finisher)
		for other in get_tree().get_nodes_in_group("structures"):
			if other is PhysicsBody2D:
				finisher.add_collision_exception_with(other)
		await steps(180)
	await steps(240)
	var roof_gone: bool = house.region("RoofLeft").is_empty()
	var roof_fell: float = 0.0 if roof_gone else house.region_centre("RoofLeft").y-roof_y
	print("VILLAGE_PHYSICS after finishers: standing=",house.masonry.standing(),"/",house.pieces.size()," shards=",get_tree().get_nodes_in_group("stone_shards").size()," collapsed=",house._collapsed," roof_gone=",roof_gone," roof_fell=",roof_fell)
	assert(roof_gone or roof_fell > 30.0,"With both supports gone the roof must come down or break up")
	assert(house._collapsed,"Losing both supports must bring the cottage down")
	assert(events.any(func(e):return e.type=="STRUCTURE_DESTROYED" and e.target=="VillageHouse"))
	for piece in house.pieces:
		if is_instance_valid(piece):
			assert(is_finite(piece.global_position.x) and piece.global_position.y<850,"Rubble must collide with the ground")
	for node in get_tree().get_nodes_in_group("stone_shards"):
		assert(is_finite(node.global_position.x) and node.global_position.y<900,"Shards must collide with the ground")
	print("PASS: art on physical bodies; one round opens a hole and the cottage sags; stone breaks into shards; far wall untouched; repeated hits bring it down; social events")
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
