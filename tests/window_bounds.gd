extends Node
func _ready() -> void:
	call_deferred("run")
func run() -> void:
	assert(ProjectSettings.get_setting("display/window/stretch/mode") == "disabled")
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600,900)
	add_child(viewport)
	var camera := Camera2D.new()
	camera.set_script(preload("res://scripts/camera/kingdom_camera.gd"))
	viewport.add_child(camera)
	camera.configure_world(6927.0)
	for width in [1280,1920,1600]:
		camera.position.x = camera.max_x
		viewport.size = Vector2i(width,900)
		await get_tree().process_frame
		assert(is_equal_approx(camera.min_x, width/2.0))
		assert(is_equal_approx(camera.max_x, 6927.0-width/2.0))
		assert(camera.position.x <= camera.max_x)
		assert(camera.zoom == Vector2.ONE, "Window size must not alter zoom")
	for speed in [0.20,0.24]:
		var band := Node2D.new()
		band.set_script(preload("res://scripts/art/landscape_band.gd"))
		band.texture = preload("res://assets/backgrounds/valley_midground.png")
		band.camera = camera
		band.scroll_speed = speed
		viewport.add_child(band)
		camera.position.x = 1000
		band._process(0.0)
		var initial_screen_x: float = band.position.x-camera.position.x
		camera.position.x = 2000
		band._process(0.0)
		var moved_screen_x: float = band.position.x-camera.position.x
		assert(is_equal_approx(moved_screen_x-initial_screen_x, -1000*speed))
		assert(band.position.y == 0.0)
	print("PASS: 1280/1600/1920 window bounds preserve zoom; background layers have stable horizontal parallax")
	get_tree().quit()
