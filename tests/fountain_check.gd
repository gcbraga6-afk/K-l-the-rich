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
	var foot: float = fountain.position.y + fountain.FOOT * fountain.art_scale
	assert(absf(foot - ground) < 2.0, "The stone must stand on the street, not float")
	# Water has to move, or it is a photograph of a fountain.
	var seen := {}
	for i in range(40):
		await steps(6)
		seen[fountain.sprite.texture.region.position] = true
	assert(seen.size() >= 2, "The jets must run")
	assert(not fountain.dry, "A fountain nobody shot must have water")
	print("FOUNTAIN running, ", seen.size(), " states of flow")
	var said := ""
	var broadcast = world.get_node("Structures/Mirror/Broadcast")
	for hit in range(3):
		fountain.apply_explosion_damage(1, fountain.global_position)
		await steps(10)
	assert(fountain.dry, "Three rounds must take the water")
	assert(fountain.sprite.texture.region.position == Vector2(0, 0), "A broken fountain shows the dry stone")
	await steps(30)
	said = broadcast.current_message
	print("FOUNTAIN dry, mirror says: ", said.replace("\n", " "))
	assert(said.contains("taken"), "The Crown must say who took the water")
	print("PASS: the fountain runs, takes three rounds, and stands there dry")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
