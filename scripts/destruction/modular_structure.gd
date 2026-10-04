extends Node2D

const Debris = preload("res://scripts/destruction/structural_debris.gd")
var kind := "house"
var building: StaticBody2D
var texture: Texture2D
var tex_size := Vector2.ZERO
var factor := 1.0
var origin := Vector2.ZERO
var parts: Array[Dictionary] = []
var pieces_root: Node2D
var holes: Array[Vector2] = []
var serial := 0
var silhouette: Array[PackedVector2Array] = []

func _ready() -> void:
	building = get_parent()
	var art = building.get_node("Artwork")
	texture = art.house_texture
	tex_size = texture.get_size()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(texture.get_image(), 0.3)
	silhouette = bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO,Vector2i(tex_size)),3.0)
	factor = art.house_width / tex_size.x
	origin = Vector2(-art.house_width / 2, art.ground_y-building.position.y-tex_size.y*factor)
	pieces_root = Node2D.new()
	pieces_root.name = "Pieces"
	add_child(pieces_root)
	art.hide()
	building.get_node("CollisionShape2D").disabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if kind == "castle":
		_build_castle()
	else:
		_build_house()
	for part in parts:
		_create_visual_and_collision(part)
	building.max_integrity = _remaining_integrity()
	building._integrity = building.max_integrity

func _build_house() -> void:
	# Straw-roof house, in normalized coordinates of its existing atlas region.
	var roof := _normalized([Vector2(0,0),Vector2(1,0),Vector2(1,0.69),Vector2(0.82,0.61),Vector2(0.75,0.69),Vector2(0.45,0.55),Vector2(0.15,0.65),Vector2(0,0.72)])
	var left := _normalized([Vector2(0,0.72),Vector2(0.15,0.65),Vector2(0.45,0.55),Vector2(0.52,0.59),Vector2(0.52,0.94),Vector2(0,0.94)])
	var right := _normalized([Vector2(0.52,0.59),Vector2(0.75,0.69),Vector2(0.82,0.61),Vector2(1,0.69),Vector2(1,0.94),Vector2(0.52,0.94)])
	_add_part("Roof", "telhado", roof, 2, ["LeftWall", "RightWall"], 2)
	_add_part("LeftWall", "parede esquerda", left, 2, [], 0)
	_add_part("RightWall", "parede direita", right, 2, [], 0)
	_add_part("Foundation", "fundação", _rect_polygon(Rect2(0,tex_size.y*0.94,tex_size.x,tex_size.y*0.06)), 3, [], 0)

func _build_castle() -> void:
	# Tall left tower, split at actual roof/balcony/masonry transitions.
	var upper := PackedVector2Array([Vector2(263,0),Vector2(496,0),Vector2(496,125),Vector2(441,210),Vector2(435,272),Vector2(277,272),Vector2(263,205)])
	var shaft := PackedVector2Array([Vector2(277,272),Vector2(435,272),Vector2(431,455),Vector2(282,455)])
	var support := PackedVector2Array([Vector2(282,455),Vector2(431,455),Vector2(429,590),Vector2(284,590)])
	_add_part("TowerCrown", "cobertura da torre", upper, 2, ["TowerShaft"], 1)
	_add_part("TowerShaft", "corpo da torre", shaft, 3, ["TowerSupport"], 1)
	_add_part("TowerSupport", "base da torre", support, 3, [], 0)
	var remainder: Array[PackedVector2Array] = [_rect_polygon(Rect2(Vector2.ZERO,tex_size))]
	for cut in [upper,shaft,support]:
		var next: Array[PackedVector2Array] = []
		for polygon in remainder:
			for result in Geometry2D.clip_polygons(polygon, cut):
				if not Geometry2D.is_polygon_clockwise(result):
					next.append(result)
			remainder = next
	for i in remainder.size():
		_add_part("Keep%d" % i, "muralha do castelo", remainder[i], 16, [], 0)

func _normalized(points: Array) -> PackedVector2Array:
	var polygon := PackedVector2Array()
	for point in points:
		polygon.append(point * tex_size)
	return polygon

func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])

func _add_part(id: String, title: String, polygon: PackedVector2Array, health: int, supports: Array, required: int) -> void:
	parts.append({"id":id,"title":title,"polygon":polygon,"hp":health,"max_hp":health,"supports":supports,"required":required,"fallen":false})

func _texture_polygon(polygon: PackedVector2Array, pivot: Vector2 = Vector2.ZERO) -> Polygon2D:
	var node := Polygon2D.new()
	var points := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in polygon:
		points.append((point-pivot)*factor)
		uv.append(point + (texture.region.position if texture is AtlasTexture else Vector2.ZERO))
	node.polygon = points
	node.uv = uv
	node.texture = texture.atlas if texture is AtlasTexture else texture
	return node

func _create_visual_and_collision(part: Dictionary) -> void:
	var visual := _texture_polygon(part.polygon)
	visual.position = origin
	pieces_root.add_child(visual)
	part.visual = visual
	var body := StaticBody2D.new()
	body.name = part.id
	body.set_meta("structure_owner", building)
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = origin
	pieces_root.add_child(body)
	var collisions: Array[CollisionPolygon2D] = []
	var hit_polygons: Array[PackedVector2Array] = []
	for outline in silhouette:
		for cut in Geometry2D.intersect_polygons(part.polygon,outline):
			hit_polygons.append(cut)
			var collision := CollisionPolygon2D.new()
			var polygon := PackedVector2Array()
			for point in cut:
				polygon.append(point*factor)
			collision.polygon = polygon
			body.add_child(collision)
			collisions.append(collision)
	part.body = body
	part.collisions = collisions
	part.hit_polygons = hit_polygons

func closest_point(point: Vector2) -> Vector2:
	var best := Vector2(INF,INF)
	var distance := INF
	var local := (to_local(point)-origin)/factor
	for part in parts:
		if part.fallen:
			continue
		for polygon in part.hit_polygons:
			if Geometry2D.is_point_in_polygon(local, polygon):
				return point
			for i in polygon.size():
				var candidate := Geometry2D.get_closest_point_to_segment(local,polygon[i],polygon[(i+1)%polygon.size()])
				var world := to_global(origin+candidate*factor)
				if world.distance_squared_to(point) < distance:
					distance = world.distance_squared_to(point)
					best = world
	return best

func damage_near(amount: int, source: Vector2, force_ratio: float, _radius := 155.0, _heading := Vector2.ZERO, _cascade := true) -> void:
	var selected := -1
	var distance := INF
	var local := (to_local(source)-origin)/factor
	for i in parts.size():
		var part := parts[i]
		if part.fallen:
			continue
		var d := INF
		for polygon in part.hit_polygons:
			if Geometry2D.is_point_in_polygon(local,polygon):
				d = 0.0
			for j in polygon.size():
				d = minf(d, local.distance_to(Geometry2D.get_closest_point_to_segment(local,polygon[j],polygon[(j+1)%polygon.size()])))
		if d < distance:
			distance = d
			selected = i
	if selected < 0:
		return
	var hit := parts[selected]
	hit.hp = maxi(0,hit.hp-amount)
	hit.visual.modulate = Color.WHITE.lerp(Color("b29d87"), (1.0-float(hit.hp)/hit.max_hp)*0.3)
	holes.append(to_local(source))
	if hit.hp <= 0:
		holes.clear()
		_detach(hit, source, force_ratio)
		_check_supports(source,force_ratio)
	building._integrity = _remaining_integrity()
	EventBus.world_event.emit({"type":"STRUCTURE_DESTROYED" if building._integrity == 0 else "STRUCTURE_HIT","target":str(building.name),"part":hit.title,"cause":"knight","position":source,"severity":minf(1,float(amount)/hit.max_hp),"narrative_value":0.7})
	queue_redraw()

func _check_supports(source: Vector2, force_ratio: float) -> void:
	var changed := true
	while changed:
		changed = false
		for part in parts:
			if part.fallen or part.required == 0:
				continue
			var alive := 0
			for support_id in part.supports:
				for support in parts:
					if support.id == support_id and not support.fallen:
						alive += 1
			if alive < part.required:
				_detach(part,source,force_ratio)
				changed = true

func _remaining_integrity() -> int:
	var result := 0
	for part in parts:
		if not part.fallen:
			result += part.hp
	return result

func _detach(part: Dictionary, source: Vector2, force_ratio: float) -> void:
	part.fallen = true
	part.hp = 0
	part.visual.hide()
	for collision in part.collisions:
		collision.set_deferred("disabled",true)
	_spawn_debris.call_deferred(part.polygon, source, force_ratio)

func _spawn_debris(polygon: PackedVector2Array, source: Vector2, force_ratio: float, transform_override: Transform2D = Transform2D.IDENTITY, fragment: bool = false) -> void:
	var pivot := Vector2.ZERO
	for point in polygon:
		pivot += point
	pivot /= polygon.size()
	var body := RigidBody2D.new()
	body.set_script(Debris)
	body.name = "Fallen_%s_%d" % [building.name, serial]
	serial += 1
	body.controller = self
	body.source_polygon = polygon
	body.can_fracture = not fragment
	body.mass = 8.0 if kind == "castle" else 3.0
	body.add_child(_texture_polygon(polygon,pivot))
	var shape := CollisionShape2D.new()
	var points := PackedVector2Array()
	for point in polygon:
		points.append((point-pivot)*factor*0.94)
	var convex := ConvexPolygonShape2D.new()
	var hull := Geometry2D.convex_hull(points)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size()-1]):
		hull.remove_at(hull.size()-1)
	convex.points = hull
	shape.shape = convex
	body.add_child(shape)
	body.position = to_global(origin+pivot*factor)
	if transform_override != Transform2D.IDENTITY:
		body.transform = transform_override
	get_tree().root.add_child(body)
	tree_exiting.connect(body.queue_free)
	for part in parts:
		body.add_collision_exception_with(part.body)
	body.z_index = 5
	var direction := signf(body.global_position.x-source.x)
	if kind == "house" and not fragment:
		direction = -direction
	if direction == 0:
		direction = 1
	body.linear_velocity = Vector2(direction*(45+force_ratio*70), -35*force_ratio)
	body.angular_velocity = direction * (0.35 if kind == "castle" else 0.8)

func fracture_debris(body: RigidBody2D) -> void:
	if not is_instance_valid(body):
		return
	var polygon: PackedVector2Array = body.source_polygon
	var pivot := Vector2.ZERO
	var bounds := Rect2(polygon[0],Vector2.ZERO)
	for point in polygon:
		pivot += point
		bounds = bounds.expand(point)
	pivot /= polygon.size()
	var step := 90.0 / factor if kind == "castle" else 42.0 / factor
	var spawned := 0
	for y in range(int(floor(bounds.position.y/step)),int(ceil(bounds.end.y/step))):
		for x in range(int(floor(bounds.position.x/step)),int(ceil(bounds.end.x/step))):
			var clipped := Geometry2D.intersect_polygons(polygon,_rect_polygon(Rect2(x*step,y*step,step,step)))
			for piece in clipped:
				if piece.size() < 3 or spawned >= 24:
					continue
				var center := Vector2.ZERO
				for point in piece:
					center += point
				center /= piece.size()
				var pose := Transform2D(body.global_rotation,body.to_global((center-pivot)*factor))
				_spawn_debris(piece, body.global_position, 0.25, pose, true)
				spawned += 1
	body.queue_free()

func _draw() -> void:
	# Exposed timber remains on the surviving walls after the roof is lost.
	if kind == "house" and not parts.is_empty() and parts[0].fallen:
		var left := origin + Vector2(tex_size.x*0.16,tex_size.y*0.65)*factor
		var right := origin + Vector2(tex_size.x*0.77,tex_size.y*0.65)*factor
		draw_line(left,right,Color("503a26"),7)
		for i in range(5):
			var foot := left.lerp(right,float(i)/4)
			draw_line(foot,foot+Vector2(-9,-18-i%2*6),Color("96734c"),4)
	if kind == "castle" and parts.size() >= 3 and parts[1].fallen:
		var cap := origin + Vector2(285,590 if parts[2].fallen else 455)*factor
		for i in range(8):
			draw_rect(Rect2(cap+Vector2(i*17*factor,-5-i%3*3),Vector2(18*factor,12)),Color("a49a81"))
	# Fracture marks follow the damaged material; missing parts stay missing.
	for hit in holes:
		draw_polyline(PackedVector2Array([hit+Vector2(-9,-13),hit,hit+Vector2(-5,9),hit+Vector2(8,19)]),Color("453a31"),2)
