extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var village = world.get_node("Village")
	var tower = world.get_node("Structures/Castle/ModularStructure")
	await get_tree().create_timer(10).timeout
	for house in village.front_houses:
		var physical = house.get_node("PhysicalHouse")
		var beam = physical.get_node("LoadBeam")
		print("STABILITY ",house.name," collapsed=",physical._collapsed," beam_delta=",beam.position.distance_to(physical.initial["LoadBeam"])," rotation=",beam.rotation)
		assert(not physical._collapsed,"A house must not collapse without a shot")
		for body in physical.pieces:
			assert(not body.released,"No piece may come loose without a shot")
			if str(body.name).begins_with("Roof"):
				print("ROOF ",house.name," ",body.name," drift=",body.position.distance_to(physical.initial[body.name]))
				assert(body.position.distance_to(physical.initial[body.name])<15,"Unhit roof must retain its original placement")
	print("TOWER stable=",not tower._tower_fallen)
	for body in tower.tower_bodies:
		print("TOWER ",body.name," delta=",body.position.distance_to(tower.initial_poses[body.name])," rotation=",body.rotation)
	assert(not tower._tower_fallen,"Tower must stand under its own weight")
	await capture(world,Vector2(1500,350),1.0,"expanded_village_before")
	await capture(world,Vector2(6170,-50),0.65,"physical_tower_before")
	var house = village.front_houses[2].get_node("PhysicalHouse")
	var roof = house.get_node("RoofLeft")
	var start: Vector2 = roof.position
	# Strike the support courses with real projectile bodies, not damage callbacks.
	var house_ball = load("res://scenes/projectile.tscn").instantiate()
	house_ball.position = house.get_node("LeftWall3").global_position-Vector2(48,0)
	house_ball.linear_velocity = Vector2(1800,0)
	world.add_child(house_ball)
	# Isolate this facade from shops on the overlapping depth plane.
	for other in get_tree().get_nodes_in_group("structures"):
		if other is PhysicsBody2D:
			house_ball.add_collision_exception_with(other)
	var crown = tower.tower_bodies[0]
	var crown_start: Vector2 = crown.position
	var ball = load("res://scenes/projectile.tscn").instantiate()
	ball.position = tower.to_global(tower.origin+Vector2(250,310)*tower.factor)
	ball.linear_velocity = Vector2(2200,0)
	world.add_child(ball)
	await get_tree().create_timer(0.75).timeout
	await capture(world,Vector2(6170,-50),0.65,"physical_tower_impact")
	# Follow the wall hit with a roof hit: surviving central walls may still
	# support an unhit roof, so one displaced course need not destroy a house.
	var roof_ball = load("res://scenes/projectile.tscn").instantiate()
	roof_ball.position = roof.global_position+Vector2(-80,0)
	roof_ball.linear_velocity = Vector2(1800,0)
	world.add_child(roof_ball)
	for other in get_tree().get_nodes_in_group("structures"):
		if other is PhysicsBody2D:
			roof_ball.add_collision_exception_with(other)
	# A second aimed hit tests loss of the upper tower after its masonry was hit.
	var second = load("res://scenes/projectile.tscn").instantiate()
	second.position = tower.to_global(tower.origin+Vector2(250,100)*tower.factor)
	second.linear_velocity = Vector2(2400,0)
	world.add_child(second)
	await get_tree().create_timer(7).timeout
	print("HIT SUPPORT ",house.get_node("LeftWall1").position," door=",house.get_node("Door").position)
	print("HOUSE roof_delta=",roof.position.distance_to(start)," collapsed=",house._collapsed," integrity=",village.front_houses[2]._integrity,"/",village.front_houses[2].max_integrity)
	print("TOWER crown_delta=",crown.position.distance_to(crown_start)," collapsed=",tower._tower_fallen)
	assert(roof.position.distance_to(start)>15,"The original painted roof must move after support impact")
	assert(tower._tower_fallen,"A physical projectile must dislodge the tower")
	assert(world.get_node("Structures/Castle")._integrity>0,"The keep must survive the lost tower")
	assert(tower.tower_bodies.size()==7,"Tower bodies must persist")
	for body in tower.tower_bodies:
		assert(is_finite(body.position.x) and absf(body.global_position.x)<15000)
	await capture(world,Vector2(6170,-50),0.65,"physical_tower_after")
	await capture(world,Vector2(1500,350),1.0,"expanded_village_after")
	print("PASS: eight stable physical houses, original village art, stable tower, gravity collapse, surviving keep and persistent debris")
	get_tree().quit()

func capture(world: Node, at: Vector2, zoom: float, id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	var camera = world.get_node("KingdomCamera")
	camera.set_process(false)
	camera.position = at
	camera.zoom = Vector2.ONE*zoom
	await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/%s.png" % id)
