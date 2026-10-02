extends Node

signal world_event(event: Dictionary)
signal weapon_changed(weapon: String)

signal projectile_fired(event: Dictionary)
signal projectile_impacted(event: Dictionary)
signal structure_hit(event: Dictionary)
signal ammo_changed(current: int, maximum: int)
signal intervention_ended(reason: String)
signal camera_shake_requested(strength: float, duration: float)

func emit_projectile_fired(event: Dictionary) -> void:
	projectile_fired.emit(event)


func emit_projectile_impacted(event: Dictionary) -> void:
	projectile_impacted.emit(event)


func emit_structure_hit(event: Dictionary) -> void:
	structure_hit.emit(event)


func emit_ammo_changed(current: int, maximum: int) -> void:
	ammo_changed.emit(current, maximum)


func emit_intervention_ended(reason: String) -> void:
	intervention_ended.emit(reason)


func emit_camera_shake_requested(strength: float, duration: float) -> void:
	camera_shake_requested.emit(strength, duration)
