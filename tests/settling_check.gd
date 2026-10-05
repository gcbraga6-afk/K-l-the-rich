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
	# Long enough for anything thrown to have come down and settled.
	await steps(600)
	var ground: float = facade.to_global(facade.base_offset
		+ Vector2(0.0, facade.art.get_height()) * facade.pixel).y
	var hanging := 0
	var total := 0
	for shard in get_tree().get_nodes_in_group("stone_shards"):
		if not is_instance_valid(shard):
			continue
		total += 1
		# Well clear of the rooftops: rubble resting on a roof is fine, rubble
		# stopped in open sky is not.
		if shard.freeze and shard.global_position.y < ground - 320.0:
			hanging += 1
			if hanging <= 3:
				print("  HANGING at ", shard.global_position, " ground=", ground)
	print("SETTLING total=", total, " hanging=", hanging)
	assert(total > 0, "The rounds must have thrown some rubble")
	assert(hanging == 0, "No piece may freeze in mid air")
	print("PASS: every piece thrown by a round comes down and settles on something")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
