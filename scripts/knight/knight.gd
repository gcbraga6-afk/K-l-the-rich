extends Node2D

@export var projectile_scene: PackedScene
@export var cooldown_seconds := 0.8
@export var max_ammo := 8
@export var aim_touch_radius := 90.0
@export var min_drag_px := 18.0
@export var max_drag_px := 180.0
@export var max_muzzle_speed := 900.0
@export var trajectory_points := 20
@export var trajectory_step := 0.08

@onready var cannon_pivot: Node2D = $CannonPivot
@onready var aim_line: Line2D = $AimLine

var _cooldown := 0.0
var _ammo := 0
var _intervention_active := true
var _is_aiming := false
var _aim_velocity := Vector2.ZERO

func _ready() -> void:
	_ammo = max_ammo
	aim_line.visible = false
	call_deferred("_emit_ammo_changed")


func _emit_ammo_changed() -> void:
	EventBus.emit_ammo_changed(_ammo, max_ammo)

func _process(delta: float) -> void:
	if not _intervention_active:
		return

	_cooldown = maxf(0.0, _cooldown - delta)

	if Input.is_action_just_pressed("fire") and _can_start_aim():
		_is_aiming = true
		aim_line.visible = true

	if _is_aiming:
		_update_drag_aim()

	if Input.is_action_just_released("fire") and _is_aiming:
		_release_aim()


func _can_start_aim() -> bool:
	if _cooldown > 0.0 or _ammo <= 0:
		return false

	var muzzle_position := _muzzle_global_position()
	return get_global_mouse_position().distance_to(muzzle_position) <= aim_touch_radius


func _update_drag_aim() -> void:
	var muzzle_position := _muzzle_global_position()
	var drag := muzzle_position - get_global_mouse_position()
	var distance := drag.length()

	if distance <= 0.001:
		_aim_velocity = Vector2.ZERO
		aim_line.points = PackedVector2Array()
		return

	var clamped_distance := minf(distance, max_drag_px)
	var speed := (clamped_distance / max_drag_px) * max_muzzle_speed
	_aim_velocity = drag.normalized() * speed

	cannon_pivot.rotation = _aim_velocity.angle()
	_update_trajectory_preview(muzzle_position, _aim_velocity)


func _update_trajectory_preview(start_position: Vector2, velocity: Vector2) -> void:
	var gravity := ProjectSettings.get_setting("physics/2d/default_gravity") as float
	var points := PackedVector2Array()
	points.append(to_local(start_position))

	for i in range(1, trajectory_points + 1):
		var t := float(i) * trajectory_step
		var predicted := start_position + velocity * t + Vector2(0.0, 0.5 * gravity * t * t)
		points.append(to_local(predicted))

	aim_line.points = points


func _release_aim() -> void:
	_is_aiming = false
	aim_line.visible = false

	if _aim_velocity.length() < min_drag_px / max_drag_px * max_muzzle_speed:
		return

	_fire(_aim_velocity)


func _fire(velocity: Vector2) -> void:
	if projectile_scene == null or _ammo <= 0:
		return

	_ammo -= 1
	_emit_ammo_changed()

	var projectile := projectile_scene.instantiate() as RigidBody2D
	var direction := velocity.normalized()
	projectile.global_position = _muzzle_global_position()
	projectile.linear_velocity = velocity
	get_tree().current_scene.add_child(projectile)

	EventBus.emit_projectile_fired({
		"type": "PROJECTILE_FIRED",
		"cause": "knight",
		"position": projectile.global_position,
		"direction": direction,
		"narrative_value": 0.0,
	})
	EventBus.emit_camera_shake_requested(2.0, 0.08)

	_cooldown = cooldown_seconds

	if _ammo == 0:
		_end_intervention("ammo_empty")


func _muzzle_global_position() -> Vector2:
	return cannon_pivot.global_position + Vector2.RIGHT.rotated(cannon_pivot.global_rotation) * 76.0


func _end_intervention(reason: String) -> void:
	_intervention_active = false
	EventBus.emit_intervention_ended(reason)
