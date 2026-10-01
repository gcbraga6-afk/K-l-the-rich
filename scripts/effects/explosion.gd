extends Node2D

@export var radius := 155.0
@export var max_damage := 2
@export var lifetime := 0.75

@onready var blast: ColorRect = $Blast

func _ready() -> void:
	_apply_damage()
	_spawn_debris()
	EventBus.emit_camera_shake_requested(11.0, 0.24)

	var tween := create_tween()
	blast.scale = Vector2.ZERO
	blast.modulate = Color(1.0, 0.7, 0.22, 0.72)
	tween.tween_property(blast, "scale", Vector2(radius / 24.0, radius / 24.0), 0.12)
	tween.tween_property(blast, "modulate", Color(0.35, 0.2, 0.08, 0.0), 0.38)

	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _apply_damage() -> void:
	for node in get_tree().get_nodes_in_group("structures"):
		if not node.has_method("apply_explosion_damage"):
			continue

		var distance := global_position.distance_to(node.global_position)
		if distance > radius:
			continue

		var falloff := 1.0 - distance / radius
		var damage := maxi(1, ceili(float(max_damage) * falloff))
		node.apply_explosion_damage(damage, global_position, falloff)


func _spawn_debris() -> void:
	for i in range(14):
		var piece := RigidBody2D.new()
		piece.gravity_scale = 1.0
		piece.global_position = global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-10.0, 10.0))
		piece.linear_velocity = Vector2.RIGHT.rotated(randf_range(0.0, TAU)) * randf_range(160.0, 440.0)
		piece.angular_velocity = randf_range(-10.0, 10.0)
		piece.collision_layer = 0
		piece.collision_mask = 0

		var visual := ColorRect.new()
		var size := randf_range(5.0, 13.0)
		visual.offset_left = -size * 0.5
		visual.offset_top = -size * 0.5
		visual.offset_right = size * 0.5
		visual.offset_bottom = size * 0.5
		visual.color = Color(randf_range(0.16, 0.34), randf_range(0.11, 0.22), randf_range(0.07, 0.13), 1.0)
		piece.add_child(visual)

		get_tree().current_scene.add_child(piece)
		_fade_and_free(piece)


func _fade_and_free(piece: RigidBody2D) -> void:
	var tween := create_tween()
	tween.tween_interval(randf_range(0.55, 0.95))
	tween.tween_property(piece, "modulate", Color(1, 1, 1, 0), 0.35)
	tween.tween_callback(piece.queue_free)
