extends RigidBody2D

@export var impact_severity := 0.25
@export var narrative_value := 0.1
@export var impact_effect_scene: PackedScene
@export var explosion_scene: PackedScene

var weapon := "Basic"
var _age := 0.0

var _has_impacted := false

func _ready() -> void:
	add_to_group("active_projectiles")
	collision_mask = 1 | 8 | 16
	if weapon == "Basic":
		mass = 6.0
		linear_damp = 0.0
	else:
		# Flash detects masonry without physically pushing it like a cannonball.
		collision_layer = 32
		collision_mask = 1 | 8
		var sensor := Area2D.new()
		sensor.collision_layer = 0
		sensor.collision_mask = 16
		var sensor_shape := CollisionShape2D.new()
		sensor_shape.shape = $CollisionShape2D.shape.duplicate()
		sensor.add_child(sensor_shape)
		sensor.body_entered.connect(_on_body_entered)
		add_child(sensor)
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	# A surviving cannonball may strike more than one physical building.
	if weapon == "Basic" and body.has_meta("physical_house"):
		body.get_meta("physical_house").register_impact(global_position)
	if _has_impacted:
		return

	_has_impacted = true
	var structure = body.get_meta("structure_owner", body)
	EventBus.emit_projectile_impacted({
		"type": "PROJECTILE_IMPACTED",
		"cause": "knight",
		"target": structure.name,
		"part": str(body.name),
		"position": global_position,
		"severity": impact_severity,
		"narrative_value": narrative_value,
	})
	if weapon == "Basic" and body.has_meta("physical_house"):
		# Retain this body: the physics solver transfers the actual momentum.
		return
	EventBus.emit_camera_shake_requested(5.0, 0.16)


	_spawn_impact_effect()
	_spawn_explosion()
	queue_free()


func _spawn_impact_effect() -> void:
	if impact_effect_scene == null:
		return

	var effect := impact_effect_scene.instantiate() as Node2D
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)


func _spawn_explosion() -> void:
	if explosion_scene == null:
		return

	var explosion := explosion_scene.instantiate() as Node2D
	explosion.weapon = weapon
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > 15.0 or global_position.y > 1200.0 or global_position.x < -600.0 or global_position.x > 8200.0:
		queue_free()
