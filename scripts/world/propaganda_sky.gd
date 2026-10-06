extends Node2D

# Sends a dragon across the kingdom now and then, carrying whatever the Crown is
# saying at the time. One at a time: the sky is scenery, not a parade.

const Dragon = preload("res://scripts/world/propaganda_dragon.gd")

# Provisional, taken from the NORMAL shelf of ESPELHO.md. The register is still
# the user's to settle, and these are meant to be replaced.
# Short, because a banner is read in the second it takes to cross the sky. The
# Mirror can afford a sentence; this cannot.
const LINES := [
	"STRONG KING. KIND HAND.",
	"LONG LIVE THE KING.",
	"ORDER IS FREEDOM.",
	"TRUST THE CROWN.",
	"ONE KINGDOM. ONE KING.",
]

const FIRST := 14.0     # seconds before the first one appears
const BETWEEN := 46.0   # seconds of empty sky between passes

var _next := FIRST
var _said := 0

# One at a time, wherever it ended up parented.
func _aloft() -> bool:
	for node in get_tree().get_nodes_in_group("propaganda_dragons"):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			return true
	return false


func _process(delta: float) -> void:
	_next -= delta
	if _next > 0.0 or _aloft():
		return
	_next = BETWEEN
	var dragon := Node2D.new()
	dragon.name = "PropagandaDragon"
	dragon.set_script(Dragon)
	# Slipped in between the valley and the woodland, so the near trees pass in
	# front of it and the far mountains stay behind. Draw order inside one depth is
	# tree order, which is why it is parented here rather than kept under the sky.
	var landscape := get_parent().get_node("Landscape") if get_parent().has_node("Landscape") else null
	if landscape != null and landscape.has_node("WoodlandDepth"):
		landscape.add_child(dragon)
		landscape.move_child(dragon, landscape.get_node("WoodlandDepth").get_index())
	else:
		add_child(dragon)
	dragon.say(LINES[_said % LINES.size()])
	_said += 1
	# Enters over the castle and flies down the kingdom towards the knight, which is
	# the way the art faces.
	dragon.position = Vector2(preload("res://scripts/world/terraces.gd").WORLD_WIDTH + 200.0,
		92.0 + randf_range(-26.0, 26.0))
