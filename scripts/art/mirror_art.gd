extends "res://scripts/village/house_art.gd"

func _draw() -> void:
	if building == null or house_texture == null:
		return
	if building._integrity > 0:
		super._draw()
		return
	var base := ground_y - building.position.y
	for i in range(9):
		var x := -house_width * 0.42 + i * house_width * 0.10
		draw_colored_polygon(PackedVector2Array([Vector2(x, base), Vector2(x+6, base-4-i%3*3), Vector2(x+10, base-1)]), Color("b8dce4"))
	for i in range(3):
		draw_line(Vector2(-house_width*0.35+i*house_width*0.28, base-3), Vector2(-house_width*0.14+i*house_width*0.28, base-8), Color("a67b32"), 4)
