extends RigidBody2D

var controller: Node2D
var source_polygon := PackedVector2Array()
var impact_speed := 0.0
var can_fracture := true
var age := 0.0
var quiet_time := 0.0
var struck := {}

func _ready() -> void:
	add_to_group("structural_debris")
	collision_layer = 8
	collision_mask = 1
	contact_monitor = true
	max_contacts_reported = 4
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp = 0.35
	angular_damp = 0.5
	var material := PhysicsMaterial.new()
	material.friction = 0.85
	material.bounce = 0.06
	physics_material_override = material
	body_entered.connect(_on_contact)

func _physics_process(delta: float) -> void:
	age += delta
	if age > 0.4:
		collision_mask = 1 | 8
	impact_speed = maxf(impact_speed * 0.96, linear_velocity.length())
	if can_fracture and age > 0.8 and get_contact_count() > 0 and is_instance_valid(controller):
		can_fracture = false
		controller.call_deferred("fracture_debris", self)
	if get_contact_count() > 0 and linear_velocity.length() < 15 and absf(angular_velocity) < 0.12:
		quiet_time += delta
	else:
		quiet_time = 0.0
	if quiet_time > 1.5:
		freeze = true
		set_physics_process(false)
	if global_position.y > 2000:
		queue_free()

func _on_contact(body: Node) -> void:
	if age < 0.15 or impact_speed < 150:
		return
	var owner_node = body.get_meta("structure_owner") if body.has_meta("structure_owner") else (body if body.has_method("apply_explosion_damage") else null)
	if is_instance_valid(owner_node) and not struck.has(owner_node.get_instance_id()):
		struck[owner_node.get_instance_id()] = true
		owner_node.call_deferred("apply_explosion_damage", 1 if impact_speed < 500 else 2, global_position, 0.6)
	if can_fracture and is_instance_valid(controller):
		can_fracture = false
		controller.call_deferred("fracture_debris", self)
