extends RefCounted

# Local-energy masonry model, shared by every building made of physical pieces.
#
# Stone does not hand a cannonball's momentum to the whole building. The blast
# spends its energy where it lands: pieces inside the core are thrown out, pieces
# just outside take a decaying share of it, and anything past the radius is left
# alone. Whatever falls afterwards falls because the pieces holding it up are
# gone, not because the shot pushed it sideways.
#
# Pieces stand frozen until something reaches them, so an untouched building is
# static collision and cannot be shoved around by an impact.

const JOINT_TOL := 10.0      # vertical gap still read as a masonry joint
const GROUND_TOL := 12.0     # distance from the lowest course still read as footing
const CORE_RATIO := 0.34      # share of the radius blown out outright
const RELEASE_STRESS := 0.3   # accumulated energy that frees a piece outside the core
const EJECT_SPEED := 420.0    # speed a cratered piece leaves at, at full energy
const NUDGE_IMPULSE := 1200.0 # momentum handed to pieces beyond the core
const SHATTER_ENERGY := 0.3   # energy above which cratered stone breaks instead of coming out whole
const SHARD_COUNT := 8        # shards a broken piece becomes
const RADIAL_SHARE := 0.45    # how much of the throw is radial rather than along the shot
const MAX_DOWNWARD := 0.25    # ejecta cannot be driven down into the footing

var pieces: Array[RigidBody2D] = []
var shape := {}       # instance id -> hull in body space
var supporters := {}  # instance id -> pieces carrying its weight
var anchored := {}    # instance id -> sits on the footing, never falls on its own
var stress := {}      # instance id -> energy taken from blasts so far
var fracture := true  # on-demand fracture; off reproduces whole-piece removal


func build(bodies: Array[RigidBody2D]) -> void:
	pieces = bodies
	var rects := {}
	for body in pieces:
		var id := body.get_instance_id()
		shape[id] = _local_hull(body)
		rects[id] = _global_rect(body, shape[id])
		stress[id] = 0.0
		anchored[id] = false
	var footing := -INF
	for body in pieces:
		footing = maxf(footing, (rects[body.get_instance_id()] as Rect2).end.y)
	for body in pieces:
		var id := body.get_instance_id()
		var rect: Rect2 = rects[id]
		anchored[id] = rect.end.y >= footing - GROUND_TOL
		var below: Array[RigidBody2D] = []
		for other in pieces:
			if other == body:
				continue
			var other_rect: Rect2 = rects[other.get_instance_id()]
			# Only a piece underneath carries weight, and only where they overlap.
			if rect.position.x >= other_rect.end.x - 2.0 or other_rect.position.x >= rect.end.x - 2.0:
				continue
			if absf(other_rect.position.y - rect.end.y) <= JOINT_TOL:
				below.append(other)
		supporters[id] = below
	_anchor_unreachable()


func blast(center: Vector2, radius: float, strength: float, heading := Vector2.ZERO) -> int:
	var core := radius * CORE_RATIO
	var freed := 0
	for body in pieces:
		if not is_instance_valid(body) or body.released:
			continue
		var id := body.get_instance_id()
		var points: PackedVector2Array = shape[id]
		if points.size() < 3:
			continue
		# Measure to the nearest face, so a long piece is not judged by its centre.
		var local := body.to_local(center)
		var near := _closest_local(local, points)
		var distance := 0.0 if Geometry2D.is_point_in_polygon(local, points) else local.distance_to(near)
		if distance > radius:
			continue
		var energy := pow(1.0 - distance / radius, 2.0) * strength
		if distance <= core:
			_free(body, center, near, energy, true, heading)
			freed += 1
			continue
		# Outside the core a single blast only cracks the masonry. Repeated hits
		# on the same spot add up until the course finally gives way, and when it
		# does the material has to leave the wall: a piece merely let loose while
		# still filling its own gap carries the load as before and nothing falls.
		stress[id] = float(stress[id]) + energy
		if float(stress[id]) >= RELEASE_STRESS:
			_free(body, center, near, maxf(energy * 0.5, 0.25), true, heading)
			freed += 1
	settle()
	return freed


func settle() -> void:
	# Gravity does the collapsing. A piece that lost any of its support becomes
	# dynamic and the solver decides whether it tips, slides or holds.
	var changed := true
	while changed:
		changed = false
		for body in pieces:
			if not is_instance_valid(body) or body.released or anchored[body.get_instance_id()]:
				continue
			for support in supporters[body.get_instance_id()]:
				if not is_instance_valid(support) or support.released:
					body.release(Vector2.ZERO, Vector2.ZERO)
					changed = true
					break


func standing() -> int:
	var result := 0
	for body in pieces:
		if is_instance_valid(body) and not body.released:
			result += 1
	return result


func _free(body: RigidBody2D, center: Vector2, near_local: Vector2, energy: float, cratered: bool, heading: Vector2) -> void:
	var contact := body.to_global(near_local)
	# Radially away from the blast, so the hole is actually vacated. The contact
	# point only sets the lever arm, never the direction.
	var radial := body.global_position - center
	if radial.length() < 1.0:
		radial = Vector2.UP
	var direction := radial.normalized()
	if heading != Vector2.ZERO:
		# A cannon round punches the masonry through along its own line. Pure
		# radial ejection would send the course above up and the one below down,
		# and the column would only jam against itself.
		direction = (direction * RADIAL_SHARE + heading.normalized() * (1.0 - RADIAL_SHARE)).normalized()
	# Spall leaves a crater upwards and sideways. A steeply falling round would
	# otherwise drive the whole course straight down into ground it cannot enter,
	# and the wall would take the hit without ever opening up.
	if direction.y > MAX_DOWNWARD:
		direction = Vector2(direction.x, MAX_DOWNWARD).normalized()
		if absf(direction.x) < 0.2:
			direction = Vector2(signf(radial.x) if radial.x != 0.0 else 1.0, MAX_DOWNWARD).normalized()
	# Inside the crater the material is pulverised and carried off whatever it
	# weighs. Beyond it the blast only hands over momentum, so heavy stone
	# barely shifts while a light roof panel is thrown clear.
	var impulse := direction * NUDGE_IMPULSE * energy
	if cratered:
		impulse = direction * EJECT_SPEED * energy * body.mass
		# Enough energy and the stone does not leave as a slab: it breaks up.
		if fracture and energy >= SHATTER_ENERGY and body.has_method("shatter"):
			body.shatter(impulse, body.to_local(center), SHARD_COUNT)
			return
		# Cratered stone stops being part of the building. Without this it would
		# be driven through its own neighbours and grind to a halt between them,
		# leaving the hole full of the rubble that should have left it.
		for other in pieces:
			if other != body and is_instance_valid(other):
				body.add_collision_exception_with(other)
	body.release(impulse, (contact - body.global_position) * 0.3)


func _anchor_unreachable() -> void:
	# A piece with no path down to the footing would collapse on frame one.
	# Anchor it instead: an authored building has to start standing.
	var reached := {}
	var queue: Array[RigidBody2D] = []
	for body in pieces:
		if anchored[body.get_instance_id()]:
			reached[body.get_instance_id()] = true
			queue.append(body)
	while not queue.is_empty():
		var current: RigidBody2D = queue.pop_back()
		for body in pieces:
			var id := body.get_instance_id()
			if reached.has(id):
				continue
			if (supporters[id] as Array).has(current):
				reached[id] = true
				queue.append(body)
	for body in pieces:
		if not reached.has(body.get_instance_id()):
			anchored[body.get_instance_id()] = true


func _local_hull(body: PhysicsBody2D) -> PackedVector2Array:
	var points := PackedVector2Array()
	for child in body.get_children():
		if child is CollisionPolygon2D:
			for point in (child as CollisionPolygon2D).polygon:
				points.append(child.transform * point)
		elif child is CollisionShape2D and child.shape is ConvexPolygonShape2D:
			for point in (child.shape as ConvexPolygonShape2D).points:
				points.append(child.transform * point)
	if points.size() < 3:
		return points
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	return hull


func _global_rect(body: PhysicsBody2D, points: PackedVector2Array) -> Rect2:
	if points.is_empty():
		return Rect2(body.global_position, Vector2.ZERO)
	var rect := Rect2(body.to_global(points[0]), Vector2.ZERO)
	for point in points:
		rect = rect.expand(body.to_global(point))
	return rect


func _closest_local(point: Vector2, polygon: PackedVector2Array) -> Vector2:
	var best := polygon[0]
	var distance := INF
	for i in polygon.size():
		var candidate := Geometry2D.get_closest_point_to_segment(point, polygon[i], polygon[(i + 1) % polygon.size()])
		var squared := point.distance_squared_to(candidate)
		if squared < distance:
			distance = squared
			best = candidate
	return best
