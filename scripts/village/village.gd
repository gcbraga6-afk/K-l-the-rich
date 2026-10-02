extends Node2D

const Catalog = preload("res://scripts/village/house_catalog.gd")
const HouseArt = preload("res://scripts/village/house_art.gd")
const Structure = preload("res://scripts/world/structure.gd")
const Walker = preload("res://scenes/characters/simple_walker.tscn")
const ResidentArt = preload("res://scripts/village/resident_art.gd")
const Depth = preload("res://scripts/village/village_depth.gd")
const StreetDetails = preload("res://scripts/village/street_details.gd")
const Haze = preload("res://scripts/village/house_haze.gdshader")

var rear_row: Node2D
var front_houses: Array[Node2D] = []
var rear_houses: Array[Sprite2D] = []

func _ready() -> void:
	var world := get_parent()
	rear_row = Node2D.new()
	rear_row.name = "RearStreet"
	rear_row.set_script(Depth)
	rear_row.camera = world.get_node("KingdomCamera")
	rear_row.z_index = -8
	add_child(rear_row)
	var rear_details := Node2D.new()
	rear_details.set_script(StreetDetails)
	rear_details.rear_street = true
	rear_details.z_index = -1
	rear_row.add_child(rear_details)
	var rear_positions := [600.0, 850.0, 1120.0, 1410.0, 1680.0, 1930.0, 2170.0, 2470.0, 2750.0, 3040.0, 3300.0, 3920.0]
	var rear_models := [4, 5, 6, 7, 9, 10, 11, 12, 13, 14, 15, 18]
	var haze := ShaderMaterial.new()
	haze.shader = Haze
	for i in range(rear_positions.size()):
		var sprite := Sprite2D.new()
		sprite.name = "RearHouse%02d" % (rear_models[i] + 1)
		sprite.texture = Catalog.house(rear_models[i])
		sprite.centered = false
		var factor := (185.0 + (i % 3) * 10.0) / sprite.texture.get_width()
		sprite.scale = Vector2.ONE * factor
		sprite.position = Vector2(rear_positions[i] - sprite.texture.get_width()*factor/2, 576-sprite.texture.get_height()*factor)
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		sprite.material = haze
		sprite.set_meta("model", rear_models[i])
		rear_row.add_child(sprite)
		rear_houses.append(sprite)
		rear_details.house_positions.append(rear_positions[i])
	var front_details := Node2D.new()
	front_details.set_script(StreetDetails)
	front_details.z_index = -1
	add_child(front_details)
	var positions := [980.0, 680.0, 1260.0, 1800.0, 2470.0, 3140.0, 3840.0, 4140.0]
	var models := [0, 2, 3, 8, 1, 16, 17, 19]
	for i in range(positions.size()):
		var house: StaticBody2D
		if i == 0:
			house = world.get_node("Structures/VillageHouse")
		else:
			house = StaticBody2D.new()
			house.name = "VillageHouse%02d" % (models[i]+1)
			house.set_script(Structure)
			house.add_to_group("structures")
			var visual := ColorRect.new()
			visual.name = "Visual"
			house.add_child(visual)
			var collision := CollisionShape2D.new()
			collision.name = "CollisionShape2D"
			house.add_child(collision)
			var label := Label.new()
			label.name = "NameLabel"
			house.add_child(label)
		var texture := Catalog.house(models[i])
		var width := 260.0 if i < 6 else 245.0
		var height := width * texture.get_height() / texture.get_width()
		house.position = Vector2(positions[i], 550)
		var visual: ColorRect = house.get_node("Visual")
		visual.position = Vector2(-width*0.40, 70-height*0.85)
		visual.size = Vector2(width*0.80, height*0.85)
		var shape := RectangleShape2D.new()
		shape.size = visual.size
		var collision: CollisionShape2D = house.get_node("CollisionShape2D")
		collision.shape = shape
		collision.position = visual.position + visual.size/2
		if i != 0:
			world.get_node("Structures").add_child(house)
		var art := Node2D.new()
		art.name = "Artwork"
		art.set_script(HouseArt)
		art.house_texture = texture
		art.house_width = width
		house.add_child(art)
		house.set_meta("model", models[i])
		front_houses.append(house)
		front_details.house_positions.append(positions[i])
	# Small groups walk between homes and existing workplaces.
	for i in range(11):
		var person := Walker.instantiate()
		person.name = "Villager%02d" % (i+1)
		person.position.x = 620.0 + i * 235
		person.left_x = maxf(520, person.position.x - 180)
		person.right_x = minf(3100, person.position.x + 360)
		person.speed = 22.0 + (i % 4) * 8
		person.body_color = [Color("69715c"), Color("927653"), Color("547481"), Color("936452")][i % 4]
		world.get_node("Characters").add_child(person)
	for person in world.get_node("Characters").get_children():
		person.z_index = 3
		var art := Node2D.new()
		art.set_script(ResidentArt)
		person.add_child(art)
		if person.label == "Child":
			person.scale = Vector2.ONE * 0.72
