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
	# The dazzle is the point of the round, so the test has to look at it while it is
	# there. A broken shader let this pass green with nothing on screen at all.
	var dazzle = get_tree().current_scene.get_node_or_null("FlashDazzle")
	assert(dazzle != null, "A flash must dazzle whoever is watching")
	var shader: Shader = dazzle._ghost.material.shader
	assert(shader != null and shader.code.contains("hint_screen_texture"),
		"The after-image shader must read the screen the way this engine offers it")
	assert(dazzle._sheet.color.a > 0.5, "The screen must go white at the burst")
	# And the eyes must come back: the white lifts and the smear takes over.
	await steps(90)
	assert(dazzle._sheet.color.a < 0.05, "The white must lift")
	assert(dazzle._ghost.material.get_shader_parameter("strength") > 0.1,
		"The after-image must be there once the white has gone")
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
	print("PASS: the flash reaches the street, dazzles the screen and breaks nothing")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
