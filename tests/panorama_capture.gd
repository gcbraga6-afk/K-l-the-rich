extends Node
func _ready() -> void:
	call_deferred("capture")
func capture() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(3200,1000)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var world = load("res://scenes/main.tscn").instantiate()
	viewport.add_child(world)
	world.get_node("HUD").hide()
	var camera = world.get_node("KingdomCamera")
	camera.set_process(false)
	camera.zoom = Vector2.ONE*0.5
	camera.position = Vector2(3130,-150)
	await get_tree().process_frame
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://assets/backgrounds/playable_panorama.png")
	get_tree().quit()
