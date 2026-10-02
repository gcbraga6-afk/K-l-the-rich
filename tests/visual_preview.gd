extends Node

func _ready() -> void:
	call_deferred("capture")

func capture() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	var camera = world.get_node("KingdomCamera")
	for view in [[800.0, "launch"], [1500.0, "village"], [3100.0, "industry"], [4600.0, "nobles"], [6127.0, "castle"]]:
		camera.position.x = view[0]
		camera.position.y = camera.resting_y(view[0])
		await get_tree().process_frame
		await get_tree().process_frame
		RenderingServer.force_draw()
		get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/preview_%s.png" % view[1])
	get_tree().quit()
