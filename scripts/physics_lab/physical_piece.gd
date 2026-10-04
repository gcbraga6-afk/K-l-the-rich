extends RigidBody2D

var outline := PackedVector2Array()
var tint := Color("9aafbf")
var material_kind := "stone"
var start_position := Vector2.ZERO
var show_debug_art := true
var released := false

var _quiet := 0.0
var _pending_impulse := Vector2.ZERO
var _pending_offset := Vector2.ZERO

func _ready() -> void:
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	linear_damp = 0.08
	angular_damp = 0.15
	can_sleep = true
	contact_monitor = true
	max_contacts_reported = 4
	# Masonry nobody has reached is static collision. It cannot be shoved by an
	# impact, and it cannot slide against its neighbours.
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	freeze = true
	set_physics_process(false)
	start_position = position
	queue_redraw()

func release(impulse: Vector2, offset: Vector2) -> void:
	if released:
		return
	# The flag flips at once so the support cascade sees one consistent state,
	# while the physics server is only touched outside its query flush.
	released = true
	_pending_impulse = impulse
	_pending_offset = offset
	_wake.call_deferred()

func _wake() -> void:
	freeze = false
	# A body that falls asleep on its first step never runs _integrate_forces,
	# and the blast would be lost before it could be applied.
	can_sleep = false
	sleeping = false
	# Stone tumbles a little and stops. It does not spin like a cube or roll away.
	linear_damp = 0.25
	angular_damp = 2.2
	set_physics_process(true)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# Unfreezing resets the body's state, so the blast lands on the first step
	# the body actually takes part in rather than being discarded.
	if _pending_impulse != Vector2.ZERO:
		state.apply_impulse(_pending_impulse, _pending_offset)
		_pending_impulse = Vector2.ZERO

func _physics_process(delta: float) -> void:
	angular_velocity = clampf(angular_velocity, -3.0, 3.0)
	if get_contact_count() > 0 and linear_velocity.length() < 14.0 and absf(angular_velocity) < 0.12:
		_quiet += delta
	else:
		_quiet = 0.0
	# Settled rubble goes back to being scenery: no jitter, no creeping downhill.
	if _quiet > 1.2:
		freeze = true
		set_physics_process(false)

func _draw() -> void:
	if not show_debug_art:
		return
	draw_colored_polygon(outline,tint)
	var border := outline.duplicate()
	border.append(outline[0])
	draw_polyline(border,tint.darkened(0.45),2,true)
	if material_kind == "wood":
		var bounds := Rect2(outline[0],Vector2.ZERO)
		for p in outline:
			bounds = bounds.expand(p)
		for i in range(2):
			var y := bounds.position.y+7+i*8
			draw_line(Vector2(bounds.position.x+8,y),Vector2(bounds.end.x-8,y),tint.darkened(0.25),1,true)
	elif material_kind == "stone":
		draw_line(outline[0]+Vector2(5,5),outline[1]+Vector2(-5,5),tint.lightened(0.25),2,true)
