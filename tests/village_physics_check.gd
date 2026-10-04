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
	await get_tree().create_timer(4).timeout
	assert(absf(beam.position.y-house.initial["LoadBeam"].y)<6,"House must stand in the actual village")
	assert(absf(beam.rotation)<0.06,"Roof supports must remain level before a shot")
	assert(not house._collapsed,"Settlement alone must not destroy a house")
	for piece in house.pieces:
		assert(not piece.freeze and piece.has_node("Skin"))
	await capture("village_physics_before")
	var roof_y: float = roof.global_position.y
	var support_start: Vector2 = support.global_position
	world.get_node("Knight")._fire(Vector2(800,90))
	await get_tree().create_timer(1.25).timeout
	await capture("village_physics_impact")
	assert(not impacts.is_empty() and impacts[0].target == &"VillageHouse","Real cannon must hit the physical house")
	assert(get_tree().get_nodes_in_group("active_projectiles").size()==1,"Ball must survive physical contact and transfer momentum")
	await get_tree().create_timer(5).timeout
	await capture("village_physics_after")
	var displacement: float = support.global_position.distance_to(support_start)
	var drop: float = roof.global_position.y-roof_y
	print("VILLAGE_PHYSICS displacement=",displacement," roof_drop=",drop," beam_rotation=",beam.rotation," collapsed=",house._collapsed)
	assert(displacement>30,"Impact must move the supporting wall")
	assert(drop>30 or absf(roof.rotation)>0.3,"Roof must physically fall or rotate after support loss")
	assert(house._collapsed,"Actual structural movement must report collapse to the game")
	assert(events.any(func(e):return e.type=="STRUCTURE_DESTROYED" and e.target=="VillageHouse"))
	assert(house.pieces.size()==14,"All original pieces must remain as debris")
	for piece in house.pieces:
		assert(is_finite(piece.global_position.x) and piece.global_position.y<850,"Debris must collide with the ground")
	print("PASS: art on physical bodies; stable village placement; real cannon impact; persistent gravity-driven collapse; social event")
	get_tree().quit()

func capture(id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/%s.png" % id)
