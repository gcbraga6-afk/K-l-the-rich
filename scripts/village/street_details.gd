extends Node2D

var house_positions: Array[float] = []
var rear_street := false

func _draw() -> void:
	if rear_street:
		# A shallow raised street visually anchors the smaller back-row homes.
		draw_colored_polygon(PackedVector2Array([Vector2(420,574),Vector2(4350,574),Vector2(4440,612),Vector2(360,612)]), Color("8d895b"))
		draw_line(Vector2(440,577),Vector2(4340,577),Color("b6a27a"),5)
	for x in house_positions:
		if rear_street:
			draw_colored_polygon(PackedVector2Array([Vector2(x-8,575),Vector2(x+9,575),Vector2(x+45,610),Vector2(x+15,610)]),Color("baaa80"))
		else:
			for i in range(5):
				draw_rect(Rect2(x-22+i*12,617+(i%2)*3,9,3),Color("cec09a"))
			# Short fencing preserves gaps for doors and sightlines.
			for i in range(4):
				draw_rect(Rect2(x+127+i*15,589,4,31),Color("716348"))
			draw_line(Vector2(x+124,598),Vector2(x+178,598),Color("9d8a60"),3)
