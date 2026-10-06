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
	var tower := Node2D.new()
	tower.name = "ModularStructure"
	tower.set_script(preload("res://scripts/destruction/physical_castle_tower.gd"))
	tower.kind = "castle"
	$Structures/Castle.add_child(tower)
	var sky := Node2D.new()
	sky.name = "PropagandaSky"
	sky.set_script(preload("res://scripts/world/propaganda_sky.gd"))
	add_child(sky)
	var society := Node.new()
	society.name = "Society"
	society.set_script(preload("res://scripts/systems/kingdom_society.gd"))
	add_child(society)
	var broadcast := Node2D.new()
	broadcast.name = "Broadcast"
	broadcast.set_script(preload("res://scripts/systems/mirror_broadcast.gd"))
	$Structures/Mirror.add_child(broadcast)

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
