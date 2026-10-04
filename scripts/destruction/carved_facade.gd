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
var _art_texture: ImageTexture
var _tear_seed := 0.0
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
	_art_texture = ImageTexture.create_from_image(art)
	_tear_seed = float(hash(str(art.get_size())) % 997)
	_build_interior()
	_build_sprite()
	_rebuild_collision()


# The round takes a bite out of the wall where it lands.
#
# Deferred as a whole: this is called from a collision callback, and rebuilding
# the collision shapes or adding bodies while the physics server is flushing its
# queries raises an engine error. The editor halts the running game on one.
func carve(at: Vector2, radius: float) -> void:
	if mask == null:
		return
	_carve_now.call_deferred(at, radius)


func _carve_now(at: Vector2, radius: float) -> void:
	if mask == null:
		return
	var centre := _to_mask(at)
	var r := maxf(radius / pixel, 3.0)
	var before := _standing_pixels()
	var taken := []
	if centre.y < eaves:
		# Rafters carry the roof across its whole span. Break them and the span
		# comes down as a section; it does not keep a tidy round hole punched in it.
		_collapse_roof(centre.x, r)
	else:
		taken = _punch(centre, r)
	mask_texture.update(mask)
	var removed := before - _standing_pixels()
	if removed <= 0:
		return
	_carved_area += removed
	_spill(at, radius, removed, taken)
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
	# Reaching well up towards the ridge and bounded below by the eaves, so the span
	# comes away as roof and the walls underneath are untouched.
	var chunks := _erode(Vector2(at_x, eaves * 0.86), radius * 1.15, 2.6, 0, int(eaves))
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
		_debris(slab, seed_point,
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
func _punch(centre: Vector2, radius: float) -> Array:
	return _erode(centre, radius, 1.0, int(eaves))


# The blast falls off with distance and is torn up by noise, so no edge anywhere
# is a line: the core goes entirely, the rim comes away speckled and ragged, and
# nothing past the reach is touched. Returns the pixels it took.
#
# `lift` stretches the reach upwards, which is how a roof loses a whole span from
# one hit while a wall only loses what is near it. `top` and `floor_row` bound the
# bite to one part of the building.
func _erode(centre: Vector2, radius: float, lift: float, top: int, floor_row := -1) -> Array:
	var taken := []
	var bottom: int = mask.get_height() if floor_row < 0 else mini(floor_row, mask.get_height())
	var reach := radius * 1.5
	var from_y := maxi(top, int(centre.y - reach * lift))
	var to_y := mini(bottom, int(centre.y + reach))
	var from_x := maxi(0, int(centre.x - reach))
	var to_x := mini(mask.get_width(), int(centre.x + reach))
	for y in range(from_y, to_y):
		for x in range(from_x, to_x):
			var dx := (float(x) - centre.x) / radius
			var dy := (float(y) - centre.y) / radius
			if dy < 0.0:
				dy /= maxf(lift, 0.001)
			var t := sqrt(dx * dx + dy * dy)
			if t > 1.45:
				continue
			var torn := t + _tear(x, y) * 0.5 - 0.22
			if torn <= 1.0:
				if mask.get_pixel(x, y).r > 0.3 and art.get_pixel(x, y).a > 0.3:
					taken.append(Vector2(x, y))
				mask.set_pixel(x, y, Color.BLACK)
			elif torn <= 1.0 + RIM / radius:
				var keep: float = mask.get_pixel(x, y).r
				mask.set_pixel(x, y, Color(minf(keep, 0.4), 0, 0))
	return taken


# Two scales of cell noise: the coarse one tears the outline into lumps, the fine
# one frays its edge pixel by pixel.
func _tear(x: int, y: int) -> float:
	return _cell(x / 9, y / 9, 0.0) * 0.65 + _cell(x / 3, y / 3, 31.0) * 0.35


func _cell(cx: int, cy: int, salt: float) -> float:
	var n: float = sin(float(cx) * 12.9898 + float(cy) * 78.233 + _tear_seed + salt) * 43758.5453
	return n - floor(n)


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
func _spill(at: Vector2, radius: float, removed: int, taken: Array) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash("%d:%d" % [int(at.x), int(at.y)])
	var count := clampi(int(removed / 260.0), 3, 10)
	for i in count:
		var size := radius * rng.randf_range(0.10, 0.24)
		var chunk := PackedVector2Array()
		for corner in range(5):
			var angle := TAU * corner / 5.0 + rng.randf_range(-0.3, 0.3)
			chunk.append(Vector2.RIGHT.rotated(angle) * size * rng.randf_range(0.7, 1.3))
		# Cut from a spot the blast actually took, so the chunk carries that paint.
		var from: Vector2 = taken[rng.randi_range(0, taken.size() - 1)] if not taken.is_empty() else _to_mask(at)
		_debris(chunk, from,
			Vector2(rng.randf_range(-150.0, 150.0), rng.randf_range(-260.0, -60.0)),
			Color("9d9280"), 1.0)
	var puff := DustPuff.new()
	puff.configure(clampf(float(removed) / 2600.0, 0.5, 1.5), Color("b3a994"))
	puff.position = to_local(at)
	add_child(puff)


# One piece of the building, cut from the facade's own pixels so a tile falls
# looking like a tile and plaster falls looking like plaster. Flat colour is what
# made the rubble read as plastic.
func _debris(shape: PackedVector2Array, origin_px: Vector2, velocity: Vector2, colour: Color, weight: float) -> void:
	var body := RigidBody2D.new()
	body.set_script(Shard)
	body.shard = shape
	body.generation = 2
	body.owner_structure = owner_structure
	body.mass = weight
	body.tint = colour
	body.position = base_offset + origin_px * pixel
	body.collision_layer = 8
	body.collision_mask = 1 | 8
	body.z_as_relative = false
	body.z_index = 5
	var collider := CollisionShape2D.new()
	var convex := ConvexPolygonShape2D.new()
	convex.points = Geometry2D.convex_hull(shape)
	collider.shape = convex
	body.add_child(collider)
	var skin := Polygon2D.new()
	skin.name = "Skin"
	skin.polygon = shape
	var uv := PackedVector2Array()
	for point in shape:
		uv.append(origin_px + point / pixel)
	skin.uv = uv
	skin.texture = _art_texture
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(skin)
	body.show_skin = true
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
# The room behind the facade: a back wall, a floor and the joists over them, and
# nothing else. It is always there and always hidden; a breach is what reveals it.
# Kept plain so one room reads correctly behind any of the twenty cottages, and so
# replacing it with painted art later changes nothing else.
# The room behind the facade: a back wall, a floor and the joists over them.
# It is always there and always hidden; a breach is what reveals it.
#
# Painted far lighter than a real room would look from outside in daylight. At
# this size a physically honest interior is a black hole in the wall and reads as
# nothing at all; the eye needs the floor and the back wall to actually separate.
func _build_interior() -> void:
	var w := art.get_width()
	var h := art.get_height()
	var room := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(art.get_size()) + str(eaves))
	var wall := Color("584736")
	var floor_tone := Color("7a6449")
	var timber := Color("33281d")
	var roof_space := Color("2e251b")
	var floor_y := int(h * 0.80)
	var ceiling := int(h * 0.34)
	# Roof space above the joists is the darkest part of the house.
	for y in range(h):
		for x in range(w):
			room.set_pixel(x, y, roof_space if y < ceiling else wall)
	# The back wall, shaded down towards the eaves so it has somewhere to recede to.
	for y in range(ceiling, floor_y):
		var depth := float(y - ceiling) / maxf(float(floor_y - ceiling), 1.0)
		var shade := wall.darkened(0.30 * (1.0 - depth))
		for x in range(w):
			room.set_pixel(x, y, shade)
	# Boards on the back wall, alternating so the surface has a grain to catch.
	for i in range(13):
		var bx := int(w * (0.03 + 0.075 * i))
		_fill(room, Rect2i(bx, ceiling, 3, floor_y - ceiling), wall.darkened(0.22))
		_fill(room, Rect2i(bx + 3, ceiling, 2, floor_y - ceiling), wall.lightened(0.10))
	# The floor plane. This is what actually sells depth: a surface going back.
	_fill(room, Rect2i(0, floor_y, w, h - floor_y), floor_tone)
	_fill(room, Rect2i(0, floor_y, w, 3), floor_tone.lightened(0.25))
	for i in range(9):
		var fy := floor_y + 4 + i * 4
		if fy < h:
			_fill(room, Rect2i(0, fy, w, 1), floor_tone.darkened(0.14))
	# Joists over the room, snapped and hanging where the roof came down.
	_fill(room, Rect2i(0, ceiling - 2, w, 5), timber)
	for i in range(7):
		var jx := int(w * (0.06 + 0.14 * i))
		var drop := rng.randi_range(0, int(h * 0.16))
		_beam(room, Vector2(jx, ceiling), Vector2(jx + rng.randi_range(-18, 18), ceiling + drop + 12), 4, timber)
	_room_texture = ImageTexture.create_from_image(room)


func _fill(target: Image, box: Rect2i, colour: Color) -> void:
	for y in range(maxi(0, box.position.y), mini(target.get_height(), box.end.y)):
		for x in range(maxi(0, box.position.x), mini(target.get_width(), box.end.x)):
			target.set_pixel(x, y, colour)


# A timber drawn between two points, for joists, table legs and roof members.
func _beam(target: Image, from: Vector2, to: Vector2, thickness: int, colour: Color) -> void:
	var steps := int(maxf(from.distance_to(to), 1.0))
	for i in range(steps + 1):
		var point := from.lerp(to, float(i) / float(steps))
		_fill(target, Rect2i(int(point.x) - thickness / 2, int(point.y) - thickness / 2, thickness, thickness), colour)


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
