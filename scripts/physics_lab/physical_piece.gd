extends RigidBody2D

const Fracture = preload("res://scripts/destruction/fracture.gd")
const Shard = preload("res://scripts/destruction/stone_shard.gd")
const DustPuff = preload("res://scripts/destruction/dust_puff.gd")

var outline := PackedVector2Array()
var tint := Color("9aafbf")
var material_kind := "stone"
var start_position := Vector2.ZERO
var show_debug_art := true
var released := false
var shattered := false
var allow_fracture := true

# A one-course sink reaches about 300 px/s; a real collapse from roof height
# well over 600. Above this, stone that lands has to break rather than survive.
const IMPACT_SHATTER_SPEED := 380.0

var _quiet := 0.0
var _pending_impulse := Vector2.ZERO
var _pending_offset := Vector2.ZERO
var _peak := 0.0
var _jam := 0.0
var _jam_from := Vector2.ZERO

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

func shatter(impulse: Vector2, focus_local: Vector2, count: int) -> void:
	if released:
		return
	# Flagged gone at once so the support cascade stops counting on this piece,
	# while the bodies are built outside the physics server's query flush.
	released = true
	shattered = true
	_shatter.call_deferred(impulse, focus_local, count)

func _shatter(impulse: Vector2, focus_local: Vector2, count: int) -> void:
	var polygon := _collision_polygon()
	if polygon.size() < 3:
		queue_free()
		return
	var made: int = Fracture.scatter(get_parent(), self, {
		"polygon": polygon,
		"count": count,
		"focus": focus_local,
		"inherited": linear_velocity + impulse / maxf(mass, 0.001),
		"mass": mass,
		"tint": tint,
		"structure": get_meta("structure_owner") if has_meta("structure_owner") else null,
		"generation": 1,
		"skin": get_node_or_null("Skin"),
	})
	var puff := DustPuff.new()
	puff.configure(clampf(impulse.length() / (maxf(mass, 0.001) * 420.0), 0.4, 1.4), tint)
	puff.global_position = to_global(focus_local)
	get_parent().add_child(puff)
	if made == 0:
		shattered = false
		released = true
		_wake.call_deferred()
		return
	queue_free()

# Rubble this piece already became is not scenery. A round landing in it wakes it,
# moves it, knocks dust off it and breaks it down further.
func disturb(center: Vector2, energy: float, impulse: Vector2) -> void:
	if shattered:
		return
	if allow_fracture and energy >= 0.3:
		shatter(impulse, to_local(center), 6)
		return
	# Adds to whatever is already pending, and only touches the physics server
	# once the query flush is over.
	_pending_impulse += impulse
	_pending_offset = Vector2.ZERO
	_quiet = 0.0
	_wake.call_deferred()
	_dust.call_deferred(center, clampf(energy, 0.25, 1.0))

func _dust(at: Vector2, strength: float) -> void:
	var puff := DustPuff.new()
	puff.configure(strength, tint)
	puff.global_position = at
	get_parent().add_child(puff)

func _collision_polygon() -> PackedVector2Array:
	for child in get_children():
		if child is CollisionShape2D and child.shape is ConvexPolygonShape2D:
			return (child.shape as ConvexPolygonShape2D).points
		if child is CollisionPolygon2D:
			return (child as CollisionPolygon2D).polygon
	return outline

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
		# Sleeping was only held off so this impulse could land.
		can_sleep = true
	if not released or shattered or not allow_fracture:
		return
	_peak = maxf(_peak * 0.97, state.linear_velocity.length())
	# Masonry that comes down from a height breaks where it lands. Without this a
	# roof survives the whole collapse as one slab and drops neatly into place.
	if _peak >= IMPACT_SHATTER_SPEED and state.get_contact_count() > 0:
		shatter(Vector2.ZERO, state.get_contact_local_position(0), 7)

func _physics_process(delta: float) -> void:
	angular_velocity = clampf(angular_velocity, -3.0, 3.0)
	# A block wedged between its neighbours stops moving while the solver keeps
	# feeding it gravity, so its velocity climbs without the body going anywhere.
	# Stone under that much load gives way: it breaks instead of staying stuck.
	if linear_velocity.length() > 520.0 and get_contact_count() > 0:
		if position.distance_to(_jam_from) < 2.5:
			_jam += delta
			if _jam > 0.4:
				_jam = 0.0
				if allow_fracture and not shattered:
					shatter(Vector2.ZERO, Vector2.ZERO, 6)
				else:
					linear_velocity = Vector2.ZERO
				return
		else:
			_jam = 0.0
			_jam_from = position
	else:
		_jam = 0.0
		_jam_from = position
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
