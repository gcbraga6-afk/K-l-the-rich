extends Camera2D

@export var speed := 700.0
@export var min_x := 640.0
@export var max_x := 4560.0

func _process(delta: float) -> void:
	var direction := Input.get_axis("camera_left", "camera_right")
	position.x = clamp(position.x + direction * speed * delta, min_x, max_x)

