extends Node
func _ready() -> void:
	call_deferred("capture")
func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1800,900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(world)
	world.get_node("HUD").hide()
	var camera = world.get_node("KingdomCamera")
	camera.set_process(false)
	camera.zoom = Vector2.ONE*1.1
	await get_tree().process_frame
	# Put the cart on the village street so both the load and the carter show.
	var cart = world.get_node("SupplyCart")
	cart.rolling = true
	cart.visible = true
	cart.position.x = 1500.0
	cart._process(0.016)
	camera.position = Vector2(1520,440)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("user://cart.png")
	# And the powder store where the carts unload, short of the castle footing.
	camera.position = Vector2(5880,380)
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("user://store.png")
	get_tree().quit()
