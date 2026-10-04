extends Node

# First social slice: witnesses remember danger and loss of royal credibility.
# Values are prototype tuning, not fixed political opinions for each class.
var fear := 0.0
var frenzy := 0.0
var cohesion := 85.0
var king_prestige := {"Workers": 50.0, "Bourgeoisie": 50.0, "Nobility": 50.0, "Soldiers": 50.0}
var broadcast_count := 0

func _ready() -> void:
	EventBus.world_event.connect(_on_event)

func _process(delta: float) -> void:
	fear = maxf(0, fear - delta * 0.5)
	frenzy = maxf(0, frenzy - delta * 0.12)
	cohesion = minf(85, cohesion + delta * 0.6)

func witnesses(position: Vector2, radius: float = 600.0) -> Array:
	var result: Array = []
	for person in get_tree().get_nodes_in_group("people"):
		if person.global_position.distance_to(position) <= radius:
			result.append(person)
	return result

func _on_event(event: Dictionary) -> void:
	var kind: String = event.get("type", "")
	if kind not in ["STRUCTURE_HIT", "STRUCTURE_DESTROYED", "SOLDIER_DISORGANIZED", "RESERVOIR_OPENED"]:
		return
	var nearby := witnesses(event.get("position", Vector2.ZERO))
	var severity: float = clampf(event.get("severity", 0.5), 0.1, 1.0)
	if kind == "SOLDIER_DISORGANIZED":
		cohesion = maxf(0, cohesion - 25.0 * severity)
	if nearby.is_empty():
		return
	fear = clampf(fear + severity * 18, 0, 100)
	frenzy = clampf(frenzy + severity * 10, 0, 100)
	var groups: Array[String] = []
	for person in nearby:
		var group: String = person.social_group
		if group not in groups:
			groups.append(group)
		person.social_alarm = maxf(person.social_alarm, 9.0 + severity * 8)
		# Witnesses seek safety together, even outside the direct blast radius.
		if person.label not in ["Soldier", "King"] and kind != "RESERVOIR_OPENED":
			person.fear_seconds = maxf(person.fear_seconds, 2.0 + severity * 2)
			person._flee_direction = -1.0 if person.global_position.x < event.get("position", Vector2.ZERO).x else 1.0
	for group in groups:
		king_prestige[group] = clampf(king_prestige[group] - severity * 5, 0, 100)

func receive_propaganda(event: Dictionary, audience: Array) -> void:
	# Repeated slogans alone cannot generate legitimacy; a witnessed fact is required.
	if event.is_empty() or audience.is_empty():
		return
	broadcast_count += 1
	var seen: Array[String] = []
	for person in audience:
		if person.social_group in seen:
			continue
		seen.append(person.social_group)
		# Direct experience of danger makes reassurance less convincing.
		var credibility: float = 0.2 if person.social_alarm > 0 else 1.0
		king_prestige[person.social_group] = clampf(king_prestige[person.social_group] + credibility, 0, 100)
