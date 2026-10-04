extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await get_tree().process_frame
	var house = world.get_node("Structures/VillageHouse")
	var soldier = world.get_node("Characters/SoldierA")
	var worker = world.get_node("Characters/WorkerA")
	var knight = world.get_node("Knight")
	worker.position = house.position + Vector2(30,70)
	var blast_scene = load("res://scenes/explosion.tscn")
	var flash = blast_scene.instantiate()
	flash.weapon = "Flash"
	flash.position = house.global_position
	world.add_child(flash)
	assert(house._integrity == house.max_integrity, "Flash must not damage structures")
	assert(worker.fear_seconds > 0.0, "Nearby civilians must flee")
	soldier.react_to_blast(soldier.global_position, "Flash")
	assert(soldier.disorganized_seconds > 0.0, "Flash must disorganize soldiers")
	soldier._physics_process(8.0)
	assert(soldier.disorganized_seconds > 0.0, "Shaken cohesion must delay recovery")
	soldier._physics_process(20.0)
	assert(soldier.disorganized_seconds == 0.0, "Soldiers must eventually recover")
	var basic = blast_scene.instantiate()
	basic.position = house.global_position + Vector2(150, 0)
	world.add_child(basic)
	assert(house._integrity < house.max_integrity, "Explosion must measure distance to building surface")
	var physical = house.get_node("PhysicalHouse")
	assert(physical.pieces.size() == 14, "Explosion must preserve the original physical parts")
	assert(house.get_node("CollisionShape2D").disabled, "Legacy solid facade must not block the moving pieces")
	for piece in physical.pieces:
		assert(piece.has_node("Skin"), "Damage must never swap a piece for a ruined sprite")
	knight._ammo = 1
	knight._fire(Vector2(1500, -1500))
	assert(not knight._intervention_active, "Last shot must end intervention")
	assert(get_tree().get_nodes_in_group("active_projectiles").size() == 1, "Last shot must remain in flight")
	var camera = world.get_node("KingdomCamera")
	var projectile = get_tree().get_nodes_in_group("active_projectiles")[0]
	assert(camera._follow_target == projectile, "Camera must follow fired projectile")
	projectile.position = Vector2(2400, -400)
	for frame in 180: camera._process(0.016)
	assert(absf(camera.position.x-projectile.position.x) < 1.0, "Camera must track horizontal flight")
	projectile.queue_free()
	await get_tree().process_frame
	camera._process(0.016)
	assert(is_equal_approx(camera.position.x, 2400.0), "Camera must remain near impact")
	var home := InputEventKey.new()
	home.keycode = KEY_HOME
	home.pressed = true
	camera._unhandled_key_input(home)
	for frame in 180: camera._process(0.016)
	assert(camera.position.x == camera.min_x, "Home must return to cannon")
	await get_tree().create_timer(0.9).timeout
	print("PASS: Flash, fear, recovery, blast damage, ruins, last shot and projectile camera")
	get_tree().quit()
