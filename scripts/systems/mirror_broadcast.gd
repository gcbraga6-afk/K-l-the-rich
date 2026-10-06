extends Node2D

# The Kingdom speaks through the mirror, and the mirror never reports damage. Every
# round the Knight fires comes back as a threat to the people and as proof that the
# Crown holds. It is written in the Kingdom's own voice, addressed to its subjects.
const IDLE := "The Kingdom watches\nover its subjects."

var mirror: StaticBody2D
var society: Node
var viewport: SubViewport
var screen: Polygon2D
var message: Label
var headline: Label
var current_message := IDLE
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
	headline.text = "VOICE OF THE KINGDOM"
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
	var glass := PackedVector2Array()
	for corner in corners:
		glass.append(origin + (corner - Vector2(5,83)) * factor)
	# The board is painted in perspective: its right edge stands 601 pixels tall against
	# 455 on the left. Stretched across that shape as a single quad, the text bends --
	# Godot cuts a quad into two triangles and maps the texture across each on its own,
	# so the writing kinks along the diagonal seam. Cut into narrow vertical strips
	# instead, every strip is near enough a rectangle for that seam to vanish, and the
	# line of text runs straight into the distance the way the frame around it does.
	const STRIPS := 56
	var polygon := PackedVector2Array()
	var mapping := PackedVector2Array()
	var faces := []
	for i in range(STRIPS + 1):
		var along := float(i) / float(STRIPS)
		polygon.append(glass[0].lerp(glass[1], along))
		mapping.append(Vector2(640.0 * along, 0.0))
		polygon.append(glass[3].lerp(glass[2], along))
		mapping.append(Vector2(640.0 * along, 360.0))
	for i in range(STRIPS):
		faces.append(PackedInt32Array([i * 2, i * 2 + 2, i * 2 + 3, i * 2 + 1]))
	screen.polygon = polygon
	screen.uv = mapping
	screen.polygons = faces
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
			current_message = IDLE
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
	# The water is checked before anything else a round can hit. The fountain also
	# reports itself as a structure, so without this it fell through to the line
	# about the Kingdom's trade and the Crown missed its best moment of the match.
	# A round that chips the fountain is not news; the Crown has nothing to say about
	# it yet. Saying the usual line about trade here would occupy the screen for
	# twelve seconds and bury the moment the water actually stops.
	if target == "VillageFountain" and kind == "STRUCTURE_HIT":
		return
	var urgent := false
	if kind == "FOUNTAIN_BROKEN" or (kind == "STRUCTURE_DESTROYED" and target == "VillageFountain"):
		urgent = true
		# It invents nothing. The fountain is dry and the whole village can see it.
		text = "The Knight has taken\nthe water from your\nchildren's mouths."
	elif kind in ["STRUCTURE_HIT", "STRUCTURE_DESTROYED"]:
		if target == "Mirror":
			text = "They strike at the\nvoice of the Kingdom.\nIt is not silenced."
		elif target.begins_with("VillageHouse"):
			text = "Your homes are struck.\nThe Knight makes war\non your families."
		elif target == "Castle" or target.begins_with("NobleHouse"):
			text = "The Crown is attacked\nand the Crown stands."
		else:
			text = "He strikes at your\nlabour, and calls it\nstriking at us."
	elif kind == "SOLDIER_DISORGANIZED":
		text = "Your guards are hurt\nshielding you.\nRemain calm."
	elif kind == "RESERVOIR_OPENED":
		text = "The Crown grants water.\nForm your lines\nin good order."
	if text.is_empty():
		return
	if current_message == text:
		return
	for queued in pending:
		if queued.message == text:
			return
	var entry := event.duplicate()
	entry.message = text
	if urgent:
		# The water stopping cuts whatever is on the screen. Everything else waits
		# its turn; this is the thing the whole village is looking at.
		pending.push_front(entry)
		remaining = 0.0
	else:
		pending.append(entry)
	if pending.size() > 4:
		pending.pop_back() if urgent else pending.pop_front()
