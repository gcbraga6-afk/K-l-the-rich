extends Node2D

# Does powder come off the Kingdom, and does an empty rack wait for the round
# still in the air before it closes the intervention?

var world: Node2D
var ammo := -1
var seized: Array = []
var ended := ""

func _ready() -> void:
	world = $World
	EventBus.ammo_changed.connect(func(current, _max): ammo = current)
	EventBus.ammo_seized.connect(func(amount, _pos, source): seized.append([source, amount]))
	EventBus.intervention_ended.connect(func(reason): ended = reason)
	await get_tree().process_frame
	await get_tree().process_frame

	var store = world.get_node("PowderStore")
	var cart = world.get_node("SupplyCart")
	var knight = world.get_node("Knight")
	print("rack at arrival: ", ammo, "   store crates: ", store.crates, "   cart crates: ", cart.crates)

	# The store, taken with one round landing on the pile.
	_blast(store.global_position + Vector2(0, -26))
	await get_tree().create_timer(0.4).timeout
	print("store taken -> rack ", ammo, "  store spent: ", store.spent)

	# The cart, once it is rolling, hit on the crates rather than on the bench.
	cart.rolling = true
	cart.visible = true
	cart.position.x = 1400.0
	await get_tree().process_frame
	_blast(cart.global_position + Vector2(-30, -56))
	await get_tree().create_timer(0.4).timeout
	print("cart taken  -> rack ", ammo, "  driver struck: ", cart.driver_struck)

	# A dry rack with a round in the air must not end the intervention.
	knight._ammo = 0
	knight._emit_ammo_changed()
	var round_body := preload("res://scenes/projectile.tscn").instantiate()
	round_body.global_position = Vector2(2000, 200)
	round_body.linear_velocity = Vector2(300, -200)
	world.add_child(round_body)
	await get_tree().create_timer(0.6).timeout
	print("dry, round in the air -> ended: '", ended, "'  (want empty)")
	var held := ended == ""
	round_body.queue_free()
	await get_tree().create_timer(2.2).timeout
	print("dry, sky clear        -> ended: '", ended, "'  (want ammo_empty)")

	var ok := seized.size() == 2 and held and ended == "ammo_empty"
	print("seized: ", seized)
	print("OK" if ok else "FAIL")
	get_tree().quit()


func _blast(at: Vector2) -> void:
	var boom = preload("res://scenes/explosion.tscn").instantiate()
	boom.global_position = at
	world.add_child(boom)
