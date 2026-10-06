extends StaticBody2D

# The village fountain, and the only thing in the kingdom the Knight can take
# away rather than merely break.
#
# Water is already political here: GAME_DESIGN.md gives opening a reservoir high
# narrative value against the King, and the society code treats RESERVOIR_OPENED
# as the one event that does not frighten civilians. The fountain is the other
# side of that. Shelling it hands the Crown the best propaganda of the match,
# and the Crown will not have to invent a word of it.

const SHEET = preload("res://assets/props/fountain_states.png")
const FRAME := Vector2i(512, 768)
const FOOT := 718          # where the stone meets the ground inside a frame

# Read straight off the sheet, in the order it is drawn.
enum { DRY, TRICKLE, MIDDLING, FULL }
const FLOW := [MIDDLING, FULL, MIDDLING, TRICKLE]   # the loop that reads as running water

# Where the stone's left edge actually sits inside each frame, measured off the
# sheet. The four states are not drawn on the same spot, so left alone the
# fountain jumped twenty-two pixels sideways on every change of frame — a
# fountain shivering in the street. Holding `STONE_X + shift` constant puts the
# stone in one place and leaves only the water moving.
const STONE_X := [28.0, 8.0, 28.0, 6.0]
const BEAT := 0.22

@export var max_integrity := 3

var art_scale := 0.24
var dry := false
var _integrity := 0
var _beat := 0.0
var sprite: Sprite2D

func _ready() -> void:
	add_to_group("structures")
	_integrity = max_integrity
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.filter_clip = true
	atlas.region = _region(FULL)
	sprite = Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.scale = Vector2.ONE * art_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_show(FULL)
	collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	# The basin and the column, not the empty sky around the jets.
	box.size = Vector2(330, 420) * art_scale
	shape.shape = box
	shape.position = Vector2(256, FOOT - 210) * art_scale
	add_child(shape)

func _process(delta: float) -> void:
	if dry:
		return
	_beat += delta
	_show(FLOW[int(_beat / BEAT) % FLOW.size()])

func apply_explosion_damage(amount: int, source_position: Vector2, _ratio := 1.0, _radius := 155.0, _heading := Vector2.ZERO, _cascade := true) -> void:
	if dry:
		return
	_integrity = maxi(0, _integrity - amount)
	EventBus.world_event.emit({
		"type": "STRUCTURE_DESTROYED" if _integrity == 0 else "STRUCTURE_HIT",
		"target": name,
		"position": global_position,
		"severity": float(amount) / float(max_integrity),
		"narrative_value": 0.8,
	})
	if _integrity > 0:
		return
	# The jets stop and the basin empties. The fountain is still standing, which is
	# the point: the village can see exactly what was taken and what is left.
	dry = true
	_show(DRY)
	EventBus.world_event.emit({
		"type": "FOUNTAIN_BROKEN",
		"target": name,
		"position": global_position,
		"severity": 1.0,
		"narrative_value": 1.0,
	})

# Puts one state on screen with the stone held still.
func _show(state: int) -> void:
	sprite.texture.region = _region(state)
	sprite.position.x = (STONE_X[DRY] - STONE_X[state]) * art_scale


func _region(state: int) -> Rect2:
	# The sheet is two by two, read left to right and top to bottom.
	return Rect2((state % 2) * FRAME.x, (state / 2) * FRAME.y, FRAME.x, FRAME.y)

# Stands the fountain on the ground at `x`, with its stone foot on the terrace.
func stand_at(x: float) -> void:
	var ground: float = preload("res://scripts/world/terraces.gd").walking_y(x)
	position = Vector2(x - FRAME.x * art_scale * 0.5, ground - FOOT * art_scale)
