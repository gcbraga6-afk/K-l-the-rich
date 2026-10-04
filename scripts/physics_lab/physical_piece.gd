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
	var parts: Array = Fracture.shards(polygon, count, focus_local)
	var total := maxf(Fracture.area(polygon), 0.001)
	var inherited := impulse / maxf(mass, 0.001)
	var skin := get_node_or_null("Skin")
	var host := get_parent()
	var structure = get_meta("structure_owner") if has_meta("structure_owner") else null
	var rng := RandomNumberGenerator.new()
	for part in parts:
		var middle: Vector2 = Fracture.centroid(part)
		var local := PackedVector2Array()
		for point in part:
			local.append(point - middle)
		var hull := Geometry2D.convex_hull(local)
		if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
			hull.remove_at(hull.size() - 1)
		if hull.size() < 3:
			continue
		var body := RigidBody2D.new()
		body.set_script(Shard)
		body.shard = hull
		body.tint = tint
		body.owner_structure = structure
		body.mass = maxf(mass * Fracture.area(part) / total, 0.05)
		body.global_position = to_global(middle)
		body.global_rotation = global_rotation
		body.collision_layer = 8
		body.collision_mask = 1 | 8 | 16
		var collider := CollisionShape2D.new()
		var convex := ConvexPolygonShape2D.new()
		convex.points = hull
		collider.shape = convex
		body.add_child(collider)
		# Each shard keeps the painted facade it came from, so breaking a wall
		# never turns it into flat grey blocks.
		var painted := _paint(skin, part, middle)
		if painted != null:
			body.add_child(painted)
		host.add_child(body)
		# Spread around the inherited velocity, so the shards fan out from the hit.
		var away := (middle - focus_local).normalized() if middle.distance_to(focus_local) > 1.0 else Vector2.UP
		body.linear_velocity = inherited + away * rng.randf_range(40.0, 150.0)
		body.angular_velocity = rng.randf_range(-2.5, 2.5)
	var puff := DustPuff.new()
	puff.configure(clampf(inherited.length() / 420.0, 0.4, 1.4), tint)
	puff.global_position = to_global(focus_local)
	host.add_child(puff)
	queue_free()

func _collision_polygon() -> PackedVector2Array:
	for child in get_children():
		if child is CollisionShape2D and child.shape is ConvexPolygonShape2D:
			return (child.shape as ConvexPolygonShape2D).points
		if child is CollisionPolygon2D:
			return (child as CollisionPolygon2D).polygon
	return outline

# Maps a shard back onto the facade's texture, reusing the affine relation the
# original skin already carries between its polygon and its uv.
func _paint(skin: Node, part: PackedVector2Array, middle: Vector2) -> Polygon2D:
	if skin == null or not (skin is Polygon2D):
		return null
	var source := skin as Polygon2D
	if source.texture == null or source.uv.size() < 3 or source.polygon.size() < 3:
		return null
	var p := source.polygon
	var u := source.uv
	var e1 := p[1] - p[0]
	var e2 := p[2] - p[0]
	var det := e1.x * e2.y - e1.y * e2.x
	if absf(det) < 0.0001:
		return null
	var f1 := u[1] - u[0]
	var f2 := u[2] - u[0]
	var shard_polygon := PackedVector2Array()
	var shard_uv := PackedVector2Array()
	for point in part:
		var d := point - p[0]
		var a := (d.x * e2.y - d.y * e2.x) / det
		var b := (e1.x * d.y - e1.y * d.x) / det
		shard_polygon.append(point - middle)
		shard_uv.append(u[0] + f1 * a + f2 * b)
	var node := Polygon2D.new()
	node.polygon = shard_polygon
	node.uv = shard_uv
	node.texture = source.texture
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	return node

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
