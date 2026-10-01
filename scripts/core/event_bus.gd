extends Node

signal projectile_fired(event: Dictionary)
signal projectile_impacted(event: Dictionary)
signal structure_hit(event: Dictionary)

func emit_projectile_fired(event: Dictionary) -> void:
	projectile_fired.emit(event)


func emit_projectile_impacted(event: Dictionary) -> void:
	projectile_impacted.emit(event)


func emit_structure_hit(event: Dictionary) -> void:
	structure_hit.emit(event)

