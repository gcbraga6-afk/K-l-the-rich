extends RigidBody2D

var outline := PackedVector2Array()
var tint := Color("9aafbf")
var material_kind := "stone"
var start_position := Vector2.ZERO
var show_debug_art := true

func _ready() -> void:
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp = 0.08
	angular_damp = 0.15
	can_sleep = true
	start_position = position
	queue_redraw()

func _draw() -> void:
	if not show_debug_art:
		return
	draw_colored_polygon(outline,tint)
	var border := outline.duplicate()
	border.append(outline[0])
	draw_polyline(border,tint.darkened(0.45),2,true)
	if material_kind == "wood":
		var bounds := Rect2(outline[0],Vector2.ZERO)
		for p in outline:
			bounds = bounds.expand(p)
		for i in range(2):
			var y := bounds.position.y+7+i*8
			draw_line(Vector2(bounds.position.x+8,y),Vector2(bounds.end.x-8,y),tint.darkened(0.25),1,true)
	elif material_kind == "stone":
		draw_line(outline[0]+Vector2(5,5),outline[1]+Vector2(-5,5),tint.lightened(0.25),2,true)
