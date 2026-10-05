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
	# about 455, with masonry weight and no drag in flight about 780.
	var probe := _launch(world, facade.to_global(facade.base_offset) + Vector2(0, -620), Vector2.ZERO)
	for look in range(60):
		await get_tree().physics_frame
		if not is_instance_valid(probe):
			break
		assert(not probe.sleeping, "A piece must not fall asleep in mid air")
		assert(not probe.freeze, "A piece must not freeze in mid air")
	assert(is_instance_valid(probe), "The probe must still be falling")
	print("PROBE fall speed=", probe.linear_velocity.y, " at ", probe.global_position.y)
	assert(probe.linear_velocity.y > 600.0, "Masonry must fall like masonry, not drift")
	probe.queue_free()
	# Long enough for anything thrown to have come down and settled.
	await steps(600)
	var hanging := 0
	var total := 0
	for shard in get_tree().get_nodes_in_group("stone_shards"):
		if not is_instance_valid(shard):
			continue
		total += 1
		# Well clear of the rooftops: rubble resting on a roof is fine, rubble
		# stopped in open sky is not. Asleep counts as stopped, because a sleeping
		# body is not being simulated at all.
		var stopped: bool = shard.freeze or shard.sleeping or shard.linear_velocity.length() < 12.0
		if stopped and shard.global_position.y < ground - 320.0:
			hanging += 1
			if hanging <= 3:
				print("  HANGING at ", shard.global_position, " frozen=", shard.freeze,
					" asleep=", shard.sleeping, " v=", shard.linear_velocity.length())
	print("SETTLING total=", total, " hanging=", hanging)
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
