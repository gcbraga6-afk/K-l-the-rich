extends RefCounted

# Voronoi subdivision of a convex polygon, used to break masonry into irregular
# shards instead of rectangles. Irregular shards jam against one another the way
# broken stone does; a stack of boxes only ever slides.
#
# Built on Geometry2D alone, so it needs no addon and no new dependency. The
# patterns are computed once per piece and reused, never per frame.

const FAR := 20000.0

# Breaking stone down without end is a combinatorial trap: eight shards that each
# split into five, twice over, is hundreds of bodies from a single wall. Past this
# many live shards the stone stops subdividing and is only thrown around.
const SHARD_BUDGET := 160


# Shards of `polygon`, biased towards `focus` when it is given, so the crack
# pattern is finest where the round actually landed.
static func shards(polygon: PackedVector2Array, count: int, focus := Vector2.INF, rng: RandomNumberGenerator = null) -> Array:
	if polygon.size() < 3 or count < 2:
		return [polygon]
	if rng == null:
		rng = seeded(polygon)
	# Snapped so sub-pixel differences in the contact point cannot change which
	# pattern comes out: the same wall broken by the same hit breaks the same way.
	if focus.x != INF:
		focus = Vector2(snappedf(focus.x, 8.0), snappedf(focus.y, 8.0))
	var seeds := _seeds(polygon, count, focus, rng)
	if seeds.size() < 2:
		return [polygon]
	var total := area(polygon)
	var cells := []
	for i in seeds.size():
		var cell := polygon
		for j in seeds.size():
			if i == j:
				continue
			cell = _half_plane(cell, seeds[i], seeds[j])
			if cell.size() < 3:
				break
		# Slivers are poison for the solver: a near degenerate convex shape makes
		# contact resolution diverge and bodies fly off to absurd coordinates.
		if cell.size() >= 3 and area(cell) >= maxf(6.0, total * 0.04) and thickness(cell) >= 3.0:
			cells.append(cell)
	return cells if cells.size() > 1 else [polygon]


# Builds the shard bodies for a polygon that is breaking up. Shared by masonry
# breaking for the first time and by rubble being broken again, so both produce
# the same kind of stone.
#
# options: polygon, count, focus (local), inherited (Vector2), mass, tint,
# structure, generation, skin (Polygon2D or null)
static func scatter(host: Node, source: Node2D, options: Dictionary) -> int:
	var Shard = load("res://scripts/destruction/stone_shard.gd")
	var polygon: PackedVector2Array = options.polygon
	var focus: Vector2 = options.focus
	var inherited: Vector2 = options.inherited
	var tree := host.get_tree()
	var live: int = tree.get_nodes_in_group("stone_shards").size() if tree != null else 0
	if live >= SHARD_BUDGET:
		return 0
	var allowance: int = mini(int(options.count), SHARD_BUDGET - live)
	if allowance < 2:
		return 0
	var parts: Array = shards(polygon, allowance, focus)
	if parts.size() < 2:
		return 0
	var total := maxf(area(polygon), 0.001)
	var rng := seeded(polygon)
	var made := 0
	for part in parts:
		var middle: Vector2 = centroid(part)
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
		body.tint = options.tint
		body.owner_structure = options.structure
		body.generation = options.generation
		body.mass = maxf(float(options.mass) * area(part) / total, 0.04)
		body.global_position = source.to_global(middle)
		body.global_rotation = source.global_rotation
		body.collision_layer = 8
		body.collision_mask = 1 | 8 | 16
		body.z_as_relative = false
		body.z_index = 5
		var collider := CollisionShape2D.new()
		var convex := ConvexPolygonShape2D.new()
		convex.points = hull
		collider.shape = convex
		body.add_child(collider)
		# Each shard keeps the slice of painted facade it came from, so breaking a
		# wall never turns it into flat grey blocks.
		var painted := paint(options.get("skin"), part, middle)
		if painted != null:
			painted.name = "Skin"
			body.add_child(painted)
		host.add_child(body)
		# A shard has left the building, so it must not prop up the courses above
		# the crater: otherwise the hole fills with its own rubble and nothing
		# sinks. It still collides with other buildings, and can damage them.
		for sibling in host.get_children():
			if sibling is RigidBody2D and sibling != body and sibling.collision_layer == 16:
				body.add_collision_exception_with(sibling)
		var away := (middle - focus).normalized() if middle.distance_to(focus) > 1.0 else Vector2.UP
		body.linear_velocity = inherited + away * rng.randf_range(40.0, 150.0)
		body.angular_velocity = rng.randf_range(-2.5, 2.5)
		made += 1
	return made


# Maps a shard back onto the facade's texture, reusing the affine relation the
# source skin already carries between its polygon and its uv.
static func paint(skin, part: PackedVector2Array, middle: Vector2) -> Polygon2D:
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


# Derived from the piece's own geometry, so breaking is reproducible: the kingdom
# is persistent, and a test that fires the same shot must get the same rubble.
static func seeded(polygon: PackedVector2Array) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	var middle := centroid(polygon)
	rng.seed = hash("%d:%d:%d" % [int(snappedf(middle.x, 0.5) * 2.0), int(snappedf(middle.y, 0.5) * 2.0), int(area(polygon))])
	return rng


# Shortest side of the bounding box: a cheap stand-in for how sliver-like a shape
# is, and enough to keep degenerate stones out of the simulation.
static func thickness(polygon: PackedVector2Array) -> float:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	return minf(bounds.size.x, bounds.size.y)


static func area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5


static func centroid(polygon: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	for point in polygon:
		sum += point
	return sum / polygon.size()


static func _seeds(polygon: PackedVector2Array, count: int, focus: Vector2, rng: RandomNumberGenerator) -> Array:
	var bounds := Rect2(polygon[0], Vector2.ZERO)
	for point in polygon:
		bounds = bounds.expand(point)
	var result := []
	var attempts := 0
	while result.size() < count and attempts < count * 40:
		attempts += 1
		var candidate := Vector2(
			rng.randf_range(bounds.position.x, bounds.end.x),
			rng.randf_range(bounds.position.y, bounds.end.y))
		# Pull part of the pattern towards the impact so the crater is finely
		# broken while the far side of the piece stays in bigger slabs.
		if focus.x != INF and result.size() % 2 == 1:
			candidate = candidate.lerp(focus, rng.randf_range(0.35, 0.85))
		if Geometry2D.is_point_in_polygon(candidate, polygon):
			result.append(candidate)
	return result


static func _half_plane(polygon: PackedVector2Array, keep: Vector2, other: Vector2) -> PackedVector2Array:
	var normal := other - keep
	if normal.length() < 0.001:
		return polygon
	normal = normal.normalized()
	var middle := (keep + other) * 0.5
	var along := Vector2(-normal.y, normal.x)
	# Everything past the bisector, away from `keep`, is cut off.
	var cutter := PackedVector2Array([
		middle + along * FAR,
		middle - along * FAR,
		middle - along * FAR + normal * FAR,
		middle + along * FAR + normal * FAR,
	])
	var parts := Geometry2D.clip_polygons(polygon, cutter)
	var best := PackedVector2Array()
	var best_area := 0.0
	for part in parts:
		if Geometry2D.is_polygon_clockwise(part):
			continue
		var size := area(part)
		if size > best_area:
			best_area = size
			best = part
	return best
