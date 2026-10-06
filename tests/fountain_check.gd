extends Node

# The fountain runs, and three rounds leave it standing and dry — which is the
# point. The village can see what was taken and what is left.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(120)
	var fountain = world.get_node("Structures/VillageFountain")
	assert(fountain != null, "The village must have its fountain")
	var ground: float = preload("res://scripts/world/terraces.gd").walking_y(2210.0)
	var factor: float = fountain.stone_height / fountain.FLOW_HEIGHT
	var foot: float = fountain.position.y + fountain.FLOW_FOOT * factor
	assert(absf(foot - ground) < 2.0, "The stone must stand on the street, not float")
	# The water must move and the stone must not. The flowing frames were redrawn on
	# one unchanging fountain, so the stone needs no shift — but a future sheet drawn
	# out of register would shiver the whole thing, which is what happened before.
	var seen := {}
	var stone_at := {}
	for i in range(40):
		await steps(6)
		seen[fountain.sprite.texture.region.position.x] = true
		stone_at[snappedf(fountain.sprite.position.x + 78.0 * fountain.sprite.scale.x, 0.01)] = true
	assert(seen.size() >= 3, "All three jets must be used")
	assert(stone_at.size() == 1, "The stone must hold still while the water runs")
	assert(not fountain.dry, "A fountain nobody shot must have water")
	print("FOUNTAIN running, ", seen.size(), " states of flow")
	# Everything in the structures group must answer what a blast asks of it. The
	# fountain joined that group with only apply_explosion_damage, so the first
	# round fired in the real game crashed on the missing closest_point.
	for node in get_tree().get_nodes_in_group("structures"):
		assert(node.has_method("closest_point"),
			"%s is in the structures group but cannot be asked where it is" % node.name)
		assert(node.has_method("apply_explosion_damage"),
			"%s is in the structures group but cannot be damaged" % node.name)
	var reach: Vector2 = fountain.closest_point(fountain.global_position + Vector2(400, 0))
	assert(reach.x < fountain.global_position.x + 400.0, "The fountain must report its own edge")
	# A real round, through the real blast. Every test here called
	# apply_explosion_damage by hand, which exercises the method I remembered to
	# write rather than the path the game takes — and the game crashed on the first
	# shot while ten tests stayed green.
	# The real scene, not a bare node wearing the script: an explosion expects the
	# children its scene gives it, and building one by hand tests a different thing.
	var blast = load("res://scenes/explosion.tscn").instantiate()
	world.add_child(blast)
	blast.global_position = fountain.global_position + Vector2(0, -40)
	blast._apply_damage()
	await steps(10)
	assert(fountain._integrity < fountain.max_integrity, "A real blast must reach the fountain")
	blast.queue_free()
	var said := ""
	var broadcast = world.get_node("Structures/Mirror/Broadcast")
	for hit in range(3):
		fountain.apply_explosion_damage(1, fountain.global_position)
		await steps(10)
	assert(fountain.dry, "Three rounds must take the water")
	assert(fountain.sprite.texture.atlas == fountain.DRY_SHEET, "A broken fountain shows the dry stone")
	# Matched on the stone's height and on the ground, so drying does not make the
	# fountain jump or change size.
	var dry_factor: float = fountain.stone_height / fountain.DRY_HEIGHT
	var dry_foot: float = fountain.position.y + fountain.sprite.position.y + fountain.DRY_FOOT * dry_factor
	assert(absf(dry_foot - ground) < 3.0, "The dry fountain must stand on the same stone")
	await steps(30)
	said = broadcast.current_message
	print("FOUNTAIN dry, mirror says: ", said.replace("\n", " "))
	assert(said.contains("taken"), "The Crown must say who took the water")
	print("PASS: the fountain runs, takes three rounds, and stands there dry")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
