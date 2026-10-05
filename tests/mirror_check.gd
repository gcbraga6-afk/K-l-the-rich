extends Node

# The mirror is the kingdom's voice, so how many rounds silence it is a design
# number, not an accident: three.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(240)
	var mirror = world.get_node("Structures/Mirror")
	var broadcast = mirror.get_node_or_null("Broadcast")
	assert(mirror.visible, "The mirror must stand where a round can reach it")
	assert(mirror.collision_layer == 1, "The mirror must be solid")
	assert(broadcast != null, "The mirror must be broadcasting")
	print("MIRROR integrity=", mirror._integrity, " at ", mirror.global_position)
	var hits := 0
	while mirror._integrity > 0 and hits < 10:
		hits += 1
		mirror.apply_explosion_damage(1, mirror.global_position + Vector2(0, -40))
		await steps(4)
		print("  hit ", hits, " -> integrity ", mirror._integrity)
	assert(hits == 3, "Three rounds must silence the mirror, not %d" % hits)
	await steps(30)
	assert(not broadcast.screen.visible, "A broken mirror shows nothing")
	print("PASS: the mirror stands in reach, speaks, and three rounds silence it")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
