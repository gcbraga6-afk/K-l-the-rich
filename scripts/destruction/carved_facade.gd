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
const STEP := 3            # mask pixels decided together, to keep a round cheap
const THROW := 520.0       # how hard a piece at the centre of the blast is hurled
const LOFT := 0.45         # how much of the throw is turned upwards

# What a part of the building is made of, painted alongside its artwork. Without a
# map everything is masonry and the roof is found from the silhouette instead.
enum { NOTHING, WALL, ROOF, WINDOW, TIMBER }

# Painted modules the room is laid up from. Each house draws a different
# combination, so twenty cottages do not share one interior. Missing files are
# tolerated: the room falls back to being drawn in code.
const MODULES := "res://assets/interiors/%s.png"
const WALLS := ["wall_stone", "wall_plank", "wall_plaster", "wall_brick"]
const FLOORS := ["floor_plank", "floor_earth"]
const JOISTS := ["joist_beams", "joist_lath"]
const LOOSE := ["beam_a", "beam_b", "rubble_a", "rubble_b"]

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
# The tearing noise, baked once. Evaluating it with sin() per pixel costs hundreds
# of thousands of calls per round, which is most of a visible freeze on its own.
const NOISE_SIZE := 64
var _noise := PackedFloat32Array()
var _collider: StaticBody2D
var _carved_area := 0.0
# Masonry still standing, kept as a running count and as one image. Recomputing
# either from scratch means walking a quarter of a million pixels in GDScript, and
# that is a visible freeze every time a round lands.
var _solid: Image
var _standing := 0
# Worked on as raw bytes. Image.get_pixel and set_pixel are method calls through
# the binding, and at a quarter of a million of them per round that alone is a
# visible stutter.
var _mask_bytes := PackedByteArray()   # one byte per pixel: masonry still there
var _solid_bytes := PackedByteArray()  # rgba, only the alpha byte is used
var eaves := 0.0      # mask row where the roof ends and the walls begin
var _material := PackedByteArray()   # one byte per pixel, from the painted map
var _window_of := PackedInt32Array() # which window opening a pixel belongs to, 0 for none
var _window_pixels := {}             # opening id -> its pixels
var _gone_windows := {}              # openings already blown out
var _has_map := false                # whether this house carries a painted map


func setup(texture: Texture2D, width: float, foot_y: float, structure: Node = null, materials: Texture2D = null) -> void:
	owner_structure = structure
	art = _lift(texture)
	if art == null:
		return
	pixel = width / art.get_width()
	base_offset = Vector2(-width * 0.5, foot_y - art.get_height() * pixel)
	mask = Image.create(art.get_width(), art.get_height(), false, Image.FORMAT_L8)
	mask.fill(Color.WHITE)
	mask_texture = ImageTexture.create_from_image(mask)
	_solid = Image.create(art.get_width(), art.get_height(), false, Image.FORMAT_RGBA8)
	var count := art.get_width() * art.get_height()
	_mask_bytes.resize(count)
	_solid_bytes.resize(count * 4)
	_standing = 0
	for y in range(art.get_height()):
		for x in range(art.get_width()):
			var index := y * art.get_width() + x
			var opaque: bool = art.get_pixel(x, y).a > 0.3
			_mask_bytes[index] = 255 if opaque else 0
			_solid_bytes[index * 4] = 255
			_solid_bytes[index * 4 + 1] = 255
			_solid_bytes[index * 4 + 2] = 255
			_solid_bytes[index * 4 + 3] = 255 if opaque else 0
			if opaque:
				_standing += 1
	_sync_images()
	_read_materials(materials)
	eaves = _find_eaves()
	_art_texture = ImageTexture.create_from_image(art)
	_tear_seed = float(hash(str(art.get_size())) % 997)
	_noise.resize(NOISE_SIZE * NOISE_SIZE)
	for i in range(NOISE_SIZE * NOISE_SIZE):
		var n: float = sin(float(i % NOISE_SIZE) * 12.9898 + float(i / NOISE_SIZE) * 78.233 + _tear_seed) * 43758.5453
		_noise[i] = n - floor(n)
	_build_interior()
	_build_sprite()
	_rebuild_collision(_silhouette())


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
	# A round that lands beside the house, or in a hole already taken out of it,
	# still bites the nearest masonry rather than chewing empty air.
	# Checked against both dimensions: an x past the width still lands inside the
	# byte array, one row down, and the carve then happens somewhere it cannot reach.
	if not _standing_at(centre):
		centre = _to_mask(closest_point(at))
	var before := _standing_pixels()
	var taken := []
	# Without a painted map every pixel is masonry, so the map cannot be asked what
	# is roof; the eaves line found from the silhouette answers instead.
	var probe_index := int(centre.y) * art.get_width() + int(centre.x)
	var on_roof: bool = centre.y < eaves
	if _has_map and probe_index >= 0 and probe_index < _material.size() and _material[probe_index] != NOTHING:
		on_roof = _material[probe_index] == ROOF
	if on_roof:
		# Rafters carry the roof across its whole span. Break them and the span
		# comes down as a section; it does not keep a tidy round hole punched in it.
		_collapse_roof(centre.x, r)
	else:
		taken = _punch(centre, r)
	_sync_images()
	var removed := before - _standing_pixels()
	if removed <= 0:
		return
	_carved_area += removed
	_spill(at, radius, removed, taken)
	# Rubble already lying here is part of what the next round lands in.
	Shard.disturb_all(get_tree(), at, radius * 1.6, 1.0)
	var shapes: Array = _drop_unsupported(_silhouette())
	_rebuild_collision(shapes)


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
		var span := tile * rng.randf_range(0.07, 0.14)
		var slab := PackedVector2Array()
		for corner in range(6):
			var angle := TAU * corner / 6.0 + rng.randf_range(-0.26, 0.26)
			slab.append(Vector2.RIGHT.rotated(angle) * Vector2(span * 1.7, span * 0.6) * rng.randf_range(0.75, 1.25))
		# A roof falls in on itself: the span drops into the room, it does not burst
		# outwards like something thrown.
		# Near the hit the span is thrown clear; further along it simply drops in.
		var thrown := _hurl(seed_point, Vector2(at_x, eaves * 0.86), radius * 1.3, rng)
		_debris(slab, seed_point, thrown + Vector2(0.0, rng.randf_range(40.0, 120.0)), Color("a8603f"), 0.7)
	var puff := DustPuff.new()
	puff.configure(1.4, Color("b3a994"), radius * pixel / 60.0)
	puff.position = base_offset + Vector2(at_x, eaves * 0.6) * pixel
	add_child(puff)


# Reads the painted material map, if the house has one, and finds each window
# opening as a connected run of window pixels. An opening fails as a whole: that
# is the difference between a shell taking out a window and a shell slicing one
# in half along with the wall it sits in.
func _read_materials(map: Texture2D) -> void:
	var w := art.get_width()
	var h := art.get_height()
	_material.resize(w * h)
	_window_of.resize(w * h)
	_has_map = map != null
	if map == null:
		for i in range(w * h):
			_material[i] = WALL
			_window_of[i] = 0
		return
	var image := map.get_image()
	if image.get_size() != Vector2i(w, h):
		image = image.duplicate()
		image.resize(w, h, Image.INTERPOLATE_NEAREST)
	for y in range(h):
		for x in range(w):
			var index := y * w + x
			_window_of[index] = 0
			var colour := image.get_pixel(x, y)
			if colour.a < 0.3:
				_material[index] = NOTHING
			elif colour.b > 0.5 and colour.b > colour.r + 0.2:
				_material[index] = WINDOW
			elif colour.r > 0.5 and colour.g < 0.45 and colour.b < 0.4:
				_material[index] = ROOF
			elif colour.r > 0.4 and colour.g > 0.25 and colour.b < 0.35:
				_material[index] = TIMBER
			else:
				_material[index] = WALL
	_find_windows(w, h)


func _find_windows(w: int, h: int) -> void:
	var next_id := 0
	for start in range(w * h):
		if _material[start] != WINDOW or _window_of[start] != 0:
			continue
		next_id += 1
		var pixels := []
		var queue := [start]
		_window_of[start] = next_id
		while not queue.is_empty():
			var index: int = queue.pop_back()
			pixels.append(index)
			var x := index % w
			var y := index / w
			for step: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var nx: int = x + step.x
				var ny: int = y + step.y
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var near := ny * w + nx
				if _material[near] == WINDOW and _window_of[near] == 0:
					_window_of[near] = next_id
					queue.append(near)
		_window_pixels[next_id] = pixels


# The nearest point on what is still standing, for working out whether a blast
# reaches this building at all.
func _standing_at(mask_point: Vector2) -> bool:
	if mask_point.x < 0.0 or mask_point.y < 0.0:
		return false
	if mask_point.x >= float(art.get_width()) or mask_point.y >= float(art.get_height()):
		return false
	return _mask_bytes[int(mask_point.y) * art.get_width() + int(mask_point.x)] > 0


func closest_point(point: Vector2) -> Vector2:
	var local := _to_mask(point)
	var w := art.get_width()
	var h := art.get_height()
	var inside := Vector2(clampf(local.x, 0.0, w - 1.0), clampf(local.y, 0.0, h - 1.0))
	var index := int(inside.y) * w + int(inside.x)
	if index >= 0 and index < _mask_bytes.size() and _mask_bytes[index] > 76:
		return to_global(base_offset + inside * pixel)
	# Not on standing masonry: search outward in rings, coarsely, and settle for the
	# clamped point if this building has nothing left near there.
	for ring in range(4, maxi(w, h), 6):
		for step in range(0, 16):
			var probe := inside + Vector2.RIGHT.rotated(TAU * step / 16.0) * ring
			if probe.x < 0.0 or probe.y < 0.0 or probe.x >= w or probe.y >= h:
				continue
			var at := int(probe.y) * w + int(probe.x)
			if _mask_bytes[at] > 76:
				return to_global(base_offset + probe * pixel)
	return to_global(base_offset + inside * pixel)


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
	var touched := {}
	var bottom: int = mask.get_height() if floor_row < 0 else mini(floor_row, mask.get_height())
	# Both bounds wander: a bite that stops dead along one row is the horizontal
	# straight edge that gave the damage its geometric look.
	var wander := radius * 0.45
	var width := mask.get_width()
	var reach := radius * 1.5
	var from_y := maxi(0, int(minf(float(top) - wander, centre.y - reach * lift)))
	var to_y := mini(mask.get_height(), int(maxf(float(bottom) + wander, centre.y + reach)))
	var from_x := maxi(0, int(centre.x - reach))
	var to_x := mini(mask.get_width(), int(centre.x + reach))
	var height := mask.get_height()
	# Decided per block of STEP by STEP rather than per pixel. A quarter of a
	# million GDScript iterations is most of the pause a round used to cause, and at
	# this art scale a block is barely over one world unit across.
	for x in range(from_x, to_x, STEP):
		var sway := (_tear(x, 7) - 0.5) * wander
		var dx := (float(x) - centre.x) / radius
		var dx2 := dx * dx
		if dx2 > 2.11:
			continue
		var low := maxi(from_y, int(top + sway))
		var high := mini(to_y, int(bottom + sway))
		for y in range(low, high, STEP):
			var dy := (float(y) - centre.y) / radius
			if dy < 0.0:
				dy /= maxf(lift, 0.001)
			var t := sqrt(dx2 + dy * dy)
			if t > 1.45:
				continue
			var probe := y * width + x
			if _mask_bytes[probe] == 0:
				continue
			if _window_of[probe] != 0:
				touched[_window_of[probe]] = true
			var torn := t + _tear(x, y) * 0.5 - 0.22
			if torn > 1.0 + RIM / radius:
				continue
			var gone := torn <= 1.0
			var last_x := mini(x + STEP, width)
			var last_y := mini(y + STEP, height)
			for by in range(y, last_y):
				var row := by * width
				for bx in range(x, last_x):
					var index := row + bx
					if gone:
						if _solid_bytes[index * 4 + 3] > 127:
							taken.append(Vector2(bx, by))
							_solid_bytes[index * 4 + 3] = 0
							_standing -= 1
						_mask_bytes[index] = 0
					else:
						_mask_bytes[index] = mini(_mask_bytes[index], 102)
	# Glass and its frame go together. A shell takes a window out; it does not cut
	# one in half and leave the other half hanging in the wall.
	for opening in touched:
		taken.append_array(_blow_window(opening))
	return taken


func _blow_window(opening: int) -> Array:
	if _gone_windows.has(opening) or not _window_pixels.has(opening):
		return []
	_gone_windows[opening] = true
	var taken := []
	for index in _window_pixels[opening]:
		_mask_bytes[index] = 0
		if _solid_bytes[index * 4 + 3] > 127:
			_solid_bytes[index * 4 + 3] = 0
			_standing -= 1
			taken.append(Vector2(index % art.get_width(), index / art.get_width()))
	return taken


# Two scales of cell noise: the coarse one tears the outline into lumps, the fine
# one frays its edge pixel by pixel. Both read the baked table.
func _tear(x: int, y: int) -> float:
	var coarse: int = ((y / 9) % NOISE_SIZE) * NOISE_SIZE + (x / 9) % NOISE_SIZE
	var fine: int = ((y / 3 + 17) % NOISE_SIZE) * NOISE_SIZE + (x / 3 + 29) % NOISE_SIZE
	return _noise[coarse] * 0.65 + _noise[fine] * 0.35


# Masonry the hole cut off from the ground is no longer part of the house.
func _drop_unsupported(shapes: Array) -> Array:
	var standing := []
	var fell := false
	for polygon in shapes:
		var bottom := -INF
		for point in polygon:
			bottom = maxf(bottom, point.y)
		if bottom >= mask.get_height() - GROUND_TOL / pixel:
			standing.append(polygon)
			continue
		_fall(polygon)
		fell = true
		var box := Rect2(polygon[0], Vector2.ZERO)
		for point in polygon:
			box = box.expand(point)
		for point_y in range(maxi(0, int(box.position.y)), mini(mask.get_height(), int(box.end.y) + 1)):
			for point_x in range(maxi(0, int(box.position.x)), mini(mask.get_width(), int(box.end.x) + 1)):
				if Geometry2D.is_point_in_polygon(Vector2(point_x, point_y), polygon):
					var index := point_y * mask.get_width() + point_x
					_mask_bytes[index] = 0
					if _solid_bytes[index * 4 + 3] > 127:
						_solid_bytes[index * 4 + 3] = 0
						_standing -= 1
	if fell:
		_sync_images()
	return standing


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
		_debris(chunk, from, _hurl(from, _to_mask(at), radius / pixel, rng), Color("9d9280"), 1.0)
	var puff := DustPuff.new()
	puff.configure(clampf(float(removed) / 2600.0, 0.5, 1.5), Color("b3a994"), radius / 60.0)
	puff.position = to_local(at)
	add_child(puff)


# One piece of the building, cut from the facade's own pixels so a tile falls
# looking like a tile and plaster falls looking like plaster. Flat colour is what
# made the rubble read as plastic.
# Velocity for a piece leaving the building: away from where the round went off,
# hardest at the centre and falling away with distance, lifted so it arcs rather
# than skidding along the wall. Gravity takes over from there.
func _hurl(origin_px: Vector2, blast_px: Vector2, radius: float, rng: RandomNumberGenerator) -> Vector2:
	var away := origin_px - blast_px
	var distance := away.length()
	if distance < 0.001:
		away = Vector2(rng.randf_range(-1.0, 1.0), -1.0)
		distance = 1.0
	away = away.normalized()
	# Straight up carries nothing sideways, so the lift is added rather than aimed.
	away = (away + Vector2.UP * LOFT).normalized()
	var fade: float = clampf(1.0 - distance / maxf(radius * 1.7, 1.0), 0.15, 1.0)
	return away * THROW * fade * rng.randf_range(0.65, 1.25)


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
	return _standing


func _sync_images() -> void:
	var w := art.get_width()
	var h := art.get_height()
	mask = Image.create_from_data(w, h, false, Image.FORMAT_L8, _mask_bytes)
	_solid = Image.create_from_data(w, h, false, Image.FORMAT_RGBA8, _solid_bytes)
	if mask_texture != null:
		mask_texture.update(mask)


func _silhouette() -> Array:
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(_solid, 0.5)
	return bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, Vector2i(art.get_width(), art.get_height())), 4.0)


func _polygon_area(polygon: PackedVector2Array) -> float:
	var total := 0.0
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		total += a.x * b.y - b.x * a.y
	return absf(total) * 0.5


func _rebuild_collision(shapes: Array) -> void:
	if _collider != null:
		_collider.queue_free()
	_collider = StaticBody2D.new()
	_collider.collision_layer = 1
	_collider.collision_mask = 0
	_collider.position = base_offset
	if owner_structure != null:
		_collider.set_meta("structure_owner", owner_structure)
	for polygon in shapes:
		if polygon.size() < 3 or _polygon_area(polygon) < 12.0:
			continue
		var shape := CollisionPolygon2D.new()
		# Built from the outline's segments rather than decomposed into convex
		# pieces. Tracing a shelled silhouette loosely can leave an outline that
		# crosses itself, which the decomposer reports as an engine error, and in
		# the editor an engine error halts the running game.
		shape.build_mode = CollisionPolygon2D.BUILD_SEGMENTS
		var points := PackedVector2Array()
		for point in polygon:
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
# The room behind the facade: a back wall, a floor and the joists over them.
# It is always there and always hidden; a breach is what reveals it.
#
# Laid up from painted modules, tiled and seeded per house, so no two cottages
# show the same room and nothing had to be drawn twenty times.
func _build_interior() -> void:
	var w := art.get_width()
	var h := art.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(art.get_size()) + str(eaves))
	var wall := _module(WALLS[rng.randi() % WALLS.size()])
	var floor_tile := _module(FLOORS[rng.randi() % FLOORS.size()])
	var joist := _module(JOISTS[rng.randi() % JOISTS.size()])
	if wall == null or floor_tile == null or joist == null:
		_drawn_interior()
		return
	var room := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var floor_y := int(h * 0.80)
	var ceiling := int(h * 0.34)
	_tile(room, joist, Rect2i(0, 0, w, ceiling))
	_tile(room, wall, Rect2i(0, ceiling, w, floor_y - ceiling))
	_tile(room, floor_tile, Rect2i(0, floor_y, w, h - floor_y))
	# Above the ceiling there is no room to see, only roof space and then sky. A
	# breach up there has to open through, or a lost roof stays on screen as a dark
	# shape in the exact outline of the roof it replaced.
	# Above the ceiling there is no room to see, only roof space and then sky. A
	# breach up there has to open clean through: trying to keep the module's own
	# timber hanging there, by brightness, only ever produced speckle and streaks
	# against the sky. The timber that hangs in a gap is the falling debris itself.
	for x in range(w):
		var edge := ceiling - int((_tear(x, 0) - 0.5) * float(h) * 0.12)
		for y in range(mini(edge, h)):
			var pixel := room.get_pixel(x, y)
			room.set_pixel(x, y, Color(pixel.r, pixel.g, pixel.b, 0.0))
	_room_texture = ImageTexture.create_from_image(room)


func _module(name: String) -> Image:
	var path := MODULES % name
	if not ResourceLoader.exists(path):
		return null
	var texture: Texture2D = load(path)
	return texture.get_image() if texture != null else null


func _tile(target: Image, piece: Image, box: Rect2i) -> void:
	var step := piece.get_size()
	# Every other column is mirrored, which breaks up the repeat for nothing. A
	# straight tiling reads as wallpaper the moment two cells are visible at once.
	var flipped := piece.duplicate()
	flipped.flip_x()
	var column := 0
	var y := box.position.y
	while y < box.end.y:
		var x := box.position.x
		column = 0
		while x < box.end.x:
			var take := Rect2i(Vector2i.ZERO, Vector2i(
				mini(step.x, box.end.x - x), mini(step.y, box.end.y - y)))
			target.blit_rect(flipped if column % 2 == 1 else piece, take, Vector2i(x, y))
			x += step.x
			column += 1
		y += step.y


# A loose piece dropped at a point, keeping its own transparency.
func _scatter(target: Image, piece: Image, at: Vector2i) -> void:
	var size := piece.get_size()
	target.blend_rect(piece, Rect2i(Vector2i.ZERO, size), at - size / 2)


# Used only when the painted modules are missing, so the game never shows a house
# with nothing behind its walls.
func _drawn_interior() -> void:
	var w := art.get_width()
	var h := art.get_height()
	var room := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var wall := Color("584736")
	var floor_tone := Color("7a6449")
	var timber := Color("33281d")
	var floor_y := int(h * 0.80)
	var ceiling := int(h * 0.34)
	for y in range(h):
		for x in range(w):
			room.set_pixel(x, y, Color("2e251b") if y < ceiling else wall)
	_fill(room, Rect2i(0, floor_y, w, h - floor_y), floor_tone)
	_fill(room, Rect2i(0, floor_y, w, 3), floor_tone.lightened(0.25))
	_fill(room, Rect2i(0, ceiling - 2, w, 5), timber)
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
