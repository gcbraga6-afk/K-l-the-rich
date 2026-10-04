extends Node2D

const SHEET = preload("res://assets/characters/people_walk.png")
var person: CharacterBody2D
var sprite: Sprite2D
var frames: Array = []
var elapsed := 0.0
var facing := 1.0

func _ready() -> void:
	person = get_parent()
	person.get_node("Body").hide()
	person.get_node("Head").hide()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/people_walk.json"))
	var row := 2 if person.label == "Soldier" else (3 if person.label == "King" else person.get_index() % 2)
	# Keep one guard identity and equipment throughout the walk.
	var boxes: Array = [rows[row][1], rows[row][3], rows[row][1], rows[row][3]] if row == 2 else rows[row]
	for box in boxes:
		var texture := AtlasTexture.new()
		texture.atlas = SHEET
		texture.region = Rect2(box[0], box[1], box[2], box[3])
		texture.filter_clip = true
		frames.append(texture)
	sprite = Sprite2D.new()
	sprite.centered = false
	add_child(sprite)
	_update_frame(0)

func _process(delta: float) -> void:
	if sprite == null:
		return
	var walking: bool = absf(person.velocity.x) > 1.0
	if walking:
		facing = signf(person.velocity.x)
		elapsed += delta * (1.7 if person.fear_seconds > 0 else 1.0)
	else:
		elapsed = 0.0
	_update_frame(int(elapsed * 7.0) % 4 if walking else 1)
	# A clear visual cue for flash stun, without moving the whole person off the ground.
	sprite.modulate = Color("fff1ae") if person.disorganized_seconds > 0 else Color.WHITE
	queue_redraw()

func _update_frame(index: int) -> void:
	sprite.texture = frames[index]
	var height := 92.0 if person.label == "Soldier" else 80.0
	if person.label == "King":
		height = 88.0
	var factor: float = height / sprite.texture.get_height()
	sprite.scale = Vector2(factor * facing, factor)
	sprite.position = Vector2(-sprite.texture.get_width() * factor * facing / 2, -height)

func _draw() -> void:
	if person != null and person.disorganized_seconds > 0:
		for i in range(3):
			var angle := Time.get_ticks_msec() * 0.004 + i * TAU / 3
			draw_circle(Vector2(cos(angle) * 15, -100 + sin(angle) * 4), 2.5, Color("ffe488"))
