extends Node2D

# The lab's load-bearing geometry, built as active bodies at village scale.
# Art belongs to each body; collapse never swaps the house for a ruined sprite.
const Piece = preload("res://scripts/physics_lab/physical_piece.gd")
const Masonry = preload("res://scripts/destruction/masonry.gd")
const Fracture = preload("res://scripts/destruction/fracture.gd")
const PARTS = preload("res://assets/destruction/cottage_parts.png")
const SCALE := 225.0 / 340.0
const RECTS := {
	"stone": Rect2(59,110,479,481),
	"wood": Rect2(634,299,574,114),
	"left_roof": Rect2(26,666,570,493),
	"right_roof": Rect2(658,667,570,491),
}
var pieces: Array[RigidBody2D] = []
var initial: Dictionary = {}
var building: StaticBody2D
var sheet: Texture2D
var masonry := Masonry.new()
var region_bodies := {}
var beam_baseline := Vector2.ZERO
var _age := 0.0
var _hit_reported := false
var _collapsed := false

func _ready() -> void:
	building = get_parent()
	sheet = PARTS
	building.get_node("Artwork").hide()
	building.get_node("Visual").hide()
	building.get_node("NameLabel").hide()
	building.get_node("CollisionShape2D").disabled = true
	building.collision_layer = 0
	position = Vector2(20,70)
	for side in range(2):
		for row in range(5):
			_box("%sWall%d" % ["Left" if side == 0 else "Right",row],Vector2(-120+240*side,-24-row*48),Vector2(48,48),6,"stone")
	_box("LoadBeam",Vector2(0,-252),Vector2(340,24),5,"wood")
	_polygon("RoofLeft",PackedVector2Array([Vector2(-170,-264),Vector2(0,-398),Vector2(0,-264)]),5,"left_roof")
	_polygon("RoofRight",PackedVector2Array([Vector2(0,-398),Vector2(170,-264),Vector2(0,-264)]),5,"right_roof")
	# A separate door is lighter and shorter than the supporting masonry.
	# It can be knocked over, and never props the roof up before impact.
	_box("Door",Vector2(0,-90),Vector2(110,180),1.5,"wood")
	var texture := AtlasTexture.new()
	texture.atlas = load("res://assets/houses/houses_01.png")
	texture.region = Rect2(337,487,90,153)
	for stone in region("Door"):
		var door_sprite := stone.get_node("Skin") as Sprite2D
		var bounds := Rect2(stone.outline[0],Vector2.ZERO)
		for vertex in stone.outline:
			bounds = bounds.expand(vertex)
		door_sprite.texture = texture
		door_sprite.scale = bounds.size / texture.region.size
	# Adjacent facades represent another depth plane. They must not pin these
	# bodies in place just because their screen-space rectangles overlap.
	for body in pieces:
		for other in get_tree().get_nodes_in_group("structures"):
			if other is PhysicsBody2D:
				body.add_collision_exception_with(other)
	beam_baseline = region_centre("LoadBeam")
	masonry.build(pieces)

func _box(id: String, at: Vector2, size: Vector2, weight: float, material: String) -> RigidBody2D:
	return _polygon(id,PackedVector2Array([at-size/2,at+Vector2(size.x/2,-size.y/2),at+size/2,at+Vector2(-size.x/2,size.y/2)]),weight,material)

# The stones of one region. Collapse is judged from these, so no single piece has
# to survive the intervention for the house to know what happened to it.
func region(id: String) -> Array:
	var result := []
	for body in region_bodies.get(id, []):
		if is_instance_valid(body):
			result.append(body)
	return result

func region_centre(id: String) -> Vector2:
	var bodies: Array = region(id)
	if bodies.is_empty():
		return Vector2.ZERO
	var sum := Vector2.ZERO
	for body in bodies:
		sum += body.position
	return sum / bodies.size()

# Irregular stones wedge into each other and shed load the way masonry does. One
# big block has nowhere to go and jams between its neighbours instead, hanging in
# the air while the solver feeds it gravity it can never resolve.
func _polygon(id: String, vertices: PackedVector2Array, weight: float, material: String) -> RigidBody2D:
	var total := maxf(Fracture.area(vertices), 0.001)
	# Subdivision is off. Laying a region up as several stones made Godot's 2D
	# contact solver diverge: positions reached 1e15 and beyond within seconds of
	# the first hit, whatever sliver guards were in place. The region API below
	# stays, so turning this back on is a one line change once the stability is
	# solved — by irregular faces at the current size, or a sturdier backend.
	var count := 1
	var cells: Array = Fracture.shards(vertices, count, Vector2.INF) if count > 1 else [vertices]
	var group: Array[RigidBody2D] = []
	var first: RigidBody2D = null
	for index in cells.size():
		var cell: PackedVector2Array = cells[index]
		var stone_name: String = id if cells.size() == 1 else "%s#%d" % [id, index]
		var body := _stone(stone_name, cell, weight * Fracture.area(cell) / total, material)
		if body != null:
			group.append(body)
			if first == null:
				first = body
	region_bodies[id] = group
	return first

func _stone(id: String, vertices: PackedVector2Array, weight: float, material: String) -> RigidBody2D:
	var center := Vector2.ZERO
	for vertex in vertices:
		center += vertex*SCALE
	center /= vertices.size()
	var local := PackedVector2Array()
	for vertex in vertices:
		local.append(vertex*SCALE-center)
	# A sliver is poison for the solver: contact resolution on a near degenerate
	# convex shape diverges and bodies fly off to absurd coordinates.
	if Fracture.thickness(local) < 3.0 or Fracture.area(local) < 20.0:
		return null
	var body := RigidBody2D.new()
	body.name = id
	body.set_script(Piece)
	body.position = center
	body.mass = weight*SCALE*SCALE
	body.outline = local
	body.show_debug_art = false
	body.collision_layer = 16
	body.collision_mask = 1 | 8 | 16
	body.set_meta("physical_house",self)
	body.set_meta("structure_owner",building)
	var physics_material := PhysicsMaterial.new()
	physics_material.friction = 0.68 if material == "stone" else 0.55
	physics_material.bounce = 0.02
	body.physics_material_override = physics_material
	var collider := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	shape.points = local
	collider.shape = shape
	body.add_child(collider)
	var bounds := Rect2(local[0],Vector2.ZERO)
	for vertex in local:
		bounds = bounds.expand(vertex)
	var texture := AtlasTexture.new()
	texture.atlas = sheet
	texture.region = RECTS[material]
	texture.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.name = "Skin"
	sprite.texture = texture
	sprite.position = bounds.get_center()
	sprite.scale = bounds.size / texture.region.size
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	body.add_child(sprite)
	add_child(body)
	pieces.append(body)
	initial[body.name] = body.position
	return body

func register_impact(source: Vector2) -> void:
	if _hit_reported:
		return
	_hit_reported = true
	building._integrity = maxi(1,building.max_integrity-1)
	_emit("STRUCTURE_HIT",source,0.35)
	for person in get_tree().get_nodes_in_group("people"):
		person.react_to_blast(source,"Basic")

func _physics_process(delta: float) -> void:
	_age += delta
	if _age < 2.0 or _collapsed:
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
	if region_centre("LoadBeam").y > beam_baseline.y+35 or tilt > 0.35:
		_collapsed = true
		building._integrity = 0
		_emit("STRUCTURE_DESTROYED",to_global(region_centre("LoadBeam")),0.8)

func _emit(type: String, at: Vector2, severity: float) -> void:
	EventBus.world_event.emit({"type":type,"target":str(building.name),"cause":"knight","position":at,"severity":severity,"narrative_value":0.7})

func damage_near(_amount: int, source: Vector2, strength: float, radius := 155.0, heading := Vector2.ZERO, cascade := true) -> void:
	# The blast spends its energy at the point of impact. Pieces far from it are
	# untouched, and the collapse that follows comes from the lost support.
	register_impact(source)
	masonry.blast(source, radius, strength, heading, cascade)

func closest_point(point: Vector2) -> Vector2:
	var result := global_position
	var best := INF
	for body in pieces:
		if not is_instance_valid(body):
			continue
		var local: Vector2 = body.to_local(point)
		var polygon: PackedVector2Array = body.outline
		if Geometry2D.is_point_in_polygon(local,polygon):
			return point
		for i in polygon.size():
			var candidate := body.to_global(Geometry2D.get_closest_point_to_segment(local,polygon[i],polygon[(i+1)%polygon.size()]))
			if point.distance_squared_to(candidate) < best:
				best = point.distance_squared_to(candidate)
				result = candidate
	return result
