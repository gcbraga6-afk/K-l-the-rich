extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	var social = world.get_node("Society")
	var mirror = world.get_node("Structures/Mirror")
	var broadcast = mirror.get_node("Broadcast")
	broadcast.set_process(false)
	var untouched: float = social.fear
	social._on_event({"type": "STRUCTURE_HIT", "target": "Distant", "position": Vector2(-10000,-10000), "severity": 1.0})
	assert(social.fear == untouched, "Unwitnessed damage must not frighten distant people")
	var house = world.get_node("Structures/VillageHouse")
	var worker = world.get_node("Characters/WorkerA")
	worker.global_position = house.global_position
	var before: float = social.king_prestige.Workers
	house.apply_explosion_damage(1, house.global_position)
	assert(social.fear > 0 and social.frenzy > 0)
	assert(social.king_prestige.Workers < before)
	assert(worker.social_alarm > 0 and worker.fear_seconds > 0)
	broadcast._process(0.1)
	assert(broadcast.current_message.contains("Casas atingidas"))
	assert(broadcast.pending.is_empty())
	var count: int = social.broadcast_count
	broadcast._process(0.1)
	assert(social.broadcast_count == count, "The same message must not award prestige repeatedly")
	var guard = world.get_node("Characters/SoldierB")
	guard.react_to_blast(guard.global_position, "Flash")
	assert(social.cohesion < 85)
	broadcast._process(13)
	assert(broadcast.current_message.contains("Guardas atingidos"))
	mirror.apply_explosion_damage(99, mirror.global_position)
	broadcast._process(0.1)
	assert(not broadcast.screen.visible)
	assert(broadcast.pending.is_empty())
	print("PASS: witnessed damage, fear, prestige, cohesion, fact-based messages, deduplication and mirror silence")
	get_tree().quit()
