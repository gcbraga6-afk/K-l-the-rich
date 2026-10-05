extends Node

# No piece of a building may end up frozen in the sky.
#
# Damping used to build with the time a piece had been loose, in flight as well as
# at rest, so a piece thrown hard upward slowed to a hover; a deadline then froze
# it wherever it was, and the kingdom kept a cloud of rubble hanging over it.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(240)
	var target = world.get_node("Village").front_houses[2]
	var house = target.get_node("PhysicalHouse")
	var facade = house.facade
	# Several rounds into one cottage, which is what throws debris highest.
	for spot in [Vector2(0.4, 0.12), Vector2(0.3, 0.45), Vector2(0.55, 0.3)]:
		house.damage_near(2, facade.to_global(facade.base_offset
			+ Vector2(facade.art.get_width() * spot.x, facade.art.get_height() * spot.y) * facade.pixel), 1.0)
		await steps(60)
	var ground: float = facade.to_global(facade.base_offset
		+ Vector2(0.0, facade.art.get_height()) * facade.pixel).y
	# A piece dropped from rest, watched for half a second of clear air. Damping
	# meant for settling used to apply in flight as well, which bled the fall away
	# and left masonry drifting down like paper: with the old damping this reads
	# about 455, with masonry weight and no drag in flight about 980.
	# Timed in seconds, not in frames. Counted in frames this measured half a second
	# at 120 Hz and a whole one at 60 Hz, by which point the piece had already landed
	# and the number read was the speed after the impact.
	var probe := _launch(world, facade.to_global(facade.base_offset) + Vector2(0, -620), Vector2.ZERO)
	var flown := 0.0
	var tick := 1.0 / float(Engine.physics_ticks_per_second)
	while flown < 0.5:
		await get_tree().physics_frame
		if not is_instance_valid(probe) or probe.get_contact_count() > 0:
			break
		flown += tick
		assert(not probe.sleeping, "A piece must not fall asleep in mid air")
		assert(not probe.freeze, "A piece must not freeze in mid air")
	assert(is_instance_valid(probe), "The probe must still be falling")
	print("PROBE fall speed=", probe.linear_velocity.y, " after ", flown, "s of clear air")
	assert(flown >= 0.5, "The probe must get its clear air, or the number means nothing")
	assert(probe.linear_velocity.y > 850.0, "Masonry must fall like masonry, not drift")
	probe.queue_free()
	# A piece thrown far spends seconds in the air before it lands. Settling time
	# used to run from the blast, so that piece touched down already thick with
	# damping and oozed to a halt instead of clattering. Thrown high, then caught
	# the moment it first touches something: its drag must still be the drag of a
	# piece that has only just landed.
	var tossed := _launch(world, facade.to_global(facade.base_offset) + Vector2(60, -700), Vector2(0, -1000))
	var landed_damp := -1.0
	for look in range(600):
		await get_tree().physics_frame
		if not is_instance_valid(tossed):
			break
		if tossed.get_contact_count() > 0:
			landed_damp = tossed.linear_damp
			break
	print("TOSSED age=", tossed._age, " damp on landing=", landed_damp)
	assert(landed_damp >= 0.0, "The tossed piece must land on something")
	# Long enough that, counted from the blast as it used to be, the piece would have
	# landed with well over 1.0 of drag against the 0.4 this allows.
	assert(tossed._age > 1.2, "The toss must be a long one, or it tests nothing")
	assert(landed_damp < 0.4, "A piece must land free to clatter, not into molasses")
	tossed.queue_free()
	# Long enough for anything thrown to have come down and settled.
	await steps(600)
	# Asking where a piece is cannot answer this. Height above the rooftops called
	# rubble resting on a roof a fault and missed rubble stopped under the eaves. A
	# ray cast down from the piece's middle accused stone nestled into the hillside,
	# because a ray starting inside a collider reports no hit; moved above the piece,
	# the same ray ran straight through the wall a piece was pinned against and
	# called that wall its support.
	#
	# The honest question is physical: let the piece go, and see whether it falls.
	# Stone lying on the ground stays where it is. Stone held up by nothing, or
	# pinned to the side of a house in open air, drops.
	var stopped: Array = []
	var was_at := {}
	for shard in get_tree().get_nodes_in_group("stone_shards"):
		if not is_instance_valid(shard):
			continue
		if shard.freeze or shard.sleeping or shard.linear_velocity.length() < 12.0:
			stopped.append(shard)
			was_at[shard] = shard.global_position
	var total: int = get_tree().get_nodes_in_group("stone_shards").size()
	for shard in stopped:
		shard.set_physics_process(false)
		shard.set_deferred("freeze", false)
		shard.set_deferred("sleeping", false)
	await steps(30)
	var hanging := 0
	for shard in stopped:
		if not is_instance_valid(shard):
			continue
		var dropped: float = shard.global_position.y - was_at[shard].y
		if dropped > 26.0:
			hanging += 1
			if hanging <= 3:
				print("  HANGING at ", was_at[shard], " fell ", dropped, " once released")
	print("SETTLING total=", total, " stopped=", stopped.size(), " hanging=", hanging, " ground=", ground)
	assert(total > 0, "The rounds must have thrown some rubble")
	assert(hanging == 0, "No piece may freeze in mid air")
	print("PASS: every piece thrown by a round comes down and settles on something")
	get_tree().quit()

# One piece of stone, thrown by hand, so the arc under test is a known one.
func _launch(world: Node, at: Vector2, velocity: Vector2) -> RigidBody2D:
	var body := RigidBody2D.new()
	body.set_script(load("res://scripts/destruction/stone_shard.gd"))
	var chunk := PackedVector2Array([Vector2(-7, -5), Vector2(7, -6), Vector2(8, 5), Vector2(-6, 6)])
	body.shard = chunk
	body.generation = 2
	body.mass = 1.0
	body.collision_layer = 8
	body.collision_mask = 1 | 8
	var collider := CollisionShape2D.new()
	var convex := ConvexPolygonShape2D.new()
	convex.points = chunk
	collider.shape = convex
	body.add_child(collider)
	world.add_child(body)
	body.global_position = at
	body.linear_velocity = velocity
	return body

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
