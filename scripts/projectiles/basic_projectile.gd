extends RigidBody2D

@export var impact_severity := 0.25
@export var narrative_value := 0.1

var _has_impacted := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if _has_impacted:
		return

	_has_impacted = true
	EventBus.emit_projectile_impacted({
		"type": "PROJECTILE_IMPACTED",
		"cause": "knight",
		"target": body.name,
		"position": global_position,
		"severity": impact_severity,
		"narrative_value": narrative_value,
	})

	if body.is_in_group("structures"):
		EventBus.emit_structure_hit({
			"type": "STRUCTURE_HIT",
			"cause": "knight",
			"target": body.name,
			"position": global_position,
			"severity": impact_severity,
			"narrative_value": narrative_value,
		})

	queue_free()

