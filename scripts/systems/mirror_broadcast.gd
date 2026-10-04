extends Node2D

var mirror: StaticBody2D
var society: Node
var viewport: SubViewport
var screen: Polygon2D
var message: Label
var headline: Label
var current_message := "O Reino vela\npor seus súditos."
var pending: Array[Dictionary] = []
var remaining := 0.0
var active_event: Dictionary = {}
var delivered := false

func _ready() -> void:
	mirror = get_parent()
	society = mirror.get_parent().get_parent().get_node("Society")
	viewport = SubViewport.new()
	viewport.size = Vector2i(640, 360)
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	headline = Label.new()
	headline.position = Vector2(24, 22)
	headline.size = Vector2(592, 48)
	headline.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	headline.text = "VOZ DO REINO"
	headline.add_theme_font_size_override("font_size", 28)
	headline.add_theme_color_override("font_color", Color("e9c77b"))
	viewport.add_child(headline)
	message = Label.new()
	message.position = Vector2(35, 87)
	message.size = Vector2(570, 235)
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message.add_theme_font_size_override("font_size", 43)
	message.add_theme_color_override("font_color", Color("fff5d5"))
	message.text = current_message
	viewport.add_child(message)
	screen = Polygon2D.new()
	var art = mirror.get_node("Artwork")
	var factor: float = art.house_width / art.house_texture.get_width()
	var base: float = art.ground_y - mirror.position.y
	var origin := Vector2(-art.house_width / 2, base - art.house_texture.get_height() * factor)
	# Inner glass corners of the approved asset, minus the atlas crop origin.
	var corners := PackedVector2Array([Vector2(130,470), Vector2(987,360), Vector2(987,961), Vector2(130,925)])
	# Packed arrays are copy-on-write: assign the completed polygon explicitly.
	var polygon := PackedVector2Array()
	for corner in corners:
		polygon.append(origin + (corner - Vector2(5,83)) * factor)
	screen.polygon = polygon
	screen.uv = PackedVector2Array([Vector2(0,0), Vector2(640,0), Vector2(640,360), Vector2(0,360)])
	screen.texture = viewport.get_texture()
	screen.z_index = 2
	add_child(screen)
	EventBus.world_event.connect(_on_event)

func _process(delta: float) -> void:
	if mirror._integrity <= 0:
		screen.hide()
		pending.clear()
		active_event = {}
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		return
	remaining = maxf(0, remaining - delta)
	if remaining <= 0:
		if not pending.is_empty():
			active_event = pending.pop_front()
			current_message = active_event.message
			remaining = 12.0
			delivered = false
		else:
			active_event = {}
			current_message = "O Reino vela\npor seus súditos."
		message.text = current_message
	if not active_event.is_empty() and not delivered:
		delivered = true
		var audience: Array = society.witnesses(mirror.global_position, 800)
		society.receive_propaganda(active_event, audience)
		EventBus.world_event.emit({"type": "PROPAGANDA_BROADCAST", "target": "Mirror", "message": current_message.replace("\n", " "), "cause": active_event.get("type", ""), "position": mirror.global_position, "witnesses": audience.size(), "narrative_value": active_event.get("narrative_value", 0.0)})

func _on_event(event: Dictionary) -> void:
	if mirror._integrity <= 0:
		return
	var kind: String = event.get("type", "")
	var target: String = event.get("target", "")
	var text := ""
	if kind in ["STRUCTURE_HIT", "STRUCTURE_DESTROYED"]:
		if target == "Mirror":
			text = "Atacaram a voz\ndo Reino."
		elif target.begins_with("VillageHouse"):
			text = "Casas atingidas.\nO Cavaleiro ameaça\nnossas famílias."
		elif target == "Castle" or target.begins_with("NobleHouse"):
			text = "A Coroa está\nsob ataque."
		else:
			text = "O ataque ameaça\no trabalho\ndo Reino."
	elif kind == "SOLDIER_DISORGANIZED":
		text = "Guardas atingidos.\nA Coroa pede\ncalma."
	elif kind == "RESERVOIR_OPENED":
		text = "Água liberada.\nA Coroa pede\nordem nas filas."
	if text.is_empty():
		return
	if current_message == text:
		return
	for queued in pending:
		if queued.message == text:
			return
	var entry := event.duplicate()
	entry.message = text
	pending.append(entry)
	if pending.size() > 4:
		pending.pop_front()
