extends Node2D

@export_range(0.0, 1.0) var scroll_speed := 0.995
var camera: Camera2D

func _process(_delta: float) -> void:
	if is_instance_valid(camera):
		# Nearby rows share a street. Limit drift even on a full-world traversal.
		position.x = clampf((camera.position.x - 1700.0) * (1.0 - scroll_speed), -6.0, 6.0)
