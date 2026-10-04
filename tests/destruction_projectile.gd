extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(3).timeout
	var house = world.get_node("Structures/VillageHouse")
	var physical = house.get_node("PhysicalHouse")
	var ball = load("res://scenes/projectile.tscn").instantiate()
	ball.position = physical.get_node("RoofLeft").global_position+Vector2(-10,-100)
	ball.linear_velocity = Vector2(0,500)
	world.add_child(ball)
	await get_tree().create_timer(1.5).timeout
	assert(physical._hit_reported,"A real projectile must register contact with the roof")
	assert(house._integrity < house.max_integrity)
	assert(is_instance_valid(ball),"The cannonball must survive contact with physical masonry")
	assert(physical.pieces.size()==14,"Impact must preserve the original physical pieces")
	print("PASS: real projectile hits the roof, transfers momentum and reports localized damage")
	get_tree().quit()
