extends "res://scripts/destruction/modular_structure.gd"

# Only this tower is converted for now. The remaining keep is a static masonry
# support and collision surface. Every tower course stands frozen until a blast
# reaches it or the course below it is gone.
const Piece = preload("res://scripts/physics_lab/physical_piece.gd")
const Masonry = preload("res://scripts/destruction/masonry.gd")

var tower_bodies: Array[RigidBody2D] = []
var initial_poses: Dictionary = {}
var masonry := Masonry.new()
var _age := 0.0
var _tower_fallen := false
var _impact_reported := false

func _ready() -> void:
	super._ready()
	masonry.build(tower_bodies)

func _build_castle() -> void:
	super._build_castle()
	var originals := parts.duplicate()
	parts.clear()
	parts.append(originals[0])
	for source in [originals[1],originals[2]]:
		var from_y: float = 272 if source.id=="TowerShaft" else 455
		var height: float = 183 if source.id=="TowerShaft" else 135
		for row in range(3):
			var cut := _rect_polygon(Rect2(260,from_y+height*row/3,200,height/3))
			for polygon in Geometry2D.intersect_polygons(source.polygon,cut):
				_add_part(source.id+str(row),source.title,polygon,1,[],0)
	for i in range(3,originals.size()):
		parts.append(originals[i])

func _create_visual_and_collision(part: Dictionary) -> void:
	if part.id.begins_with("Keep"):
		super._create_visual_and_collision(part)
		return
	var center := Vector2.ZERO
	for p in part.polygon:
		center += p
	center /= part.polygon.size()
	var body := RigidBody2D.new()
	body.name = part.id
	body.set_script(Piece)
	body.show_debug_art = false
	body.position = origin+center*factor
	body.mass = 10.0 if part.id=="TowerCrown" else 5.0
	body.collision_layer = 16
	body.collision_mask = 1|8|16
	body.set_meta("physical_house",self)
	body.set_meta("structure_owner",building)
	var material := PhysicsMaterial.new()
	material.friction = 0.8
	material.bounce = 0.0
	body.physics_material_override = material
	var visual := _texture_polygon(part.polygon,center)
	body.add_child(visual)
	part.visual = visual
	var collisions: Array[CollisionPolygon2D] = []
	var hit_polygons: Array[PackedVector2Array] = []
	for outline in silhouette:
		for cut in Geometry2D.intersect_polygons(part.polygon,outline):
			hit_polygons.append(cut)
			var collision := CollisionPolygon2D.new()
			var points := PackedVector2Array()
			for p in cut:
				points.append((p-center)*factor)
			collision.polygon = points
			body.add_child(collision)
			collisions.append(collision)
	pieces_root.add_child(body)
	part.body = body
	part.collisions = collisions
	part.hit_polygons = hit_polygons
	tower_bodies.append(body)
	initial_poses[body.name] = body.position

func register_impact(at: Vector2) -> void:
	if _impact_reported:
		return
	_impact_reported = true
	EventBus.world_event.emit({"type":"STRUCTURE_HIT","target":str(building.name),"part":"torre","cause":"knight","position":at,"severity":0.4,"narrative_value":0.7})

func damage_near(_amount: int, at: Vector2, strength: float, radius := 155.0, heading := Vector2.ZERO, cascade := true) -> void:
	register_impact(at)
	masonry.blast(at, radius, strength, heading, cascade)

func _physics_process(delta: float) -> void:
	_age += delta
	if _age<3 or _tower_fallen or tower_bodies.is_empty():
		return
	var crown := tower_bodies[0]
	if crown.position.distance_to(initial_poses[crown.name])>45 or absf(crown.rotation)>0.25:
		_tower_fallen = true
		# A lost tower damages the castle but does not destroy the whole keep.
		building._integrity = maxi(1,building.max_integrity-8)
		EventBus.world_event.emit({"type":"STRUCTURE_HIT","target":str(building.name),"part":"torre desabou","cause":"knight","position":crown.global_position,"severity":0.8,"narrative_value":0.9})

func closest_point(point: Vector2) -> Vector2:
	var best := Vector2(INF,INF)
	var distance := INF
	for part in parts:
		var body: Node2D = part.body
		for collision in part.collisions:
			var polygon: PackedVector2Array = collision.polygon
			var local := body.to_local(point)
			if Geometry2D.is_point_in_polygon(local,polygon):
				return point
			for i in polygon.size():
				var candidate := body.to_global(Geometry2D.get_closest_point_to_segment(local,polygon[i],polygon[(i+1)%polygon.size()]))
				if point.distance_squared_to(candidate)<distance:
					distance = point.distance_squared_to(candidate)
					best = candidate
	return best

func _draw() -> void:
	pass
