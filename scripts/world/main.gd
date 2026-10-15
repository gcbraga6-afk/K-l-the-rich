extends Node2D

func _ready() -> void:
	# A physics step has to fit inside its own tick. Past that the engine cannot
	# deliver the ticks, the physics clock falls behind the wall clock, and the whole
	# game visibly runs in slow motion — which is how a shard storm used to look.
	# Measured, a step with rubble in the air costs around 30 ms, so 120 Hz asked for
	# nearly four times what it could pay. Rounds carry shape-cast CCD, so the high
	# rate was never what kept them from tunnelling.
	Engine.physics_ticks_per_second = 60
	DisplayServer.window_set_title("K**l the Rich — 1920 × 1080 · câmera suave")
	_expand_kingdom()
	$Backdrop.hide()
	$WorldBounds/Ground/GroundVisual.hide()
	$WorldBounds/DryCracks.hide()
	var landscape := Node2D.new()
	landscape.name = "Landscape"
	landscape.set_script(preload("res://scripts/art/kingdom_landscape.gd"))
	add_child(landscape)
	for building in $Structures.get_children():
		if building.name == "VillageHouse":
			continue
		var art := Node2D.new()
		art.name = "Artwork"
		art.set_script(preload("res://scripts/art/building_art.gd"))
		building.add_child(art)

	var village := Node2D.new()
	village.name = "Village"
	village.set_script(preload("res://scripts/village/village.gd"))
	add_child(village)
	var businesses := Node2D.new()
	businesses.name = "Businesses"
	businesses.set_script(preload("res://scripts/village/businesses.gd"))
	add_child(businesses)
	var composition := Node2D.new()
	composition.name = "Composition"
	composition.set_script(preload("res://scripts/world/composition.gd"))
	add_child(composition)
	var court := Node2D.new()
	court.name = "RoyalCourt"
	court.set_script(preload("res://scripts/world/royal_court.gd"))
	add_child(court)
	# Every building a round can reach is carved: cottages, trade and the terrace of
	# noble houses alike. One left on the old model falls back to its painted ruin,
	# which is a row of flat grey rectangles in a street where everything else
	# breaks properly.
	for house in village.front_houses + businesses.buildings + composition.noble_houses:
		var physical_house := Node2D.new()
		physical_house.name = "PhysicalHouse"
		physical_house.set_script(preload("res://scripts/destruction/carved_house.gd"))
		house.add_child(physical_house)
	# The castle is carved like everything else now, with its own drawn interior.
	# It used to be the one tower built out of stacked blocks, with the rest of the
	# keep a static prop that could not be touched — the last of the old model.
	var keep := Node2D.new()
	keep.name = "PhysicalHouse"
	keep.set_script(preload("res://scripts/destruction/carved_house.gd"))
	keep.interior = preload("res://assets/castle/castle_interior.png")
	# Three times the stone of a cottage wall, so the keep asks for a bombardment
	# rather than a visit.
	keep.toughness = 3.0
	$Structures/Castle.add_child(keep)
	var sky := Node2D.new()
	sky.name = "PropagandaSky"
	sky.set_script(preload("res://scripts/world/propaganda_sky.gd"))
	add_child(sky)
	# The Kingdom's powder, and the only reason the cannon can outlast the load it
	# arrived with. The store stands against the castle's near flank, where the
	# carts unload: the strip between the noble terrace and the castle belongs to
	# the Mirror, which spans 5400 to 5740, and a store dropped in there stood in
	# the propaganda board and hung off the edge of the terrace. The cart sets out
	# from the village end and climbs the road to the store.
	var store := Node2D.new()
	store.name = "PowderStore"
	store.set_script(preload("res://scripts/world/powder_store.gd"))
	store.position.x = 5880.0
	add_child(store)
	var cart := Node2D.new()
	cart.name = "SupplyCart"
	cart.set_script(preload("res://scripts/world/supply_cart.gd"))
	add_child(cart)
	var society := Node.new()
	society.name = "Society"
	society.set_script(preload("res://scripts/systems/kingdom_society.gd"))
	add_child(society)
	# Until the garrison existed, nothing the player did ever walked back at him.
	var garrison := Node.new()
	garrison.name = "Garrison"
	garrison.set_script(preload("res://scripts/systems/garrison.gd"))
	add_child(garrison)
	var broadcast := Node2D.new()
	broadcast.name = "Broadcast"
	broadcast.set_script(preload("res://scripts/systems/mirror_broadcast.gd"))
	$Structures/Mirror.add_child(broadcast)

	# The Pigeon, after the mirror has its broadcast: it looks the broadcast up as it
	# enters the tree. It was written and never put into the world — the knight's
	# only way into the Kingdom's own channel, which the design calls the point of
	# the whole mirror.
	var pigeon := Node2D.new()
	pigeon.name = "Pigeon"
	pigeon.set_script(preload("res://scripts/systems/pigeon.gd"))
	add_child(pigeon)

	EventBus.projectile_fired.connect(_on_projectile_fired)
	EventBus.projectile_impacted.connect(_on_projectile_impacted)
	EventBus.intervention_ended.connect(_on_intervention_ended)


func _on_projectile_fired(event: Dictionary) -> void:
	print("PROJECTILE_FIRED ", event)


func _on_projectile_impacted(event: Dictionary) -> void:
	print("PROJECTILE_IMPACTED ", event)


func _on_intervention_ended(reason: String) -> void:
	print("INTERVENTION_ENDED ", reason)


func _expand_kingdom() -> void:
	$KingdomCamera.configure_world(preload("res://scripts/world/terraces.gd").WORLD_WIDTH)
	var ground: StaticBody2D = $WorldBounds/Ground
	ground.position.x = 3800.0
	var shape := RectangleShape2D.new()
	shape.size = Vector2(7600, 80)
	ground.get_node("CollisionShape2D").shape = shape
	var locations := {"School": 4460.0, "Factory": 4820.0, "Mirror": 6160.0, "Wall": 6490.0, "Castle": 7130.0}
	for id in locations:
		var building = $Structures.get_node(id)
		building.position.x = locations[id]
		building._base_position = building.position
	$Characters/ChildA.position.x = 4400.0
	$Characters/ChildA.left_x = 4350.0
	$Characters/ChildA.right_x = 4520.0
	$Characters/SoldierA.position.x = 4650.0
	$Characters/SoldierA.left_x = 4480.0
	$Characters/SoldierA.right_x = 4800.0
	$Characters/SoldierB.position.x = 5700.0
	$Characters/SoldierB.left_x = 5550.0
	$Characters/SoldierB.right_x = 5950.0
