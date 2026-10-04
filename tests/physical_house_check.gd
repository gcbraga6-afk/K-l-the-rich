extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var lab = load("res://scenes/physics_lab/house.tscn").instantiate()
	get_tree().root.add_child(lab)
	get_tree().current_scene = lab
	await get_tree().create_timer(3.0).timeout
	var beam = lab.container.get_node("LoadBeam")
	var roof = lab.container.get_node("RoofLeft")
	assert(absf(beam.position.y-548) < 8,"House must stand under gravity before firing")
	assert(absf(beam.rotation) < 0.04,"Beam must remain level before impact")
	for part in lab.pieces:
		assert(not part.freeze,"Pieces must be real active physics bodies from the start")
	await capture("physical_house_before")
	var roof_y: float = roof.position.y
	var baseline: Vector2 = lab.container.get_node("LeftWall1").position
	lab.fire(Vector2(1250,-280))
	await get_tree().create_timer(1.2).timeout
	await capture("physical_house_impact")
	await get_tree().create_timer(3.8).timeout
	await capture("physical_house_after")
	var displacement: float = lab.container.get_node("LeftWall1").position.distance_to(baseline)
	print("PHYSICS_RESULT support displacement=",displacement," beam rotation=",beam.rotation," roof drop=",roof.position.y-roof_y)
	assert(displacement > 50,"Cannonball must physically push the wall out of place")
	assert(absf(beam.rotation) > 0.12 or beam.position.y > 580,"Loss of support must tilt or drop the beam")
	assert(roof.position.y > roof_y+60,"Roof must fall through gravity after losing support")
	for part in lab.pieces:
		assert(absf(part.position.x)<5000 and part.position.y < 900,"Pieces must remain finite and collide with ground")
	assert(lab.pieces.size() == 13,"No pieces may disappear or be replaced by a ruined sprite")
	print("PASS: stable physical house, direct momentum transfer, support loss, gravity collapse, persistent bodies")
	get_tree().quit()

func capture(id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/%s.png" % id)
