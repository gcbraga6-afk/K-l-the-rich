extends Node2D
const Catalog = preload("res://scripts/village/business_catalog.gd")
const Structure = preload("res://scripts/world/structure.gd")
const HouseArt = preload("res://scripts/village/house_art.gd")
var buildings: Array[StaticBody2D] = []
const TITLES := ["Padaria", "Taverna", "Mercado", "Alfaiataria", "Tecelagem Real", "Fundição", "Manufatura", "Destilaria"]

func _ready() -> void:
	var xs := [1540, 2070, 2750, 3440, 4820, 5160, 5510, 5840]
	# The market and the tailor are gone. Their wide awnings sprawled across the
	# street, crowded the cottages either side and hid what a round did to them.
	var dropped := [2, 3]
	for i in range(8):
		if i in dropped:
			continue
		var b: StaticBody2D
		if i == 4:
			b = get_parent().get_node("Structures/Factory")
			var old_art := b.get_node_or_null("Artwork")
			if old_art:
				b.remove_child(old_art)
				old_art.queue_free()
		else:
			b = StaticBody2D.new()
			b.name = TITLES[i]
			b.set_script(Structure)
			b.add_to_group("structures")
			var visual := ColorRect.new()
			visual.name = "Visual"
			b.add_child(visual)
			var shape_node := CollisionShape2D.new()
			shape_node.name = "CollisionShape2D"
			b.add_child(shape_node)
			var label := Label.new()
			label.name = "NameLabel"
			b.add_child(label)
		b.position = Vector2(xs[i], 550)
		b.set_meta("business", TITLES[i])
		# Which row this belongs to, so nothing downstream has to count on an index.
		b.set_meta("industry", i >= 4)
		var texture := Catalog.building(i)
		var width := 285.0 if i < 4 else 310.0
		var height := width * texture.get_height() / texture.get_width()
		var visual: ColorRect = b.get_node("Visual")
		visual.position = Vector2(-width*0.43, 70-height*0.82)
		visual.size = Vector2(width*0.86, height*0.82)
		var shape := RectangleShape2D.new()
		shape.size = visual.size
		b.get_node("CollisionShape2D").shape = shape
		b.get_node("CollisionShape2D").position = visual.position + visual.size/2
		if i != 4:
			get_parent().get_node("Structures").add_child(b)
		else:
			b._base_position = b.position
		var art := Node2D.new()
		art.name = "Artwork"
		art.set_script(HouseArt)
		art.house_texture = texture
		art.house_width = width
		b.add_child(art)
		var label: Label = b.get_node("NameLabel")
		label.text = TITLES[i]
		label.position = Vector2(-width/2, 78)
		label.size = Vector2(width, 22)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color("e4d5af"))
		label.show()
		buildings.append(b)
	EventBus.world_event.connect(_on_event)
	_assign_routines()

func _assign_routines() -> void:
	var village := get_parent().get_node("Village")
	var people := get_parent().get_node("Characters").get_children()
	var worker_index := 0
	for person in people:
		if person.label == "Soldier" or person.label == "Child":
			continue
		var home: Node2D = village.front_houses[worker_index % village.front_houses.size()]
		var job: Node2D = buildings[worker_index % buildings.size()]
		# Picked by position in whatever is left standing, not by a fixed index: two
		# of the shops no longer exist.
		person.routine_sites = [home, job, buildings[(worker_index + 2) % buildings.size()]]
		person.routine_index = worker_index % 3
		person.speed = 45.0 + (worker_index % 4) * 7.0
		worker_index += 1

func _on_event(event: Dictionary) -> void:
	if event.type != "STRUCTURE_DESTROYED":
		return
	for b in buildings:
		if str(b.name) == str(event.target):
			b.get_node("NameLabel").text = str(b.get_meta("business")) + " · fechada"
			EventBus.world_event.emit({"type":"WORKPLACE_CLOSED", "target":str(b.get_meta("business")), "cause":"damage", "position":b.global_position})
			break
