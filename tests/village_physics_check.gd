extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var house = world.get_node("Structures/VillageHouse/PhysicalHouse")
	var beam = house.get_node("LoadBeam")
	var roof = house.get_node("RoofLeft")
	var support = house.get_node("LeftWall1")
	var events: Array = []
	var impacts: Array = []
	EventBus.world_event.connect(func(event: Dictionary): events.append(event))
	EventBus.projectile_impacted.connect(func(event: Dictionary): impacts.append(event))
	await steps(240)
	assert(absf(beam.position.y-house.initial["LoadBeam"].y)<6,"House must stand in the actual village")
	assert(absf(beam.rotation)<0.06,"Roof supports must remain level before a shot")
	assert(not house._collapsed,"Settlement alone must not destroy a house")
	for piece in house.pieces:
		assert(not piece.released and piece.has_node("Skin"))
	await capture("village_physics_before")
	var roof_y: float = roof.global_position.y
	var support_start: Vector2 = support.global_position
	world.get_node("Knight")._fire(Vector2(800,90))
	await steps(75)
	await capture("village_physics_impact")
	assert(not impacts.is_empty() and impacts[0].target == &"VillageHouse","Real cannon must hit the physical house")
	assert(get_tree().get_nodes_in_group("active_projectiles").is_empty(),"The round must detonate on the masonry, not drive through it")
	await steps(300)
	await capture("village_physics_after")
	var displacement: float = support.global_position.distance_to(support_start)
	var drop: float = roof.global_position.y-roof_y
	print("VILLAGE_PHYSICS displacement=",displacement," roof_drop=",drop," beam_rotation=",beam.rotation," collapsed=",house._collapsed)
	# One round opens a hole and the cottage sags onto what is left. It does not
	# flatten: the struck course comes down, the far wall still carries the roof.
	for row in range(4):
		var fallen: RigidBody2D = house.get_node("LeftWall%d" % row)
		assert(fallen.released,"The struck course must come out of the wall")
		assert(fallen.position.y > house.initial[fallen.name].y + 8 or row == 0,"Masonry above the crater must come down")
	for row in range(5):
		var far: RigidBody2D = house.get_node("RightWall%d" % row)
		assert(not far.released,"The far wall must not come loose from a hit it never took")
		assert(far.position.is_equal_approx(house.initial[far.name]),"The far wall must not be shoved aside")
	assert(drop > 4.0,"The roof must visibly sag onto the surviving wall")
	assert(not house._collapsed,"One round must leave the cottage standing, not flatten it")
	assert(not events.any(func(e):return e.type=="STRUCTURE_DESTROYED" and e.target=="VillageHouse"),"A hole is damage, not destruction")
	assert(events.any(func(e):return e.type=="STRUCTURE_HIT" and e.target=="VillageHouse"),"The hole must still report damage")
	# Taking out the surviving support finishes the cottage off.
	for shot in range(2):
		var finisher = load("res://scenes/projectile.tscn").instantiate()
		finisher.position = house.get_node("RightWall%d" % (4-shot)).global_position+Vector2(140,0)
		finisher.linear_velocity = Vector2(-1700,0)
		world.add_child(finisher)
		for other in get_tree().get_nodes_in_group("structures"):
			if other is PhysicsBody2D:
				finisher.add_collision_exception_with(other)
		await steps(180)
	await steps(240)
	print("VILLAGE_PHYSICS after finishers: beam_rotation=",beam.rotation," collapsed=",house._collapsed)
	assert(house._collapsed,"Losing both supports must bring the cottage down")
	assert(events.any(func(e):return e.type=="STRUCTURE_DESTROYED" and e.target=="VillageHouse"))
	assert(house.pieces.size()==14,"All original pieces must remain as debris")
	for piece in house.pieces:
		assert(is_finite(piece.global_position.x) and piece.global_position.y<850,"Debris must collide with the ground")
	print("PASS: art on physical bodies; one round opens a hole and the cottage sags; far wall untouched; repeated hits bring it down; social events")
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
