extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var lab = load("res://scenes/physics_lab/carve.tscn").instantiate()
	get_tree().root.add_child(lab)
	get_tree().current_scene = lab
	await steps(60)
	var whole: float = lab.facade.standing_ratio()
	assert(whole > 0.2,"The facade must start standing")
	var aim: Vector2 = lab.facade.to_global(lab.facade.base_offset \
		+ Vector2(lab.facade.art.get_width()*0.42, lab.facade.art.get_height()*0.60) * lab.facade.pixel)
	lab.facade.carve(aim, 62.0)
	await steps(90)
	var holed: float = lab.facade.standing_ratio()
	print("CARVE whole=",whole," after_hole=",holed," rubble=",get_tree().get_nodes_in_group("stone_shards").size())
	assert(holed < whole,"The round must take material out of the wall")
	assert(holed > whole*0.55,"One round must open a hole, not level the building")
	assert(get_tree().get_nodes_in_group("stone_shards").size() > 0,"The wall must shed rubble where it was hit")
	print("PASS: facade stands, round opens a hole, rubble sheds, building survives")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
