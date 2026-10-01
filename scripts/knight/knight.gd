extends Node2D

@export var projectile_scene: PackedScene
@export var muzzle_speed := 900.0
@export var cooldown_seconds := 0.8
@export var max_ammo := 8

@onready var cannon_pivot: Node2D = $CannonPivot
@onready var aim_line: Line2D = $AimLine

var _cooldown := 0.0
var _ammo := 0
var _intervention_active := true

func _ready() -> void:
	_ammo = max_ammo
	call_deferred("_emit_ammo_changed")


func _emit_ammo_changed() -> void:
	EventBus.emit_ammo_changed(_ammo, max_ammo)

func _process(delta: float) -> void:
	if not _intervention_active:
		return

	_cooldown = maxf(0.0, _cooldown - delta)
	_aim_at_mouse()

	if Input.is_action_just_pressed("fire") and _cooldown <= 0.0:
		_fire()


func _aim_at_mouse() -> void:
	cannon_pivot.look_at(get_global_mouse_position())
	var direction := Vector2.RIGHT.rotated(cannon_pivot.global_rotation)
	aim_line.points = PackedVector2Array([
		cannon_pivot.position + direction * 82.0,
		cannon_pivot.position + direction * 210.0,
	])


func _fire() -> void:
	if projectile_scene == null or _ammo <= 0:
		return

	_ammo -= 1
	_emit_ammo_changed()

	var projectile := projectile_scene.instantiate() as RigidBody2D
	var direction := Vector2.RIGHT.rotated(cannon_pivot.global_rotation)
	projectile.global_position = cannon_pivot.global_position + direction * 76.0
	projectile.linear_velocity = direction * muzzle_speed
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


func _end_intervention(reason: String) -> void:
	_intervention_active = false
	EventBus.emit_intervention_ended(reason)
