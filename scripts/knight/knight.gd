extends Node2D

@export var projectile_scene: PackedScene
@export var muzzle_speed := 900.0
@export var cooldown_seconds := 0.8

@onready var cannon_pivot: Node2D = $CannonPivot

var _cooldown := 0.0

func _process(delta: float) -> void:
	_cooldown = maxf(0.0, _cooldown - delta)
	_aim_at_mouse()

	if Input.is_action_just_pressed("fire") and _cooldown <= 0.0:
		_fire()


func _aim_at_mouse() -> void:
	cannon_pivot.look_at(get_global_mouse_position())


func _fire() -> void:
	if projectile_scene == null:
		return

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

	_cooldown = cooldown_seconds

