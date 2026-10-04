extends Node

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	await get_tree().process_frame
	var court = world.get_node("RoyalCourt")
	var king = court.king
	var mirror = court.mirror
	assert(king.is_in_group("royalty"))
	assert(mirror.visible and mirror.is_in_group("structures"))
	assert(not mirror.get_node("CollisionShape2D").disabled)
	assert(absf(king.position.x - mirror.position.x) < 200)
	var art = king.get_node("CharacterArt")
	assert(art.frames.size() == 4 and art.sprite.texture is AtlasTexture)
	king.velocity.x = -30
	art._process(0.2)
	assert(art.sprite.scale.x < 0)
	king.velocity.x = 30
	art._process(0.2)
	assert(art.sprite.scale.x > 0)
	var guard = world.get_node("Characters/CastleGuard")
	guard.react_to_blast(guard.global_position, "Flash")
	assert(guard.disorganized_seconds > 0)
	mirror.apply_explosion_damage(99, mirror.global_position)
	await get_tree().process_frame
	assert(mirror._integrity == 0)
	assert(mirror.get_node("CollisionShape2D").disabled)
	assert(king.fear_seconds > 0)
	print("ROYAL_COURT_CHECK_OK: walk frames, facing, guards, king, destructible mirror")
	get_tree().quit()
