extends Node2D

var person: CharacterBody2D
var time := 0.0

func _ready() -> void:
	person = get_parent()
	person.get_node("Body").hide()
	person.get_node("Head").hide()

func _process(delta: float) -> void:
	time += delta
	queue_redraw()

func _draw() -> void:
	if person == null:
		return
	var stride := sin(time*10) * 4.0 if absf(person.velocity.x) > 1.0 else 0.0
	var cloth: Color = person.body_color
	var skin: Color = person.head_color
	var soldier: bool = person.label == "Soldier"
	draw_rect(Rect2(-10,-3,21,4),Color(0.12,0.14,0.12,0.35))
	draw_rect(Rect2(-7+stride,-19,6,18),Color("3d3935"))
	draw_rect(Rect2(2-stride,-19,6,18),Color("484237"))
	draw_rect(Rect2(-9+stride,-4,9,4),Color("292c2b"))
	draw_rect(Rect2(1-stride,-4,10,4),Color("292c2b"))
	draw_rect(Rect2(-9,-42,19,25),cloth)
	draw_rect(Rect2(-9,-23,19,4),Color("655038"))
	draw_rect(Rect2(-13,-38,5,21),cloth.darkened(0.15))
	draw_rect(Rect2(10,-38,5,21),cloth.darkened(0.15))
	draw_rect(Rect2(-13,-20,5,6),skin)
	draw_rect(Rect2(10,-20,5,6),skin)
	draw_rect(Rect2(-6,-57,14,15),skin)
	draw_rect(Rect2(-7,-60,16,7),Color("68543b"))
	draw_rect(Rect2(3 if person.velocity.x >= 0 else -5,-51,2,2),Color("292d2e"))
	if soldier:
		draw_rect(Rect2(-9,-61,20,8),Color("849295"))
		if person.disorganized_seconds <= 0:
			draw_line(Vector2(19,-3),Vector2(19,-65),Color("816345"),3)
			draw_colored_polygon(PackedVector2Array([Vector2(14,-64),Vector2(19,-76),Vector2(24,-64)]),Color("aab4af"))
	else:
		draw_rect(Rect2(-10,-59,23,4),Color("a18a58"))
		draw_rect(Rect2(-5,-65,14,7),Color("b29a63"))
