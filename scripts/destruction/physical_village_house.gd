extends "res://scripts/destruction/physical_house.gd"

# Preserve each existing cottage's painted facade. The image regions are skins
# on bodies present from frame one, not fragments spawned after an HP threshold.
#
# Each region is laid up as several irregular stones rather than one rectangle.
# Irregular stones wedge into each other and shed load the way masonry does; a
# single big block has nowhere to go and jams between its neighbours instead,
# hanging in the air while the solver feeds it gravity it can never resolve.
var facade: Texture2D
var facade_size: Vector2
var factor := 1.0
var origin := Vector2.ZERO

func _ready() -> void:
	building = get_parent()
	var art = building.get_node("Artwork")
	facade = art.house_texture
	facade_size = facade.get_size()
	factor = art.house_width/facade_size.x
	origin = Vector2(-art.house_width/2,art.ground_y-building.position.y-facade_size.y*factor)
	art.hide()
	building.get_node("Visual").hide()
	building.get_node("NameLabel").hide()
	building.get_node("CollisionShape2D").disabled = true
	building.collision_layer = 0
	var w := facade_size.x
	var h := facade_size.y
	for side in range(2):
		for row in range(5):
			_region("%sWall%d" % ["Left" if side == 0 else "Right",row],Rect2(w*0.68*side,h*(0.9-row*0.1),w*0.32,h*0.1),2.6)
	_region("Door",Rect2(w*0.32,h*0.5,w*0.36,h*0.5),3.0)
	_region("LoadBeam",Rect2(0,h*0.45,w,h*0.05),2.2)
	_region("RoofLeft",Rect2(0,0,w*0.5,h*0.45),2.4)
	_region("RoofRight",Rect2(w*0.5,0,w*0.5,h*0.45),2.4)
	beam_baseline = region_centre("LoadBeam")
	for body in pieces:
		for other in get_tree().get_nodes_in_group("structures"):
			if other is PhysicsBody2D:
				body.add_collision_exception_with(other)
	masonry.build(pieces)

func _region(id: String, rect: Rect2, weight: float) -> void:
	var base := _base_polygon(id, rect)
	var total := maxf(Fracture.area(base), 0.001)
	var count := _stone_count(total)
	var cells: Array = Fracture.shards(base, count, Vector2.INF) if count > 1 else [base]
	var group: Array[RigidBody2D] = []
	for index in cells.size():
		var cell: PackedVector2Array = cells[index]
		var stone_name: String = id if cells.size() == 1 else "%s#%d" % [id, index]
		var body := _facade_stone(stone_name, cell, weight * Fracture.area(cell) / total)
		if body != null:
			group.append(body)
	region_bodies[id] = group

func _stone_count(area: float) -> int:
	# Subdivision is off. Laying a region up as several stones made Godot's 2D
	# contact solver diverge: positions reached 1e15 and beyond within seconds of
	# the first hit, whatever sliver guards were in place. The region API below
	# stays, so turning this back on is a one line change once the stability is
	# solved — by irregular faces at the current size, or a sturdier backend.
	return 1

func _base_polygon(id: String, rect: Rect2) -> PackedVector2Array:
	var corners := PackedVector2Array([rect.position,Vector2(rect.end.x,rect.position.y),rect.end,Vector2(rect.position.x,rect.end.y)])
	# Simple pitched rafters give each roof half a continuous load-bearing base.
	# Decorative chimneys stay in the art; they cannot create hidden contact islands.
	if id == "RoofLeft":
		return PackedVector2Array([corners[3],corners[1],corners[2]])
	if id == "RoofRight":
		return PackedVector2Array([corners[0],corners[2],corners[3]])
	return corners

func _facade_stone(name: String, cell: PackedVector2Array, weight: float) -> RigidBody2D:
	# Eaves may overlap visually in the dense village. Keep the stone inside the
	# masonry footprint so neighbouring roofs do not start interpenetrating.
	var clipped := PackedVector2Array()
	for point in cell:
		clipped.append(Vector2(clampf(point.x, 7.0, facade_size.x - 7.0), point.y))
	var centre: Vector2 = Fracture.centroid(clipped)
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	var atlas_offset: Vector2 = facade.region.position if facade is AtlasTexture else Vector2.ZERO
	for point in clipped:
		polygon.append((point - centre) * factor)
		uv.append(point + atlas_offset)
	var hull := Geometry2D.convex_hull(polygon)
	if hull.size() > 1 and hull[0].is_equal_approx(hull[hull.size() - 1]):
		hull.remove_at(hull.size() - 1)
	if hull.size() < 3 or Fracture.thickness(hull) < 3.0 or Fracture.area(hull) < 20.0:
		return null
	var body := RigidBody2D.new()
	body.name = name
	body.set_script(Piece)
	body.position = origin + centre * factor
	body.mass = maxf(weight, 0.2)
	body.outline = polygon
	body.show_debug_art = false
	body.collision_layer = 16
	body.collision_mask = 1|8|16
	body.set_meta("physical_house",self)
	body.set_meta("structure_owner",building)
	var material := PhysicsMaterial.new()
	material.friction = 0.9
	material.bounce = 0.0
	body.physics_material_override = material
	var collision := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	shape.points = hull
	collision.shape = shape
	body.add_child(collision)
	var skin := Polygon2D.new()
	skin.name = "Skin"
	skin.polygon = polygon
	skin.uv = uv
	skin.texture = facade.atlas if facade is AtlasTexture else facade
	skin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(skin)
	add_child(body)
	pieces.append(body)
	initial[body.name] = body.position
	return body

func _physics_process(delta: float) -> void:
	_age += delta
	if _age < 2 or _collapsed:
		return
	var beam: Array = region("LoadBeam")
	if beam.is_empty():
		# The beam itself broke up: the roof has nothing left to rest on.
		_collapsed = true
		building._integrity = 0
		_emit("STRUCTURE_DESTROYED",global_position,0.8)
		return
	var tilt := 0.0
	for body in beam:
		tilt = maxf(tilt, absf(body.rotation))
	if region_centre("LoadBeam").distance_to(beam_baseline) > 35 or tilt > 0.35:
		_collapsed = true
		building._integrity = 0
		_emit("STRUCTURE_DESTROYED",to_global(region_centre("LoadBeam")),0.8)
