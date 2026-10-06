extends StaticBody2D

# The village fountain, and the only thing in the kingdom the Knight can take
# away rather than merely break.
#
# Water is already political here: GAME_DESIGN.md gives opening a reservoir high
# narrative value against the King, and the society code treats RESERVOIR_OPENED
# as the one event that does not frighten civilians. The fountain is the other
# side of that. Shelling it hands the Crown the best propaganda of the match,
# and the Crown will not have to invent a word of it.

const FLOW_SHEET = preload("res://assets/props/fountain_flow.png")
const DRY_SHEET = preload("res://assets/props/fountain_states.png")

# The flowing frames were redrawn on one unchanging fountain, so the stone holds
# still on its own: measured, its left edge sits at x=78, 79, 78 across the three
# and its top at y=9 in all of them. No per-frame shift is needed any more.
const FLOW_FRAME := Vector2i(666, 667)
const FLOW_FOOT := 652          # where the stone meets the ground inside a flowing frame
const FLOW_HEIGHT := 643.0      # the stone's height there, used to match the dry frame

# The dry fountain still comes from the first sheet, which was drawn to different
# proportions — its stone is 477 by 699 against 511 by 643 here. Scaled to the same
# height it stands about a seventh narrower, which shows at the moment the water
# stops. A dry frame drawn on the new fountain would remove that.
const DRY_FRAME := Vector2i(512, 768)
const DRY_FOOT := 718
const DRY_HEIGHT := 699.0

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
	atlas.atlas = FLOW_SHEET
	atlas.filter_clip = true
	sprite = Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_show(0)
	collision_layer = 1
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	# The basin and the column, not the empty sky around the jets.
	var factor: float = stone_height / FLOW_HEIGHT
	box.size = Vector2(430, 430) * factor
	shape.shape = box
	shape.position = Vector2(333, FLOW_FOOT - 215) * factor
	add_child(shape)

func _process(delta: float) -> void:
	if dry:
		return
	_beat += delta
	# Up and back down, so the jets surge rather than snapping from weak to strong.
	const SURGE := [0, 1, 2, 1]
	_show(SURGE[int(_beat / BEAT) % SURGE.size()])


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
	_show_dry()
	EventBus.world_event.emit({
		"type": "FOUNTAIN_BROKEN",
		"target": name,
		"position": global_position,
		"severity": 1.0,
		"narrative_value": 1.0,
	})

# One of the three flowing frames.
func _show(frame: int) -> void:
	var factor: float = stone_height / FLOW_HEIGHT
	sprite.texture.atlas = FLOW_SHEET
	sprite.texture.region = Rect2(frame * FLOW_FRAME.x, 0, FLOW_FRAME.x, FLOW_FRAME.y)
	sprite.scale = Vector2.ONE * factor
	sprite.position = Vector2.ZERO


# The jets stop and the basin empties, from the older sheet. Matched on the height
# of the stone and on the ground its foot stands on, so it does not jump; it is
# still a touch narrower, which only a dry frame on the new fountain can fix.
func _show_dry() -> void:
	var factor: float = stone_height / DRY_HEIGHT
	sprite.texture.atlas = DRY_SHEET
	sprite.texture.region = Rect2(0, 0, DRY_FRAME.x, DRY_FRAME.y)
	sprite.scale = Vector2.ONE * factor
	# Hold the column where it was, and the foot on the same stone.
	sprite.position = Vector2(
		(333.0 * stone_height / FLOW_HEIGHT) - (266.0 * factor),
		(FLOW_FOOT * stone_height / FLOW_HEIGHT) - (DRY_FOOT * factor))


# Stands the fountain on the ground at `x`, with its stone foot on the terrace.
func stand_at(x: float) -> void:
	var ground: float = preload("res://scripts/world/terraces.gd").walking_y(x)
	var factor: float = stone_height / FLOW_HEIGHT
	position = Vector2(x - 333.0 * factor, ground - FLOW_FOOT * factor)
