extends Node

# A real cannon round fired into a roof: it detonates there, carves the span out
# and reports the damage, and the cottage underneath goes on standing.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(3).timeout
	var house = world.get_node("Structures/VillageHouse")
	var physical = house.get_node("PhysicalHouse")
	var facade = physical.facade
	var whole: float = physical.standing_ratio()
	var ball = load("res://scenes/projectile.tscn").instantiate()
	ball.position = facade.to_global(facade.base_offset
		+ Vector2(facade.art.get_width() * 0.45, facade.art.get_height() * 0.2) * facade.pixel) + Vector2(-10, -110)
	ball.linear_velocity = Vector2(0, 500)
	world.add_child(ball)
	await get_tree().create_timer(1.5).timeout
	var left: float = physical.standing_ratio()
	print("ROOF_HIT standing=", left, " was=", whole, " integrity=", house._integrity, "/", house.max_integrity)
	assert(physical._hit_reported, "A real projectile must register contact with the roof")
	assert(house._integrity < house.max_integrity)
	assert(not is_instance_valid(ball), "The round must detonate on the masonry, not drive through it")
	assert(left < whole, "The round must carve the roof it landed in")
	assert(left > 0.5, "One round into a roof must not level the cottage")
	print("PASS: real projectile detonates on the roof, carves it and reports localized damage")
	get_tree().quit()
