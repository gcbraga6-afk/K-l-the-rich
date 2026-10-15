extends Node

signal world_event(event: Dictionary)
signal weapon_changed(weapon: String)

signal projectile_fired(event: Dictionary)
signal projectile_impacted(event: Dictionary)
signal structure_hit(event: Dictionary)
signal ammo_changed(current: int, maximum: int)
signal ammo_seized(amount: int, position: Vector2, source: String)
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


# Powder taken off the Kingdom. It reaches the cannon as a count and the rest of
# the Kingdom as a fact, because a cart broken open in a crowded street is an
# event before it is a resupply.
func emit_ammo_seized(amount: int, position: Vector2, source: String) -> void:
	ammo_seized.emit(amount, position, source)
	world_event.emit({
		"type": "AMMO_SEIZED",
		"target": source, "cause": "knight", "position": position,
		"severity": 0.35, "narrative_value": 0.5,
	})


func emit_intervention_ended(reason: String) -> void:
	intervention_ended.emit(reason)


func emit_camera_shake_requested(strength: float, duration: float) -> void:
	camera_shake_requested.emit(strength, duration)
