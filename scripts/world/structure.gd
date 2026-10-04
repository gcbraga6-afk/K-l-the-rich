extends StaticBody2D

@export var max_integrity := 3
@export var damaged_color := Color(0.28, 0.25, 0.22, 1.0)
@export var ruined_color := Color(0.08, 0.07, 0.06, 1.0)
@export var collapse_threshold := 0

@onready var visual: ColorRect = $Visual

var _integrity := 0
var _original_color := Color.WHITE
var _original_scale := Vector2.ONE
var _shake_seconds := 0.0
var _base_position := Vector2.ZERO

func _ready() -> void:
	_integrity = max_integrity
	_original_color = visual.color
	_original_scale = visual.scale
	_base_position = position
	EventBus.structure_hit.connect(_on_structure_hit)


func _process(delta: float) -> void:
	if _shake_seconds <= 0.0:
		position = _base_position
		return

	_shake_seconds = maxf(0.0, _shake_seconds - delta)
	position = _base_position + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))


func _on_structure_hit(event: Dictionary) -> void:
	if event.get("target", "") != name:
		return

	_apply_damage(1, event.get("position", global_position))


func apply_explosion_damage(amount: int, source_position: Vector2, force_ratio := 1.0, radius := 155.0, heading := Vector2.ZERO, cascade := true) -> void:
	_apply_damage(amount, source_position, force_ratio, radius, heading, cascade)


func _apply_damage(amount: int, source_position: Vector2, force_ratio := 1.0, radius := 155.0, heading := Vector2.ZERO, cascade := true) -> void:
	var modular = get_node_or_null("PhysicalHouse")
	if modular == null:
		modular = get_node_or_null("ModularStructure")
	if modular != null:
		modular.damage_near(amount, source_position, force_ratio, radius, heading, cascade)
		return
	if _integrity <= 0:
		return

	_integrity = maxi(0, _integrity - amount)
	_shake_seconds = 0.16 + force_ratio * 0.18
	_update_damage_state()
	EventBus.world_event.emit({
		"type": "STRUCTURE_DESTROYED" if _integrity == 0 else "STRUCTURE_HIT",
		"target": str(name), "cause": "knight", "position": source_position,
		"severity": float(amount) / max_integrity, "narrative_value": 0.7,
	})


func _update_damage_state() -> void:
	var damage_ratio := 1.0 - float(_integrity) / float(max_integrity)

	if _integrity == 0:
		visual.color = ruined_color
		visual.scale = Vector2(0.65, 0.18)
		visual.position.y = 620.0 - global_position.y - visual.size.y * 0.18
		$CollisionShape2D.set_deferred("disabled", true)
		for child in get_children():
			if child is CanvasItem and child != visual and child.name != "NameLabel" and child.name != "Artwork":
				child.hide()
		$NameLabel.text = str(name) + " · ruínas"
	else:
		visual.color = _original_color.lerp(damaged_color, damage_ratio)
		visual.scale = _original_scale.lerp(Vector2(0.85, 0.85), damage_ratio)


func closest_point(point: Vector2) -> Vector2:
	var modular = get_node_or_null("PhysicalHouse")
	if modular == null:
		modular = get_node_or_null("ModularStructure")
	if modular != null:
		return modular.closest_point(point)
	var rect := Rect2(global_position + visual.position, visual.size * visual.scale)
	return Vector2(clampf(point.x, rect.position.x, rect.end.x), clampf(point.y, rect.position.y, rect.end.y))
