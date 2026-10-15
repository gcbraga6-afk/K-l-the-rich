extends Node2D

# A village cottage, shelled the way the reference photographs behave: the round
# tears a hole and the house goes on standing. Sits where the block model used to,
# under the name the rest of the game looks for, and answers the same two calls.
#
# The blocks it replaces could only ever fall over, which is why a shelled cottage
# read as a sheet of paper tipping into the street.

const Carved = preload("res://scripts/destruction/carved_facade.gd")
const MATERIALS := "res://assets/houses/materials/%s.png"

# A round's damage radius is tuned for the old model's reach. What it should carve
# out of a wall is a share of that wall, so it is taken from the house instead.
const BITE := 0.15
const RUINED := 0.6   # standing share below which the cottage counts as lost

# Multiplies the bite for buildings that are not cottages. A keep took the same
# hole per round as a thatched house, which put the castle down in six — and the
# castle is what the whole intervention is aimed at. Walls that thick should ask
# for a bombardment, not a visit.
var toughness := 1.0

var building: StaticBody2D
var facade: Node2D
var _whole := 1.0
var _hit_reported := false
var _collapsed := false


# Set before this enters the tree when the building has its interior drawn rather
# than assembled: the castle does, every floor of it.
var interior: Texture2D = null

func _ready() -> void:
	building = get_parent()
	var art = building.get_node("Artwork")
	art.hide()
	# Shops and factories are built slightly differently from cottages, so nothing
	# here may insist on a node being present.
	for spare in ["Visual", "NameLabel"]:
		var node = building.get_node_or_null(spare)
		if node != null:
			node.hide()
	var collider = building.get_node_or_null("CollisionShape2D")
	if collider != null:
		collider.disabled = true
	building.collision_layer = 0
	facade = Node2D.new()
	facade.name = "Facade"
	facade.set_script(Carved)
	add_child(facade)
	facade.setup(art.house_texture, art.house_width, art.ground_y - building.position.y, building, _map_for(art), interior)
	_whole = maxf(facade.standing_ratio(), 0.001)


# Each cottage may carry a painted map of what its parts are made of. Without one
# it is all masonry, which is what every house looked like before any were mapped.
#
# A village house is drawn from the catalog, and twenty of them share five sheets,
# so the map belongs to the drawing rather than to the house standing in the
# street: `house_02.png` is `house_catalog.house(2)`, the convention the painted
# maps are filed under. Looking the map up by the node's own name instead meant
# asking for `villagehouse03.png`, which no one had painted and no one ever will,
# so every house in the Kingdom carved as plain masonry. Shops and noble houses
# carry their own artwork and are still found by name.
func _map_for(art) -> Texture2D:
	var names: Array[String] = []
	if building.has_meta("model"):
		names.append("house_%02d" % int(building.get_meta("model")))
	names.append(str(building.name).to_lower())
	for name in names:
		var path: String = MATERIALS % name
		if ResourceLoader.exists(path):
			return load(path)
	return null


func damage_near(_amount: int, source: Vector2, strength: float, _radius := 155.0, _heading := Vector2.ZERO, cascade := true) -> void:
	# Flying rubble hurts a building without blowing a hole in it. Only a round
	# going off carves masonry away; debris striking a wall marks it and no more,
	# or every collapse sets off a chain of further collapses around it.
	if not cascade:
		_hit(source)
		return
	var art = building.get_node("Artwork")
	facade.carve(source, art.house_width * BITE * clampf(strength, 0.45, 1.0) / toughness)
	# The hit registers at once, because the game reads damage the moment a round
	# lands. The carve itself has to wait for the physics server, so what is left
	# standing can only be measured afterwards.
	_hit(source)
	_settle.call_deferred()


func closest_point(point: Vector2) -> Vector2:
	return facade.closest_point(point)


func standing_ratio() -> float:
	return facade.standing_ratio() / _whole


func _hit(source: Vector2) -> void:
	for person in get_tree().get_nodes_in_group("people"):
		person.react_to_blast(source, "Basic")
	if _collapsed:
		return
	_hit_reported = true
	building._integrity = maxi(1, building._integrity - 1)
	_emit("STRUCTURE_HIT", source, 0.35)


func _settle() -> void:
	if _collapsed:
		return
	var left := standing_ratio()
	if left <= RUINED:
		_collapsed = true
		building._integrity = 0
		_emit("STRUCTURE_DESTROYED", global_position, 0.8)
		return
	# Integrity tracks how much of the cottage is actually still standing, rather
	# than counting rounds: two shells into the same hole are not two houses lost.
	building._integrity = clampi(int(floor(float(building.max_integrity) * left)), 1, building._integrity)


func _emit(type: String, at: Vector2, severity: float) -> void:
	EventBus.world_event.emit({
		"type": type, "target": str(building.name), "cause": "knight",
		"position": at, "severity": severity, "narrative_value": 0.7,
	})
