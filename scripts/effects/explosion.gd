extends Node2D

@export var radius := 155.0
@export var max_damage := 2
@export var lifetime := 0.75

var weapon := "Basic"
var heading := Vector2.ZERO

const FireBurst = preload("res://scripts/effects/fire_burst.gd")

@onready var blast: ColorRect = $Blast

func _ready() -> void:
	_apply_damage()
	if weapon == "Basic":
		# A cannon round burns. Flash is a light, and stays a light.
		var fire := Node2D.new()
		fire.set_script(FireBurst)
		add_child(fire)
		fire.configure(radius * 0.62, 1.0)
	EventBus.emit_camera_shake_requested(11.0, 0.24)

	var tween := create_tween()
	blast.scale = Vector2.ZERO
	blast.modulate = Color(0.8, 0.95, 1.0, 0.9) if weapon == "Flash" else Color(1.0, 0.7, 0.22, 0.72)
	tween.tween_property(blast, "scale", Vector2(radius / 24.0, radius / 24.0), 0.12)
	tween.tween_property(blast, "modulate", Color(0.35, 0.2, 0.08, 0.0), 0.38)

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _apply_damage() -> void:
	for person in get_tree().get_nodes_in_group("people"):
		person.react_to_blast(global_position, weapon)
	if weapon == "Flash":
		return
	for node in get_tree().get_nodes_in_group("structures"):
		if not node.has_method("apply_explosion_damage"):
			continue

		var distance := global_position.distance_to(node.closest_point(global_position))
		if distance > radius:
			continue

		var falloff := 1.0 - distance / radius
		var damage := maxi(1, ceili(float(max_damage) * falloff))
		node.apply_explosion_damage(damage, global_position, falloff, radius, heading)
