extends Camera2D

@export var speed := 700.0
@export var min_x := 640.0
@export var max_x := 4560.0

var _shake_strength := 0.0
var _shake_duration := 0.0
var _base_offset := Vector2.ZERO

func _ready() -> void:
	_base_offset = offset
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)


func _process(delta: float) -> void:
	var direction := Input.get_axis("camera_left", "camera_right")
	position.x = clamp(position.x + direction * speed * delta, min_x, max_x)

	if _shake_duration > 0.0:
		_shake_duration = maxf(0.0, _shake_duration - delta)
		offset = _base_offset + Vector2(
			randf_range(-_shake_strength, _shake_strength),
			randf_range(-_shake_strength, _shake_strength)
		)
	else:
		offset = _base_offset


func _on_camera_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = duration
