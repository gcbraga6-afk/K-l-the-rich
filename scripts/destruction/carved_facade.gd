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
const RIM := 3.0           # pixels of scorched edge around every hole

var art: Image                       # the facade, lifted out of its atlas
var mask: Image                      # white where the wall still stands
var mask_texture: ImageTexture
var pixel := 1.0                     # world units per mask pixel
var base_offset := Vector2.ZERO      # top left of the facade, in local units
var owner_structure: Node = null

var _sprite: Sprite2D
var _room_texture: ImageTexture
var _collider: StaticBody2D
var _carved_area := 0.0
var eaves := 0.0      # mask row where the roof ends and the walls begin


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
	eaves = _find_eaves()
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
	if centre.y < eaves:
		# Rafters carry the roof across its whole span. Break them and the span
		# comes down as a section; it does not keep a tidy round hole punched in it.
		_collapse_roof(centre.x, r)
	else:
		_punch(centre, r)
	mask_texture.update(mask)
	var removed := before - _standing_pixels()
	if removed <= 0:
		return
	_carved_area += removed
	_spill(at, radius, removed)
	_drop_unsupported()
	_rebuild_collision()


# The row at which the silhouette stops widening: below it the walls are plumb,
# above it the roof slopes in. Derived from the art, so no house needs authoring.
func _find_eaves() -> float:
	var widest := 0
	var at_row := float(art.get_height()) * 0.42
	for y in range(art.get_height()):
		var span := 0
		for x in range(art.get_width()):
			if art.get_pixel(x, y).a > 0.3:
				span += 1
		if span > widest:
			widest = span
			at_row = float(y)
	return clampf(at_row, art.get_height() * 0.18, art.get_height() * 0.62)


# A span of roof loses its rafters and falls in, carrying its tiles with it.
func _collapse_roof(at_x: float, radius: float) -> void:
	var half := radius * 1.5
	var left := int(clampf(at_x - half, 0.0, art.get_width()))
	var right := int(clampf(at_x + half, 0.0, art.get_width()))
	var chunks := []
	for x in range(left, right):
		for y in range(0, int(eaves)):
			if mask.get_pixel(x, y).r > 0.3 and art.get_pixel(x, y).a > 0.3:
				mask.set_pixel(x, y, Color.BLACK)
				chunks.append(Vector2(x, y))
	if chunks.is_empty():
		return
	# The span does not vanish: it drops into the room as real pieces of roof.
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("roof:%d" % int(at_x))
	# Tiles, not slabs. The radius is in mask pixels, so it has to come back into
	# world units or the roof sheds pieces larger than the house it came off.
	var tile := radius * pixel
	var pieces := clampi(chunks.size() / 240, 4, 14)
	for i in pieces:
		var seed_point: Vector2 = chunks[rng.randi_range(0, chunks.size() - 1)]
		var span := tile * rng.randf_range(0.09, 0.17)
		var slab := PackedVector2Array([
			Vector2(-span * 1.7, -span * 0.42),
			Vector2(span * 1.7, -span * 0.52),
			Vector2(span * 1.6, span * 0.46),
			Vector2(-span * 1.8, span * 0.40)])
		# A roof falls in on itself: the span drops into the room, it does not burst
		# outwards like something thrown.
		_debris(slab, base_offset + seed_point * pixel,
			Vector2(rng.randf_range(-45.0, 45.0), rng.randf_range(30.0, 150.0)),
			Color("a8603f"), 0.7)
	var puff := DustPuff.new()
	puff.configure(1.4, Color("b3a994"))
	puff.position = base_offset + Vector2(at_x, eaves * 0.6) * pixel
	add_child(puff)


func standing_ratio() -> float:
	if art == null:
		return 0.0
	return float(_standing_pixels()) / float(art.get_width() * art.get_height())


# A ragged bite, not a clean circle: masonry breaks along its own faults.
func _punch(centre: Vector2, radius: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d:%d" % [int(centre.x), int(centre.y), int(radius)])
	# The outline is broken up by three harmonics instead of being a circle, so the
	# breach has the torn, uneven edge that shelled masonry actually leaves.
	var phase := Vector3(rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU), rng.randf_range(0.0, TAU))
	var box := Rect2i(
		Vector2i(maxi(0, int(centre.x - radius * 1.7)), maxi(0, int(centre.y - radius * 1.7))),
		Vector2i.ZERO)
	var far := Vector2i(
		mini(mask.get_width(), int(centre.x + radius * 1.7)),
		mini(mask.get_height(), int(centre.y + radius * 1.7)))
	box.size = far - box.position
	for y in range(box.position.y, box.end.y):
		for x in range(box.position.x, box.end.x):
			var offset := Vector2(x, y) - centre
			var distance := offset.length()
			if distance > radius * 1.6:
				continue
			var angle := offset.angle()
			if y < eaves:
				continue
			var limit: float = radius * (0.74
				+ 0.17 * sin(angle * 3.0 + phase.x)
				+ 0.11 * sin(angle * 7.0 + phase.y)
				+ 0.07 * sin(angle * 13.0 + phase.z))
			if distance <= limit:
				mask.set_pixel(x, y, Color.BLACK)
			elif distance <= limit + RIM:
				# A dusted, scorched rim, so the opening never reads as a clean cut.
				var keep: float = mask.get_pixel(x, y).r
				mask.set_pixel(x, y, Color(minf(keep, 0.4), 0, 0))


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
		body.position = to_local(at) + Vector2(rng.randf_range(-radius, radius) * 0.5, rng.randf_range(-radius, radius) * 0.5)
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
	puff.position = to_local(at)
	add_child(puff)


func _debris(shape: PackedVector2Array, where: Vector2, velocity: Vector2, colour: Color, weight: float) -> void:
	var body := RigidBody2D.new()
	body.set_script(Shard)
	body.shard = shape
	body.generation = 2
	body.owner_structure = owner_structure
	body.mass = weight
	body.tint = colour
	body.position = where
	body.collision_layer = 8
	body.collision_mask = 1 | 8
	body.z_as_relative = false
	body.z_index = 5
	var collider := CollisionShape2D.new()
	var convex := ConvexPolygonShape2D.new()
	convex.points = Geometry2D.convex_hull(shape)
	collider.shape = convex
	body.add_child(collider)
	add_child(body)
	body.linear_velocity = velocity
	body.angular_velocity = randf_range(-2.0, 2.0)


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
	material.set_shader_parameter("room_tex", _room_texture)
	_sprite.material = material
	add_child(_sprite)


# A room behind the wall, so a hole shows depth instead of the landscape.
func _build_interior() -> void:
	var room := Image.create(art.get_width(), art.get_height(), false, Image.FORMAT_RGBA8)
	var height := art.get_height()
	var width := art.get_width()
	var dark := Color("241c15")
	for y in range(height):
		var depth := float(y) / float(height)
		# Darker up under the eaves, a shade lighter where the floor catches light.
		var shade := dark.lightened(0.02 + depth * 0.14)
		for x in range(width):
			room.set_pixel(x, y, shade)
	# A floor plane and the joists over it: what makes a breach read as a room with
	# depth rather than as a flat dark patch.
	var floor_y := int(height * 0.74)
	for x in range(width):
		for y in range(floor_y, height):
			room.set_pixel(x, y, dark.lightened(0.22 - float(y - floor_y) / float(height) * 0.1))
		room.set_pixel(x, floor_y, dark.lightened(0.34))
	for beam in range(7):
		var bx := int(width * (0.08 + 0.14 * beam))
		for y in range(int(height * 0.08), int(height * 0.3)):
			for thickness in range(3):
				if bx + thickness < width:
					room.set_pixel(bx + thickness, y, dark.lightened(0.26))
	for x in range(width):
		for thickness in range(3):
			var ry := int(height * 0.3) + thickness
			if ry < height:
				room.set_pixel(x, ry, dark.lightened(0.2))
	_room_texture = ImageTexture.create_from_image(room)


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
