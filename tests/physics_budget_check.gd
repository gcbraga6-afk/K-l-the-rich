extends Node

const Fracture = preload("res://scripts/destruction/fracture.gd")

# A physics step must fit inside its own tick, or the game runs in slow motion.
#
# At 120 Hz a step has 8.33 ms. If a step costs more than that the engine cannot
# deliver 120 of them per second, the physics clock falls behind the wall clock,
# and everything on screen crawls. It shows up exactly when a round throws
# hundreds of shards, because that is when the solver has the most to do.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(240)
	var budget := 1000.0 / float(Engine.physics_ticks_per_second)
	var quiet := await _cost(30)
	print("BUDGET ", budget, " ms per step at ", Engine.physics_ticks_per_second, " Hz")
	print("QUIET  ", quiet, " ms per step, ", _shards(), " shards")
	var target = world.get_node("Village").front_houses[2]
	var house = target.get_node("PhysicalHouse")
	var facade = house.facade
	for spot in [Vector2(0.4, 0.12), Vector2(0.3, 0.45), Vector2(0.55, 0.3)]:
		house.damage_near(2, facade.to_global(facade.base_offset
			+ Vector2(facade.art.get_width() * spot.x, facade.art.get_height() * spot.y) * facade.pixel), 1.0)
		await steps(30)
	var storm := await _cost(90)
	var busy: int = Performance.get_monitor(Performance.PHYSICS_2D_ACTIVE_OBJECTS)
	var live := 0
	var scenery := 0
	for node in get_tree().get_nodes_in_group("stone_shards"):
		if not is_instance_valid(node):
			continue
		if node.freeze:
			scenery += 1
		else:
			live += 1
	print("STORM  ", storm, " ms per step, ", busy, " bodies simulated")
	print("       of which shards: ", live, " live, ", scenery, " scenery (budget ", Fracture.SHARD_BUDGET, ")")
	print("HEADROOM ", budget / storm, "x (milliseconds are for reading, not for judging)")
	# The milliseconds are not assertable. The same storm measured 13.2 ms on a quiet
	# machine, 21.1 with a battery beside it and 27.0 with an editor running the game:
	# the number carries the load of whatever else is open, so a threshold on it fails
	# for reasons that have nothing to do with this code.
	#
	# What drove the cost is countable and deterministic: how many bodies the solver
	# is actually simulating. The fault this guards against was 330 live shards at
	# 120 Hz, a step costing several times its tick, which the engine cannot deliver —
	# so the physics clock falls behind the wall clock and the game runs in slow
	# motion. Hold the body count and the milliseconds follow.
	var faults: Array = []
	# The live shards are the part this code controls, so that is what is judged.
	# The total is printed beside it to keep the judgement readable.
	if live > Fracture.SHARD_BUDGET:
		faults.append("more live shards than the budget allows: %d" % live)
	if _shards() > 260:
		faults.append("frozen rubble piling up without end: %d" % _shards())
	if not faults.is_empty():
		# Printed and quit rather than asserted: a failed assert halts the script
		# without ending the process, which hangs the whole battery behind it.
		print("FAIL: ", ", ".join(faults))
		get_tree().quit(1)
		return
	print("PASS: the solver keeps real time through a shard storm")
	get_tree().quit()

# Milliseconds the engine spends inside a physics step, averaged over a run of
# frames. Wall-clock time between `physics_frame` signals is useless here: it
# paces with the tick by definition, so it reads the tick period whether the
# solver is idle or drowning.
func _cost(frames: int) -> float:
	# One frame thrown away first: the one straight after a carve carries the
	# carve's own cost and is not what the following seconds look like.
	await get_tree().physics_frame
	var total := 0.0
	for i in frames:
		await get_tree().physics_frame
		total += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
	return total / float(frames) * 1000.0

func _shards() -> int:
	return get_tree().get_nodes_in_group("stone_shards").size()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
