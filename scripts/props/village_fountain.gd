extends StaticBody2D

# The village fountain, and the only thing in the kingdom the Knight can take away
# rather than merely break.
#
# Water is already political here: GAME_DESIGN.md gives opening a reservoir high
# narrative value against the King, and the society code treats RESERVOIR_OPENED as
# the one event that does not frighten civilians. The fountain is the other side of
# that. Shelling it hands the Crown the best propaganda of the match, and the Crown
# will not have to invent a word of it.

const SHEET = preload("res://assets/props/fountain_flow.png")
const FRAME := Vector2i(666, 667)
const FOOT := 652            # where the stone meets the ground inside a frame
const STONE_HIGH := 643.0    # the stone's height in the art, which sets the scale
const STONE_MID := 333.0     # its middle, so the column stands over the given x

# Four states on one sheet, drawn on a single unchanging fountain with only the
# water changing: measured, the stone sits at x=79, y=9 in all four. An earlier pair
# of sheets disagreed by a seventh in width, and the fountain changed shape at the
# moment the water stopped.
enum { LOW, MIDDLING, FULL, DRY }
const SURGE := [LOW, MIDDLING, FULL, MIDDLING]   # up and back down, so the jets swell
const BEAT := 0.22

@export var max_integrity := 3

# How tall the stone stands in the street.
var stone_height := 165.0
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
	sprite.scale = Vector2.ONE * _factor()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	collision_layer = 1
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var box := RectangleShape2D.new()
	# The basin and the column, not the empty sky around the jets.
	box.size = Vector2(430, 430) * _factor()
	shape.shape = box
	shape.position = Vector2(STONE_MID, FOOT - 215) * _factor()
	add_child(shape)

func _process(delta: float) -> void:
	if dry:
		return
	_beat += delta
	sprite.texture.region = _region(SURGE[int(_beat / BEAT) % SURGE.size()])

func apply_explosion_damage(amount: int, _source_position: Vector2, _ratio := 1.0, _radius := 155.0, _heading := Vector2.ZERO, _cascade := true) -> void:
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
	sprite.texture.region = _region(DRY)
	EventBus.world_event.emit({
		"type": "FOUNTAIN_BROKEN",
		"target": name,
		"position": global_position,
		"severity": 1.0,
		"narrative_value": 1.0,
	})

# Everything in the "structures" group has to answer this: a blast asks each one how
# near it is before working out the damage. Leaving it out crashed the game on every
# explosion — joining the group means meeting the whole contract, not just the one
# method that looked relevant.
func closest_point(point: Vector2) -> Vector2:
	var shape: CollisionShape2D = get_node("CollisionShape2D")
	var box: RectangleShape2D = shape.shape
	var rect := Rect2(global_position + shape.position - box.size * 0.5, box.size)
	return Vector2(clampf(point.x, rect.position.x, rect.end.x),
		clampf(point.y, rect.position.y, rect.end.y))

# Stands the fountain on the ground at `x`, with its stone foot on the terrace.
func stand_at(x: float) -> void:
	var ground: float = preload("res://scripts/world/terraces.gd").walking_y(x)
	position = Vector2(x - STONE_MID * _factor(), ground - FOOT * _factor())

func _factor() -> float:
	return stone_height / STONE_HIGH

func _region(state: int) -> Rect2:
	return Rect2(state * FRAME.x, 0, FRAME.x, FRAME.y)
