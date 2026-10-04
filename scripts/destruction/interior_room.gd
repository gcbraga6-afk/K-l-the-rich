extends Node2D

# The room behind the facade. It is always there and always hidden; a hole in the
# wall is what reveals it. Without this a breach shows the valley through the
# house, and the building reads as a painted sheet rather than a volume.
#
# Drawn rather than painted as art, so every cottage has an interior from the
# start. Replacing this with real artwork later changes nothing else.

var extent := Vector2(200, 200)
var shade := Color("2a2119")

func _draw() -> void:
	# The dark of a room seen from outside on a bright day.
	draw_rect(Rect2(Vector2.ZERO, extent), shade)
	var floor_y := extent.y * 0.62
	# A floor plane, which is what sells depth: it reads as a surface going back.
	draw_rect(Rect2(Vector2(0, floor_y), Vector2(extent.x, extent.y - floor_y)), shade.lightened(0.10))
	draw_line(Vector2(0, floor_y), Vector2(extent.x, floor_y), shade.lightened(0.22), 2.0)
	# A back wall, lit a little where it meets the floor.
	draw_rect(Rect2(Vector2(extent.x * 0.08, extent.y * 0.30), Vector2(extent.x * 0.84, floor_y - extent.y * 0.30)), shade.lightened(0.05))
	# Ceiling joists, so a breached roof shows timber rather than a flat colour.
	for i in range(5):
		var x := extent.x * (0.12 + 0.19 * i)
		draw_line(Vector2(x, extent.y * 0.12), Vector2(x, extent.y * 0.30), shade.lightened(0.18), 3.0)
	draw_line(Vector2(0, extent.y * 0.30), Vector2(extent.x, extent.y * 0.30), shade.lightened(0.14), 3.0)
