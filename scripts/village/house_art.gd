extends Node2D

var house_texture: Texture2D
var house_width := 240.0
var building: Node2D
var ground_y := 620.0
var _last_integrity := -1

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	building = get_parent()
	for child in building.get_children():
		if child is CanvasItem and child != self:
			child.hide()

func _process(_delta: float) -> void:
	if _last_integrity != building._integrity:
		_last_integrity = building._integrity
		queue_redraw()

func _draw() -> void:
	if building == null or house_texture == null:
		return
	var base := ground_y - building.position.y
	var height := house_width * house_texture.get_height() / house_texture.get_width()
	if building._integrity <= 0:
		# Debris stays at street level, leaving a genuine opening for later shots.
		for i in range(15):
			var x := -house_width * 0.43 + i * house_width * 0.058
			draw_rect(Rect2(x, base - 9 - (i % 4) * 6, 16 + i % 3 * 4, 13), Color("716c5b"))
		for i in range(4):
			draw_line(Vector2(-house_width*0.35+i*28,base-4), Vector2(-house_width*0.10+i*27,base-22-i%2*18), Color("594431"), 8)
		return
	var damage: float = 1.0 - float(building._integrity) / float(building.max_integrity)
	draw_texture_rect(house_texture, Rect2(-house_width/2, base-height, house_width, height), false, Color.WHITE.lerp(Color("9e927f"), damage * 0.7))
	if damage > 0:
		draw_polyline(PackedVector2Array([Vector2(-13,base-height*0.47),Vector2(2,base-height*0.34),Vector2(-6,base-height*0.26),Vector2(11,base-height*0.12)]), Color("4b3b30"), 3)
