extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(3).timeout
	var house = world.get_node("Village").front_houses[2]
	var physical = house.get_node("PhysicalHouse")
	var roof = physical.get_node("RoofLeft")
	var baseline: Vector2 = roof.position
	var flash = load("res://scenes/projectile.tscn").instantiate()
	flash.weapon = "Flash"
	flash.position = physical.get_node("LeftWall4").global_position-Vector2(45,0)
	flash.linear_velocity = Vector2(1800,0)
	world.add_child(flash)
	for other in get_tree().get_nodes_in_group("structures"):
		if other is PhysicsBody2D:
			flash.add_collision_exception_with(other)
	await get_tree().create_timer(2).timeout
	assert(not is_instance_valid(flash),"Flash must detonate on physical masonry")
	assert(not physical._hit_reported and not physical._collapsed,"Flash must not cause structural damage")
	assert(house._integrity==house.max_integrity)
	assert(roof.position.distance_to(baseline)<3,"Flash must not impart destructive momentum")
	print("PASS: Flash detonates at masonry without pushing or damaging physical buildings")
	get_tree().quit()
