extends Camera2D

const MIN_SHOT_ZOOM := 0.88
@export var speed := 700.0
@export var min_x := 800.0
@export var max_x := 4560.0
var world_width := 6927.0
var _follow_target: Node2D
var _rest_y := 350.0
var _shake_strength := 0.0
var _shake_duration := 0.0
var _base_offset := Vector2.ZERO
var _shot_origin_x := 0.0
var _furthest_distance := 0.0
var _return_available := false
var _returning := false
var _return_click_held := false

func _ready() -> void:
	zoom = Vector2.ONE
	get_viewport().size_changed.connect(_update_horizontal_limits)
	_update_horizontal_limits()
	position = Vector2(min_x, _rest_y)
	EventBus.projectile_fired.connect(_on_projectile_fired)
	_base_offset = offset
	EventBus.camera_shake_requested.connect(_on_camera_shake_requested)

func _process(delta: float) -> void:
	var direction := Input.get_axis("camera_left", "camera_right")
	var vertical := float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
	if _returning:
		zoom = zoom.lerp(Vector2.ONE,1.0-exp(-9.0*delta))
		_update_horizontal_limits()
		position = position.lerp(Vector2(min_x,_rest_y),1.0-exp(-9.0*delta))
		if position.distance_to(Vector2(min_x,_rest_y)) < 1.0 and zoom.x > 0.999:
			zoom = Vector2.ONE
			_update_horizontal_limits()
			position = Vector2(min_x,_rest_y)
			_returning = false
	elif not is_zero_approx(direction) or not is_zero_approx(vertical):
		_follow_target = null
		position.x = clampf(position.x + direction * speed * delta, min_x, max_x)
		position.y = clampf(position.y + vertical * speed * delta, -1400.0, 400.0)
	elif is_instance_valid(_follow_target):
		_furthest_distance = maxf(_furthest_distance,_follow_target.global_position.x-_shot_origin_x)
		var desired_zoom := lerpf(1.0,MIN_SHOT_ZOOM,smoothstep(3000.0,5500.0,_furthest_distance))
		zoom = zoom.lerp(Vector2.ONE*desired_zoom,1.0-exp(-3.0*delta))
		_update_horizontal_limits()
		var target: Vector2 = _follow_target.global_position
		position.x = lerpf(position.x,clampf(target.x,min_x,max_x),1.0-exp(-8.0*delta))
		# Let the projectile move vertically inside the frame instead of centering it.
		var soft_y := _rest_y + minf(0.0,target.y-_rest_y+180.0)*0.30
		var top_margin_y := target.y+get_viewport_rect().size.y/(2.0*zoom.y)-100.0
		position.y = lerpf(position.y,minf(soft_y,top_margin_y),1.0-exp(-5.0*delta))
		position.y = minf(position.y,target.y+get_viewport_rect().size.y/(2.0*zoom.y)-48.0)
	# An impact holds the view until navigation or the return click.
	if _shake_duration > 0.0:
		_shake_duration = maxf(0.0, _shake_duration - delta)
		offset = _base_offset + Vector2(randf_range(-_shake_strength, _shake_strength), randf_range(-_shake_strength, _shake_strength))
	else:
		offset = _base_offset

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _return_available:
			_return_click_held = true
			return_to_knight()
			get_viewport().set_input_as_handled()
		elif not event.pressed and _return_click_held:
			_return_click_held = false
			get_viewport().set_input_as_handled()

func blocks_aim_input() -> bool:
	return _returning or _return_click_held

func return_to_knight() -> void:
	_follow_target = null
	_return_available = false
	_returning = true
	_shake_duration = 0.0
	offset = _base_offset

func _on_camera_shake_requested(strength: float, duration: float) -> void:
	_shake_strength = strength
	_shake_duration = duration

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_HOME:
			return_to_knight()
		elif event.keycode == KEY_V:
			_follow_target = null
			_returning = false
			zoom = Vector2.ONE
			_update_horizontal_limits()
			position = Vector2(clampf(1500,min_x,max_x),_rest_y)

func _on_projectile_fired(event: Dictionary) -> void:
	_follow_target = event.get("projectile") as Node2D
	_shot_origin_x = _follow_target.global_position.x if is_instance_valid(_follow_target) else position.x
	_furthest_distance = 0.0
	_return_available = true
	_returning = false

static func resting_y(_x: float) -> float:
	return 350.0

func configure_world(width: float) -> void:
	world_width = width
	_update_horizontal_limits()

func _update_horizontal_limits() -> void:
	var half_width := get_viewport_rect().size.x / (2.0*zoom.x)
	min_x = minf(half_width, world_width * 0.5)
	max_x = maxf(min_x, world_width - half_width)
	position.x = clampf(position.x, min_x, max_x)
