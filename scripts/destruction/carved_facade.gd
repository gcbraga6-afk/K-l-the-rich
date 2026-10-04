extends Node2D

# A shelled building, modelled the way the reference photographs behave: the round
# tears a ragged hole out of the wall and the rest of the house goes on standing.
# The silhouette is a mask the blast punches through, not a stack of blocks, so
# the structure that survives is never handed to the solver and can never topple
# for reasons nobody asked for.
#
# What the hole takes becomes a heap at the foot of the wall. What the hole cuts
# off from the ground stops being part of the house and falls on its own, which is
# how a round brings down one half of a cottage and leaves the other half whole.

const Shard = preload("res://scripts/destruction/stone_shard.gd")
const DustPuff = preload("res://scripts/destruction/dust_puff.gd")
const MASK_SHADER = preload("res://scripts/effects/facade_mask.gdshader")

const GROUND_TOL := 10.0   # distance from the footing still counted as standing on it
const RIM := 2             # pixels of softened edge around every hole

var art: Image                       # the facade, lifted out of its atlas
var mask: Image                      # white where the wall still stands
var mask_texture: ImageTexture
var pixel := 1.0                     # world units per mask pixel
var base_offset := Vector2.ZERO      # top left of the facade, in local units
var owner_structure: Node = null

var _sprite: Sprite2D
var _interior: Node2D
var _collider: StaticBody2D
var _carved_area := 0.0


func setup(texture: Texture2D, width: float, foot_y: float, structure: Node = null) -> void:
	owner_structure = structure
	art = _lift(texture)
	if art == null:
		return
	pixel = width / art.get_width()
	base_offset = Vector2(-width * 0.5, foot_y - art.get_height() * pixel)
	mask = Image.create(art.get_width(), art.get_height(), false, Image.FORMAT_L8)
	mask.fill(Color.WHITE)
	mask_texture = ImageTexture.create_from_image(mask)
	_build_interior()
	_build_sprite()
	_rebuild_collision()


# The round takes a bite out of the wall where it lands.
func carve(at: Vector2, radius: float) -> void:
	if mask == null:
		return
	var centre := _to_mask(at)
	var r := maxf(radius / pixel, 3.0)
	var before := _standing_pixels()
	_punch(centre, r)
	mask_texture.update(mask)
	var removed := before - _standing_pixels()
	if removed <= 0:
		return
	_carved_area += removed
	_spill(at, radius, removed)
	_drop_unsupported()
	_rebuild_collision()


func standing_ratio() -> float:
	if art == null:
		return 0.0
	return float(_standing_pixels()) / float(art.get_width() * art.get_height())


# A ragged bite, not a clean circle: masonry breaks along its own faults.
func _punch(centre: Vector2, radius: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [int(centre.x), int(centre.y), int(radius)])
	var lobes := []
	for i in range(7):
		var angle := rng.randf_range(0.0, TAU)
		var reach := radius * rng.randf_range(0.30, 0.62)
		lobes.append({"at": centre + Vector2.RIGHT.rotated(angle) * reach, "r": radius * rng.randf_range(0.45, 0.78)})
	lobes.append({"at": centre, "r": radius})
	var box := Rect2i(
		Vector2i(maxi(0, int(centre.x - radius * 1.7)), maxi(0, int(centre.y - radius * 1.7))),
		Vector2i.ZERO)
	var far := Vector2i(
		mini(mask.get_width(), int(centre.x + radius * 1.7)),
		mini(mask.get_height(), int(centre.y + radius * 1.7)))
	box.size = far - box.position
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var point := Vector2(x, y)
			var nearest := INF
			for lobe in lobes:
				nearest = minf(nearest, point.distance_to(lobe.at) - lobe.r)
			if nearest <= 0.0:
				mask.set_pixel(x, y, Color.BLACK)
			elif nearest <= RIM:
				# A dusted, scorched rim, so the opening never reads as a clean cut.
				var keep: float = mask.get_pixel(x, y).r
				mask.set_pixel(x, y, Color(minf(keep, 0.55), 0, 0))


# Masonry the hole cut off from the ground is no longer part of the house.
func _drop_unsupported() -> void:
	for polygon in _silhouette():
		var bottom := -INF
		for point in polygon:
			bottom = maxf(bottom, point.y)
		if bottom >= mask.get_height() - GROUND_TOL / pixel:
			continue
		_fall(polygon)
		for point_y in range(mask.get_height()):
			for point_x in range(mask.get_width()):
				if Geometry2D.is_point_in_polygon(Vector2(point_x, point_y), polygon):
					mask.set_pixel(point_x, point_y, Color.BLACK)
	mask_texture.update(mask)


func _fall(polygon: PackedVector2Array) -> void:
	var middle := Vector2.ZERO
	for point in polygon:
		middle += point
	middle /= polygon.size()
	var local := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in polygon:
		local.append((point - middle) * pixel)
		uv.append(point)
	var hull := Geometry2D.convex_hull(local)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	if hull.size() < 3:
		return
	var body := RigidBody2D.new()
	body.set_script(Shard)
	body.shard = hull
	body.generation = 1
	body.owner_structure = owner_structure
	body.mass = maxf(Geometry2D.convex_hull(local).size() * 0.4, 2.0)
	body.position = base_offset + middle * pixel
	body.collision_layer = 8
	body.collision_mask = 1 | 8
	body.z_as_relative = false
	body.z_index = 5
	var collider := CollisionShape2D.new()
	var convex := ConvexPolygonShape2D.new()
	convex.points = hull
	collider.shape = convex
	body.add_child(collider)
	var skin := Polygon2D.new()
	skin.name = "Skin"
	skin.polygon = local
	skin.uv = uv
	skin.texture = ImageTexture.create_from_image(art)
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(skin)
	add_child(body)


# What the wall lost piles up at its foot.
func _spill(at: Vector2, radius: float, removed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [int(at.x), int(at.y)])
	var count := clampi(int(removed / 260.0), 3, 10)
	for i in count:
		var size := radius * rng.randf_range(0.10, 0.24)
		var chunk := PackedVector2Array()
		for corner in range(5):
			var angle := TAU * corner / 5.0 + rng.randf_range(-0.3, 0.3)
			chunk.append(Vector2.RIGHT.rotated(angle) * size * rng.randf_range(0.7, 1.3))
		var body := RigidBody2D.new()
		body.set_script(Shard)
		body.shard = chunk
		body.generation = 2
		body.owner_structure = owner_structure
		body.mass = 1.0
		body.position = at + Vector2(rng.randf_range(-radius, radius) * 0.5, rng.randf_range(-radius, radius) * 0.5)
		body.collision_layer = 8
		body.collision_mask = 1 | 8
		body.z_as_relative = false
		body.z_index = 5
		body.tint = Color("9d9280")
		var collider := CollisionShape2D.new()
		var convex := ConvexPolygonShape2D.new()
		convex.points = Geometry2D.convex_hull(chunk)
		collider.shape = convex
		body.add_child(collider)
		add_child(body)
		# Thrown clear of the wall and down: masonry heaps at the foot, it does not
		# scatter like kindling.
		body.linear_velocity = Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-260.0, -60.0))
		body.angular_velocity = rng.randf_range(-2.0, 2.0)
	var puff := DustPuff.new()
	puff.configure(clampf(float(removed) / 2600.0, 0.5, 1.5), Color("b3a994"))
	puff.position = at
	add_child(puff)


func _standing_pixels() -> int:
	var total := 0
	for y in range(mask.get_height()):
		for x in range(mask.get_width()):
			if mask.get_pixel(x, y).r > 0.3 and art.get_pixel(x, y).a > 0.3:
				total += 1
	return total


func _silhouette() -> Array:
	var bitmap := BitMap.new()
	var combined := Image.create(art.get_width(), art.get_height(), false, Image.FORMAT_RGBA8)
	for y in range(art.get_height()):
		for x in range(art.get_width()):
			var solid: bool = mask.get_pixel(x, y).r > 0.3 and art.get_pixel(x, y).a > 0.3
			combined.set_pixel(x, y, Color(1, 1, 1, 1.0 if solid else 0.0))
	bitmap.create_from_image_alpha(combined, 0.5)
	return bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, Vector2i(art.get_width(), art.get_height())), 2.0)


func _rebuild_collision() -> void:
	if _collider != null:
		_collider.queue_free()
	_collider = StaticBody2D.new()
	_collider.collision_layer = 1
	_collider.collision_mask = 0
	_collider.position = base_offset
	if owner_structure != null:
		_collider.set_meta("structure_owner", owner_structure)
	for polygon in _silhouette():
		for convex in Geometry2D.decompose_polygon_in_convex(polygon):
			var shape := CollisionPolygon2D.new()
			var points := PackedVector2Array()
			for point in convex:
				points.append(point * pixel)
			shape.polygon = points
			_collider.add_child(shape)
	add_child(_collider)


func _build_sprite() -> void:
	_sprite = Sprite2D.new()
	_sprite.name = "Facade"
	_sprite.centered = false
	_sprite.position = base_offset
	_sprite.scale = Vector2.ONE * pixel
	_sprite.texture = ImageTexture.create_from_image(art)
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var material := ShaderMaterial.new()
	material.shader = MASK_SHADER
	material.set_shader_parameter("mask_tex", mask_texture)
	_sprite.material = material
	add_child(_sprite)


# A room behind the wall, so a hole shows depth instead of the landscape.
func _build_interior() -> void:
	_interior = Node2D.new()
	_interior.name = "Interior"
	_interior.z_index = -1
	_interior.set_script(preload("res://scripts/destruction/interior_room.gd"))
	_interior.position = base_offset
	_interior.extent = Vector2(art.get_width(), art.get_height()) * pixel
	add_child(_interior)


func _to_mask(at: Vector2) -> Vector2:
	return (to_local(at) - base_offset) / pixel


func _lift(texture: Texture2D) -> Image:
	if texture is AtlasTexture:
		var atlas := texture as AtlasTexture
		var source := atlas.atlas.get_image()
		return source.get_region(Rect2i(atlas.region))
	if texture == null:
		return null
	return texture.get_image()
