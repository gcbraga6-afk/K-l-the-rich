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

var building: StaticBody2D
var facade: Node2D
var _whole := 1.0
var _hit_reported := false
var _collapsed := false


func _ready() -> void:
	building = get_parent()
	var art = building.get_node("Artwork")
	art.hide()
	building.get_node("Visual").hide()
	building.get_node("NameLabel").hide()
	building.get_node("CollisionShape2D").disabled = true
	building.collision_layer = 0
	facade = Node2D.new()
	facade.name = "Facade"
	facade.set_script(Carved)
	add_child(facade)
	facade.setup(art.house_texture, art.house_width, art.ground_y - building.position.y, building, _map_for(art))
	_whole = maxf(facade.standing_ratio(), 0.001)


# Each cottage may carry a painted map of what its parts are made of. Without one
# it is all masonry, which is what every house looked like before any were mapped.
func _map_for(art) -> Texture2D:
	var name := str(building.name).to_lower()
	var path: String = MATERIALS % name
	if ResourceLoader.exists(path):
		return load(path)
	return null


func damage_near(_amount: int, source: Vector2, strength: float, _radius := 155.0, _heading := Vector2.ZERO, _cascade := true) -> void:
	var art = building.get_node("Artwork")
	facade.carve(source, art.house_width * BITE * clampf(strength, 0.45, 1.0))
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
