extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920,1080)
	add_child(viewport)
	var world = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(world)
	await get_tree().process_frame
	var camera = world.get_node("KingdomCamera")
	var knight = world.get_node("Knight")
	var target := Node2D.new()
	world.add_child(target)
	target.position = Vector2(300,400)
	camera._on_projectile_fired({"projectile":target})
	target.position = Vector2(1800,-400)
	for i in 180: camera._process(1.0/60)
	assert(absf(camera.position.x-1800) < 1.0)
	assert(camera.position.y > target.position.y+200, "Vertical tracking must leave room above the projectile")
	assert(is_equal_approx(camera.zoom.x,1.0), "Short shots must not zoom out")
	target.position = Vector2(6200,-100)
	for i in 240: camera._process(1.0/60)
	assert(camera.zoom.x >= 0.88 and camera.zoom.x < 0.89)
	assert(is_equal_approx(camera.max_x,6927.0-960.0/camera.zoom.x))
	var ammo: int = knight._ammo
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	camera._input(click)
	assert(camera.blocks_aim_input())
	assert(not knight._can_start_aim(), "Return click must not aim or fire")
	assert(is_instance_valid(target), "Returning must not delete an airborne projectile")
	click.pressed = false
	camera._input(click)
	for i in 180: camera._process(1.0/60)
	assert(camera.position.distance_to(Vector2(camera.min_x,350)) < 1)
	assert(camera.zoom == Vector2.ONE)
	assert(not camera.blocks_aim_input())
	assert(knight._ammo == ammo)
	# The same return action must work after impact, with no valid projectile.
	camera._on_projectile_fired({"projectile":target})
	target.queue_free()
	await get_tree().process_frame
	click.pressed = true
	camera._input(click)
	assert(camera._returning)
	print("PASS: softer vertical follow, 12% long-shot zoom, return click in flight and after impact, no accidental aiming")
	get_tree().quit()
