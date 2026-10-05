extends Node

# Flash is a scare round. It detonates on masonry like any other, but it must not
# take a bite out of a building or report one.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().create_timer(3).timeout
	var house = world.get_node("Village").front_houses[2]
	var physical = house.get_node("PhysicalHouse")
	var whole: float = physical.standing_ratio()
	var flash = load("res://scenes/projectile.tscn").instantiate()
	flash.weapon = "Flash"
	flash.position = physical.facade.to_global(physical.facade.base_offset
		+ Vector2(physical.facade.art.get_width() * 0.5, physical.facade.art.get_height() * 0.6) * physical.facade.pixel)
	flash.position.x -= 220.0
	flash.linear_velocity = Vector2(1800, 0)
	world.add_child(flash)
	for other in get_tree().get_nodes_in_group("structures"):
		if other is PhysicsBody2D:
			flash.add_collision_exception_with(other)
	await get_tree().create_timer(2).timeout
	assert(not is_instance_valid(flash), "Flash must detonate on masonry")
	assert(not physical._hit_reported and not physical._collapsed, "Flash must not cause structural damage")
	assert(house._integrity == house.max_integrity)
	print("FLASH standing=", physical.standing_ratio(), " was=", whole)
	assert(is_equal_approx(physical.standing_ratio(), whole), "Flash must not take any material out of a wall")
	print("PASS: Flash detonates at masonry without carving or damaging buildings")
	get_tree().quit()
