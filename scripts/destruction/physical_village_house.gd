extends "res://scripts/destruction/physical_house.gd"

# Preserve each existing cottage's painted facade. The image regions are skins
# on bodies present from frame one, not fragments spawned after an HP threshold.
var facade: Texture2D
var facade_size: Vector2
var factor := 1.0
var origin := Vector2.ZERO
var roof_baseline := Vector2.ZERO

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
	roof_baseline = get_node("LoadBeam").position
	for body in pieces:
		for other in get_tree().get_nodes_in_group("structures"):
			if other is PhysicsBody2D:
				body.add_collision_exception_with(other)

func _region(id: String, region: Rect2, weight: float) -> void:
	var source := PackedVector2Array([region.position,Vector2(region.end.x,region.position.y),region.end,Vector2(region.position.x,region.end.y)])
	var center := region.get_center()
	var polygon := PackedVector2Array()
	var uv := PackedVector2Array()
	for point in source:
		polygon.append((point-center)*factor)
		uv.append(point+(facade.region.position if facade is AtlasTexture else Vector2.ZERO))
	var body := RigidBody2D.new()
	body.name = id
	body.set_script(Piece)
	body.position = origin+center*factor
	body.mass = weight
	body.outline = polygon
	body.show_debug_art = false
	body.collision_layer = 16
	body.collision_mask = 1|8|16
	body.set_meta("physical_house",self)
	body.set_meta("structure_owner",building)
	var material := PhysicsMaterial.new()
	material.friction = 0.65
	material.bounce = 0.0
	body.physics_material_override = material
	var collision := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	# Simple pitched rafters give each roof half a continuous load-bearing base.
	# Decorative chimneys stay in the art; they cannot create hidden contact islands.
	if id == "RoofLeft":
		shape.points = PackedVector2Array([polygon[3],polygon[1],polygon[2]])
	elif id == "RoofRight":
		shape.points = PackedVector2Array([polygon[0],polygon[2],polygon[3]])
	else:
		shape.points = polygon
	# Eaves may overlap visually in the dense village. Keep the collision
	# inside the masonry footprint so neighbouring roofs do not start interpenetrating.
	var points := shape.points
	for i in points.size():
		points[i].x = clampf(points[i].x,(7.0/factor-center.x)*factor,(facade_size.x-7.0/factor-center.x)*factor)
	var hull := Geometry2D.convex_hull(points)
	hull.remove_at(hull.size()-1)
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

func _physics_process(delta: float) -> void:
	_age += delta
	if _age < 2 or _collapsed:
		return
	var beam := get_node("LoadBeam") as RigidBody2D
	if beam.position.distance_to(roof_baseline)>35 or absf(beam.rotation)>0.35:
		_collapsed = true
		building._integrity = 0
		_emit("STRUCTURE_DESTROYED",beam.global_position,0.8)
