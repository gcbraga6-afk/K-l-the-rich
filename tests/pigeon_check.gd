extends Node

# The Pigeon is the Knight's only way into the Kingdom's own channel, and the
# design calls that the point of the whole mirror. It was written and never put
# into the world, and the mirror had no way to be taken over.

func _ready() -> void:
	call_deferred("run")

func run() -> void:
	var world = load("res://scenes/main.tscn").instantiate()
	get_tree().root.add_child(world)
	get_tree().current_scene = world
	await steps(180)
	var pigeon = world.get_node_or_null("Pigeon")
	assert(pigeon != null, "The Pigeon must be in the world, not only in a file")
	# It looks these up as it enters the tree, and a miss leaves it mute without
	# failing anything — which is how it sat silent before.
	assert(pigeon.mirror != null and pigeon.broadcast != null,
		"The Pigeon must have found the mirror it is meant to take over")
	assert(pigeon.frames.size() > 3, "The whole wingbeat must be there, not three poses")
	var broadcast = world.get_node("Structures/Mirror/Broadcast")
	var kingdom_screen: Texture2D = broadcast.screen.texture
	# Mark something, send the bird, let it settle on the mirror.
	var target = world.get_node("Village").front_houses[2]
	assert(pigeon.mark_target(target), "The Knight must be able to mark a target")
	assert(pigeon.deploy(), "The Pigeon must fly")
	for wait in range(1200):
		await get_tree().physics_frame
		if pigeon.state == pigeon.State.DORMANT:
			break
	assert(pigeon.state == pigeon.State.DORMANT, "It must settle on the mirror unnoticed")
	print("PIGEON dormant after ", pigeon.clock, "s")
	# And then take the channel.
	assert(pigeon.connect_live(), "Connecting must take the Kingdom's channel")
	await steps(10)
	assert(broadcast.live, "The mirror must know it has been taken over")
	assert(broadcast.screen.texture != kingdom_screen,
		"The glass must carry the Knight's feed, not the Crown's programme")
	var said: String = broadcast.current_message
	broadcast._on_event({"type": "STRUCTURE_DESTROYED", "target": "VillageHouse02", "position": Vector2.ZERO})
	await steps(10)
	assert(broadcast.current_message == said,
		"The Crown must not speak over a channel it has lost")
	print("PIGEON live, the Crown is off its own mirror")
	# Calling the bird back hands the channel over.
	pigeon.return_home()
	await steps(10)
	assert(not broadcast.live, "The Crown gets its screen back when the bird leaves")
	assert(broadcast.screen.texture == kingdom_screen, "and its own programme with it")
	print("PASS: the Pigeon reaches the mirror, takes the channel and gives it back")
	get_tree().quit()

func steps(count: int) -> void:
	for i in count:
		await get_tree().physics_frame
