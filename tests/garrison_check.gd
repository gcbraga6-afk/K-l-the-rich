extends Node2D

# The garrison's whole duty, in order: noticing, investigating, marching on the
# Knight, expelling him -- and the Flash taking the march away.

var world: Node2D
var events: Array[String] = []
var ended := ""

func _ready() -> void:
	world = $World
	EventBus.world_event.connect(func(e): events.append(e.get("type", "")))
	EventBus.intervention_ended.connect(func(r): ended = r)
	await get_tree().process_frame
	await get_tree().process_frame

	var garrison = world.get_node("Garrison")
	var knight = world.get_node("Knight")
	var soldiers := []
	for p in get_tree().get_nodes_in_group("people"):
		if p.label == "Soldier":
			soldiers.append(p)
	print("soldados no Reino: ", soldiers.size())
	var near = soldiers[0]

	# 1. A round within earshot: he stops, turns and shouts.
	_damage(near.global_position + Vector2(260, 0), 0.5)
	var noticed: bool = near.alert_seconds > 0.0
	print("1 notou e gritou:      ", noticed, "   alerta=", "%.1f" % near.alert_seconds)

	# 2. Once the shouting is done he walks to where it happened.
	var sent: bool = near.march_target != INF
	print("2 foi mandado olhar:   ", sent)

	# 3. Below the cohesion floor nobody forms up, however much damage there is.
	world.get_node("Society").cohesion = 10.0
	for i in range(14):
		_damage(near.global_position + Vector2(300, 0), 1.0)
	var held_back: bool = not garrison.marching
	print("3 sem coesão, sem marcha: ", held_back, "   provocação=", "%.1f" % garrison.provocation)

	# 4. With the garrison whole, enough damage puts it on the road.
	world.get_node("Society").cohesion = 80.0
	_damage(near.global_position + Vector2(300, 0), 1.0)
	print("4 marcha ordenada:     ", garrison.marching)

	# 5. Walking at the Knight ends the intervention.
	for s in soldiers:
		s.global_position.x = knight.global_position.x + 80.0
	await get_tree().process_frame
	await get_tree().process_frame
	print("5 expulso:             '", ended, "'")

	# 6. Two flashes and a soldier stops being one.
	var victim = soldiers[1]
	victim.react_to_blast(victim.global_position, "Flash")
	var first: bool = victim.disorganized_seconds > 0.0 and not victim.deserted
	victim.react_to_blast(victim.global_position, "Flash")
	print("6 1º flash desarma:    ", first, "   2º flash deserta: ", victim.deserted)

	var ok: bool = noticed and sent and held_back and garrison.marching \
		and ended == "expelled" and first and victim.deserted \
		and "GARRISON_MARCHES" in events and "SOLDIER_DESERTED" in events
	print("OK" if ok else "FAIL")
	get_tree().quit()


func _damage(at: Vector2, severity: float) -> void:
	EventBus.world_event.emit({
		"type": "STRUCTURE_HIT", "target": "Casa", "cause": "knight",
		"position": at, "severity": severity, "narrative_value": 0.5,
	})
