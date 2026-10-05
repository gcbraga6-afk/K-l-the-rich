extends Node

# Two rounds in the air at once. Neither may go off against the other: left on the
# default layer a round shares one with the terrain it is meant to hit, and a
# salvo detonates itself in the open sky.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(180)
	var impacts: Array = []
	EventBus.projectile_impacted.connect(func(e: Dictionary): impacts.append(e))
	var knight = world.get_node("Knight")
	# A fast flat round chasing a slow high one, so their paths cross in the open.
	knight._ammo = 8
	knight._intervention_active = true
	knight._fire(Vector2(1100, -760))
	await steps(16)
	knight._ammo = 8
	knight._fire(Vector2(1500, -140))
	await steps(220)
	for hit in impacts:
		print("  HIT ", hit.target, " at ", hit.position)
	assert(impacts.size() >= 1, "The rounds must land somewhere")
	for hit in impacts:
		# Nothing in the kingdom stands this high over the village floor.
		assert(hit.position.y > 260.0, "A round must not go off in the open sky")
		assert(str(hit.target) != "BasicProjectile", "A round must never detonate on another round")
	print("PASS: a salvo crosses without the rounds setting each other off")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
