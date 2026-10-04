extends RefCounted

# Voronoi subdivision of a convex polygon, used to break masonry into irregular
# shards instead of rectangles. Irregular shards jam against one another the way
# broken stone does; a stack of boxes only ever slides.
#
# Built on Geometry2D alone, so it needs no addon and no new dependency. The
# patterns are computed once per piece and reused, never per frame.

const FAR := 20000.0


# Shards of `polygon`, biased towards `focus` when it is given, so the crack
# pattern is finest where the round actually landed.
static func shards(polygon: PackedVector2Array, count: int, focus := Vector2.INF, rng: RandomNumberGenerator = null) -> Array:
	if polygon.size() < 3 or count < 2:
		return [polygon]
	if rng == null:
		rng = RandomNumberGenerator.new()
	var seeds := _seeds(polygon, count, focus, rng)
	if seeds.size() < 2:
		return [polygon]
	var cells := []
	for i in seeds.size():
		var cell := polygon
		for j in seeds.size():
			if i == j:
				continue
			cell = _half_plane(cell, seeds[i], seeds[j])
			if cell.size() < 3:
				break
		if cell.size() >= 3 and area(cell) > 1.0:
			cells.append(cell)
	return cells if cells.size() > 1 else [polygon]


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
