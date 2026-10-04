extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var lab = load("res://scenes/physics_lab/house.tscn").instantiate()
	get_tree().root.add_child(lab)
	get_tree().current_scene = lab
	lab.set_fracture(false)
	await get_tree().create_timer(3.0).timeout
	var beam = lab.container.get_node("LoadBeam")
	var roof = lab.container.get_node("RoofLeft")
	assert(absf(beam.position.y-548) < 8,"House must stand under gravity before firing")
	assert(absf(beam.rotation) < 0.04,"Beam must remain level before impact")
	for part in lab.pieces:
		assert(part is RigidBody2D,"Pieces must be real bodies from the start, not a ruined sprite")
		assert(not part.released,"Every piece must be standing masonry before the shot")
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
	print("STANDING ",lab.masonry.standing(),"/",lab.pieces.size())
	assert(displacement > 50,"The blast must tear the struck course out of the wall")
	# The anti-billiards guarantee: energy stays local. Masonry the blast never
	# reached, and that kept its support, must not have budged at all.
	for side in range(5):
		var far: RigidBody2D = lab.container.get_node("RightWall%d" % side)
		assert(not far.released,"Masonry outside the blast must not come loose")
		assert(far.position.is_equal_approx(Vector2(1300,776-side*48)),"Untouched masonry must not be shoved aside")
	assert(absf(beam.rotation) > 0.12 or beam.position.y > 580,"Loss of support must tilt or drop the beam")
	assert(roof.position.y > roof_y+60,"Roof must fall through gravity after losing support")
	for part in lab.pieces:
		assert(absf(part.position.x)<5000 and part.position.y < 900,"Pieces must remain finite and collide with ground")
	assert(lab.pieces.size() == 13,"No pieces may disappear or be replaced by a ruined sprite")
	# Same house, fracture on: the struck course must break up into shards that
	# carry the facade, and raise dust, instead of leaving as one slab.
	lab.reset_house()
	await get_tree().create_timer(1.0).timeout
	lab.set_fracture(true)
	lab.fire(Vector2(1250,-280))
	await get_tree().create_timer(2.5).timeout
	var shards := get_tree().get_nodes_in_group("stone_shards")
	print("FRACTURE shards=",shards.size()," standing=",lab.masonry.standing(),"/",lab.pieces.size())
	assert(shards.size() >= 8,"Cratered stone must break into shards, not come out as a slab")
	for piece in lab.pieces:
		assert(not is_instance_valid(piece) or not piece.shattered,"A shattered piece must not linger beside its shards")
	assert(lab.masonry.standing() > 0,"Fracture must not level the whole house at once")
	print("PASS: stable house, local blast energy, cratered course ejected, gravity collapse, untouched far wall, persistent bodies, on-demand fracture")
	get_tree().quit()

func capture(id: String) -> void:
	if "--capture" not in OS.get_cmdline_user_args():
		return
	await get_tree().process_frame
	RenderingServer.force_draw()
	get_viewport().get_texture().get_image().save_png("res://assets/backgrounds/%s.png" % id)
