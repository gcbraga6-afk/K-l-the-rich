extends RigidBody2D

# One piece of broken stone. It inherits the velocity of the masonry it came
# from, tumbles briefly, raises dust where it lands and then freezes into
# scenery. Stone does not bounce and does not roll far.
#
# A shard travelling fast damages whatever building it reaches, so a round can
# throw rubble into the house next door.

const DustPuff = preload("res://scripts/destruction/dust_puff.gd")

var owner_structure: Node = null
var tint := Color("9aafbf")
var shard := PackedVector2Array()

var _quiet := 0.0
var _peak := 0.0
var _struck := {}
var _landed := false

func _ready() -> void:
	add_to_group("stone_shards")
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	linear_damp = 0.3
	angular_damp = 2.4
	can_sleep = false
	contact_monitor = true
	max_contacts_reported = 4
	var stone := PhysicsMaterial.new()
	stone.friction = 0.95
	stone.bounce = 0.0
	physics_material_override = stone
	body_entered.connect(_on_contact)

func _physics_process(delta: float) -> void:
	angular_velocity = clampf(angular_velocity, -4.0, 4.0)
	var speed := linear_velocity.length()
	_peak = maxf(_peak * 0.96, speed)
	if get_contact_count() > 0:
		if not _landed and _peak > 120.0:
			_landed = true
			_raise_dust(0.45)
		if speed < 16.0 and absf(angular_velocity) < 0.15:
			_quiet += delta
		else:
			_quiet = 0.0
	else:
		_quiet = 0.0
	if _quiet > 0.9:
		freeze = true
		set_physics_process(false)
	if global_position.y > 2200.0:
		queue_free()

func _on_contact(body: Node) -> void:
	if _peak < 170.0:
		return
	var hit = body.get_meta("structure_owner") if body.has_meta("structure_owner") else null
	if hit == null or hit == owner_structure or not is_instance_valid(hit):
		return
	if _struck.has(hit.get_instance_id()) or not hit.has_method("apply_explosion_damage"):
		return
	_struck[hit.get_instance_id()] = true
	# Flying rubble is a real cause of damage, not just decoration.
	hit.call_deferred("apply_explosion_damage", 1 if _peak < 520.0 else 2, global_position, 0.5)

func _raise_dust(strength: float) -> void:
	var puff := DustPuff.new()
	puff.configure(strength, tint)
	puff.global_position = global_position
	get_parent().add_child(puff)

func _draw() -> void:
	if shard.size() < 3:
		return
	draw_colored_polygon(shard, tint)
	var border := shard.duplicate()
	border.append(shard[0])
	# The broken faces show raw stone, so a shard never reads as a painted cube.
	draw_polyline(border, tint.darkened(0.5), 1.5, true)
