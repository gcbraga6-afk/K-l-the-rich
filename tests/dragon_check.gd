extends Node

# The dragon carries the Crown's voice across the sky, can be shot down, and goes
# down behind the plateau rather than crashing into the street.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(60)
	var sky = world.get_node("PropagandaSky")
	# Rather than wait out the patrol, send one up at once.
	sky._next = 0.0
	await steps(4)
	var dragon = sky.get_child(0)
	assert(dragon != null, "A dragon must take off")
	var terrain_depth: int = world.get_node("Terraces").z_index
	assert(dragon.z_index < terrain_depth,
		"The dragon must fly behind the terrain, or it cannot fall behind the plateau")
	var hitbox = dragon.get_node("Hitbox")
	assert(hitbox.collision_layer == 16, "A round must be able to find the dragon")
	var started: float = dragon.position.x
	await steps(90)
	# It is drawn facing left with the banner trailing right, so it must travel
	# left. Sent the other way it flew backwards, towing its own banner ahead of it.
	assert(dragon.position.x < started, "The dragon must fly the way it faces")
	assert(dragon.DRIFT < 0.0, "The art faces left, so the drift must be leftward")
	print("DRAGON flying, depth ", dragon.z_index, " against terrain ", terrain_depth)
	var height: float = dragon.position.y
	dragon.apply_explosion_damage(2, dragon.global_position)
	assert(dragon.falling, "A round in the banner brings it down")
	assert(dragon.get_node("Hitbox").collision_layer == 0,
		"A falling dragon must not be shot a second time")
	# The tumble is drawn art, so the falling sheet must actually be on screen and
	# the banner must be re-cut to follow the cloth as the pose changes.
	assert(dragon.sprite.texture.atlas == dragon.FALLING_SHEET,
		"A falling dragon must wear the falling poses")
	var cut: int = dragon._shown
	var cloth_before: PackedVector2Array = dragon.banner.polygon
	await steps(120)
	assert(dragon._shown != cut or not dragon.banner.polygon.is_equal_approx(cloth_before),
		"The banner must follow the cloth through the tumble")
	assert(dragon.position.y > height + 120.0, "A downed dragon must go down")
	print("DRAGON downed, fell ", int(dragon.position.y - height), " behind the plateau")
	# It must clear itself away rather than pile up under the world.
	await steps(300)
	assert(not is_instance_valid(dragon) or dragon.is_queued_for_deletion(),
		"The wreck must not be left hanging under the kingdom")
	print("PASS: the dragon crosses the sky, takes a round, and falls out of sight")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
