extends Node2D

# Does every village house that has a painted material map actually find it?
func _ready() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	var found := 0
	var mapped := 0
	for house in get_tree().get_nodes_in_group("structures"):
		if not house.has_meta("model"):
			continue
		found += 1
		var carved = house.get_node_or_null("PhysicalHouse")
		if carved == null:
			continue
		var facade = carved.get_node_or_null("Facade")
		if facade != null and facade._has_map:
			mapped += 1
			print("MAPPED  ", house.name, "  model=", house.get_meta("model"))
	print("village houses: ", found, "   with painted map: ", mapped)
	print("OK" if mapped >= 1 else "FAIL - no house found its map")
	get_tree().quit()
