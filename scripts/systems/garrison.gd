extends Node

# What the Kingdom's soldiers do about the Knight. Until now they patrolled and
# flinched; nothing the player did ever came back at him, so the only thing that
# could end an intervention was running out of powder.
#
# Three things happen here, in order of how much the Kingdom has had:
#
#   noticing   - a round goes off within earshot and the nearest soldiers stop,
#                turn and shout. This is the rhythm of the game: the player looks
#                up because somebody on the street is pointing at what he did.
#   looking    - once the shouting stops they walk to where it happened, stand
#                about, and drift back to their beat.
#   advancing  - past a certain amount of damage the garrison stops investigating
#                and walks at the Knight. Reaching him ends the intervention.
#
# Cohesion decides whether the march happens at all. A garrison that has been
# flashed, watched the King feast and seen its own desert does not form up: the
# Knight keeps firing because nobody is left willing to walk at him. That is the
# whole mechanical weight of Cohesion, and of the Flash.

const EARSHOT := 1000.0
const MARCH_AT := 6.0        # provocation that puts the garrison on the road
const COHESION_FLOOR := 32.0 # below this nobody forms up
const REACH := 150.0         # how close to the Knight counts as expelled
const PROVOCATION_DECAY := 0.07

var society: Node
var knight: Node2D
var provocation := 0.0
var marching := false
var expelled := false

func _ready() -> void:
	EventBus.world_event.connect(_on_world_event)
	EventBus.intervention_ended.connect(func(_reason): set_process(false))


func _process(delta: float) -> void:
	provocation = maxf(0.0, provocation - delta * PROVOCATION_DECAY)
	if society == null:
		society = get_parent().get_node_or_null("Society")
	if knight == null:
		knight = get_parent().get_node_or_null("Knight")
	if knight == null:
		return

	if marching and not expelled:
		for soldier in _garrison():
			if soldier.disorganized_seconds > 0.0:
				continue
			# Re-aimed every frame: the Knight does not move, but a soldier knocked
			# about by a blast loses his order and has to be given it again.
			soldier.march_target = knight.global_position.x + REACH * 0.6
			if soldier.global_position.distance_to(knight.global_position) <= REACH:
				_expel()
				return
	# A garrison that falls apart on the way stops being a garrison.
	if marching and _formed_up() == 0:
		marching = false


func _garrison() -> Array:
	var result: Array = []
	for person in get_tree().get_nodes_in_group("people"):
		if person.label == "Soldier" and not person.deserted:
			result.append(person)
	return result


func _formed_up() -> int:
	var count := 0
	for soldier in _garrison():
		if soldier.disorganized_seconds <= 0.0:
			count += 1
	return count


func _on_world_event(event: Dictionary) -> void:
	var kind: String = event.get("type", "")
	if kind not in ["STRUCTURE_HIT", "STRUCTURE_DESTROYED", "PERSON_HIT",
			"POWDER_STORE_BLOWN", "AMMO_SEIZED"]:
		return
	var at: Vector2 = event.get("position", Vector2.ZERO)
	var severity: float = clampf(event.get("severity", 0.5), 0.1, 1.0)
	# Powder taken off the Kingdom counts double. A cart broken open in the street
	# is the Knight helping himself in front of the people who were guarding it.
	provocation += severity * (2.0 if kind in ["AMMO_SEIZED", "POWDER_STORE_BLOWN"] else 1.0)

	for soldier in _garrison():
		if soldier.global_position.distance_to(at) > EARSHOT:
			continue
		if soldier.disorganized_seconds > 0.0:
			continue
		soldier.alert_at = at
		soldier.alert_seconds = maxf(soldier.alert_seconds, 1.6 + severity * 1.2)
		# A soldier does not run from a blast the way a villager does; he looks at it.
		soldier.fear_seconds = 0.0
		if not marching:
			soldier.march_target = at.x

	if marching or provocation < MARCH_AT:
		return
	if society != null and society.cohesion < COHESION_FLOOR:
		return
	_order_march()


func _order_march() -> void:
	marching = true
	EventBus.world_event.emit({
		"type": "GARRISON_MARCHES",
		"target": "Guarda real", "cause": "knight",
		"position": knight.global_position if knight != null else Vector2.ZERO,
		"severity": 0.8, "narrative_value": 0.6,
	})


func _expel() -> void:
	expelled = true
	EventBus.world_event.emit({
		"type": "KNIGHT_EXPELLED",
		"target": "Cavaleiro", "cause": "soldiers",
		"position": knight.global_position, "severity": 1.0, "narrative_value": 0.9,
	})
	EventBus.emit_intervention_ended("expelled")
