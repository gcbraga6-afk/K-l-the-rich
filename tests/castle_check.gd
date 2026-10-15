extends Node

# The castle breaks like the rest of the kingdom, and what a round opens in it is
# the keep's own drawn interior: the throne room, the vault, the cells.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(240)
	var castle = world.get_node("Structures/Castle")
	var keep = castle.get_node_or_null("PhysicalHouse")
	assert(keep != null, "The castle must be carved like everything else")
	assert(castle.get_node_or_null("ModularStructure") == null,
		"The old stacked-block tower must be gone, not running beside the carve")
	var facade = keep.facade
	var whole: float = facade.standing_ratio()
	assert(whole > 0.2, "The castle must start standing")
	# Its interior is drawn, not assembled from cottage modules.
	assert(facade._room_texture != null, "The keep must have something behind its wall")
	assert(Vector2i(facade._room_texture.get_size()) == facade.art.get_size(),
		"The drawn interior must line up with the facade pixel for pixel")
	print("CASTLE standing ", whole, " interior ", facade._room_texture.get_size())
	# A round into the gatehouse opens it without levelling the keep.
	var at: Vector2 = facade.to_global(facade.base_offset
		+ Vector2(facade.art.get_width() * 0.5, facade.art.get_height() * 0.62) * facade.pixel)
	keep.damage_near(2, at, 1.0)
	await steps(60)
	var holed: float = facade.standing_ratio()
	assert(holed < whole, "A round must open the castle")
	assert(holed > whole * 0.5, "One round must not level the keep")
	# A keep is not a cottage. One round may open it; it must not take a sixth of it.
	assert(whole - holed < 0.06, "The castle must take a cottage's hole, not a cottage's share")
	print("CASTLE holed ", holed, " — one round took ", snappedf(whole - holed, 0.001))
	print("PASS: the castle carves, shows its own rooms, and survives one round")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
