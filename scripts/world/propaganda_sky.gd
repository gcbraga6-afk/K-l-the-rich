extends Node2D

# Sends a dragon across the kingdom now and then, carrying whatever the Crown is
# saying at the time. One at a time: the sky is scenery, not a parade.

const Dragon = preload("res://scripts/world/propaganda_dragon.gd")

# Provisional, taken from the NORMAL shelf of ESPELHO.md. The register is still
# the user's to settle, and these are meant to be replaced.
const LINES := [
	"STRONG KING. KIND HAND.",
	"ONE KINGDOM. ONE PEOPLE. ONE KING.",
	"ORDER BRINGS PROSPERITY.",
	"A SAFE KINGDOM IS A HAPPY KINGDOM.",
	"TOGETHER UNDER THE CROWN.",
]

const FIRST := 14.0     # seconds before the first one appears
const BETWEEN := 46.0   # seconds of empty sky between passes

var _next := FIRST
var _said := 0

func _process(delta: float) -> void:
	_next -= delta
	if _next > 0.0 or get_child_count() > 0:
		return
	_next = BETWEEN
	var dragon := Node2D.new()
	dragon.name = "PropagandaDragon"
	dragon.set_script(Dragon)
	add_child(dragon)
	dragon.say(LINES[_said % LINES.size()])
	_said += 1
	# Enters from behind the knight's shoulder and crosses the whole kingdom.
	dragon.position = Vector2(-620.0, 92.0 + randf_range(-26.0, 26.0))
