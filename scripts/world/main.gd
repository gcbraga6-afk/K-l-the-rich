extends Node2D

func _ready() -> void:
	EventBus.projectile_fired.connect(_on_projectile_fired)
	EventBus.projectile_impacted.connect(_on_projectile_impacted)
	EventBus.intervention_ended.connect(_on_intervention_ended)


func _on_projectile_fired(event: Dictionary) -> void:
	print("PROJECTILE_FIRED ", event)


func _on_projectile_impacted(event: Dictionary) -> void:
	print("PROJECTILE_IMPACTED ", event)


func _on_intervention_ended(reason: String) -> void:
	print("INTERVENTION_ENDED ", reason)
