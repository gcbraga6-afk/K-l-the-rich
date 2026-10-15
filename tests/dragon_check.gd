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
	var aloft: Array = get_tree().get_nodes_in_group("propaganda_dragons")
	assert(aloft.size() == 1, "A dragon must take off, and only one")
	var dragon = aloft[0]
	var terrain_depth: int = world.get_node("Terraces").z_index
	assert(dragon.z_index < terrain_depth,
		"The dragon must fly behind the terrain, or it cannot fall behind the plateau")
	# Behind the tree line: it belongs to the far landscape, and the near woodland
	# must pass in front of it.
	var landscape = world.get_node("Landscape")
	assert(dragon.get_parent() == landscape, "The dragon belongs to the far landscape")
	assert(dragon.get_index() < landscape.get_node("WoodlandDepth").get_index(),
		"The trees must cross in front of the dragon")
	assert(dragon.get_index() > landscape.get_node("ValleyDepth").get_index(),
		"The dragon must still read in front of the far valley")
	var hitbox = dragon.get_node("Hitbox")
	assert(hitbox.collision_layer == 16, "A round must be able to find the dragon")
	# The whole creature and its banner must be a target. A box over the shoulder
	# left most of it unhittable, and the player could not bring one down.
	var box: RectangleShape2D = hitbox.get_node("CollisionShape2D").shape \
		if hitbox.get_child_count() > 0 else null
	var reach: float = dragon.FRAME.x * dragon.art_scale
	assert(box != null and box.size.x > reach * 0.85,
		"The hitbox must cover the dragon and the banner it tows")
	# And it must fly where the sky is, not where the rooftops are.
	assert(dragon.position.y < 0.0, "The dragon must fly high in the frame")
	# Being hittable is not the same as being damageable: a blast only reaches what
	# is in the structures group, and it asks each member where it is first.
	assert(dragon.is_in_group("structures"), "A blast must be able to reach the dragon")
	assert(dragon.has_method("closest_point"), "and must be able to ask where it is")
	# The real path: a blast beside it, not a method called by hand.
	var blast = load("res://scenes/explosion.tscn").instantiate()
	world.add_child(blast)
	blast.global_position = dragon.closest_point(dragon.global_position)
	blast._apply_damage()
	await steps(6)
	assert(dragon.falling, "A round that reaches the dragon must bring it down")
	blast.queue_free()
	dragon.queue_free()
	await steps(4)
	sky._next = 0.0
	await steps(6)
	dragon = get_tree().get_nodes_in_group("propaganda_dragons")[0]
	await steps(30)
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
