extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().process_frame
	var impacts: Array = []
	EventBus.projectile_impacted.connect(func(event: Dictionary): impacts.append(event))
	var knight = world.get_node("Knight")
	# A full-strength drag achievable inside the launch viewport.
	var velocity := Vector2(1900,-2200)
	assert(velocity.length() <= knight.max_muzzle_speed)
	knight._fire(velocity)
	for frame in 900:
		await get_tree().physics_frame
		assert(world.get_node("KingdomCamera").zoom.x >= 0.88 and world.get_node("KingdomCamera").zoom.x <= 1.0)
		if not impacts.is_empty(): break
	assert(not impacts.is_empty(), "The long shot must produce an impact")
	print("LONG_SHOT_RESULT ", impacts[0])
	assert(impacts[0].target == &"Castle", "The castle must be reachable with the cannon")
	if "--capture-flight" in OS.get_cmdline_user_args():
		await get_tree().create_timer(0.2).timeout
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/preview_castle_impact.png")
	print("PASS: castle reachable from launch plateau at legal shot strength and bounded long-shot zoom")
	get_tree().quit()
