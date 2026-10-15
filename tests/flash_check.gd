extends Node

# A flash is for the people, and the people are in the street. It must reach the
# street whatever stands between — over a roof, in front of a wall, behind one.

const Terraces = preload("res://scripts/world/terraces.gd")

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(90)
	var knight = world.get_node("Knight")
	var where := []
	EventBus.projectile_impacted.connect(func(event): where.append(event))
	# Lobbed straight at the village roofs. A round that stops on a rooftop never
	# reaches anybody.
	knight.weapon = "Flash"
	knight._ammo = 99
	knight._fire(Vector2(1500, -1100))
	for wait in range(900):
		await get_tree().physics_frame
		if not where.is_empty():
			break
	assert(not where.is_empty(), "The flash must go off somewhere")
	var hit: Dictionary = where[0]
	print("FLASH burst at ", hit.position, " on ", hit.target)
	assert(hit.target == "Street", "A flash must burst on the street, not on a building")
	var street: float = Terraces.walking_y(hit.position.x)
	assert(absf(hit.position.y - street) < 40.0,
		"The flash must burst at the height the kingdom walks on, not above it")
	# And it must carry no structural damage: the Crown gets no rubble to point at.
	var house = world.get_node("Village").front_houses[2]
	var before: float = house.get_node("PhysicalHouse").facade.standing_ratio()
	knight._fire(Vector2(1500, -1100))
	await steps(240)
	assert(is_equal_approx(house.get_node("PhysicalHouse").facade.standing_ratio(), before),
		"A flash must leave the masonry alone")
	print("PASS: the flash reaches the street and breaks nothing")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
