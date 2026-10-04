extends Node2D

const HouseArt = preload("res://scripts/village/house_art.gd")
const Structure = preload("res://scripts/world/structure.gd")
const Haze = preload("res://scripts/village/house_haze.gdshader")
const NobleSheet = preload("res://assets/composition/nobles.png")
var noble_houses: Array[Node2D] = []
var world: Node2D

func _ready() -> void:
	world = get_parent()
	world.get_node("WorldBounds/Ground").collision_layer = 0
	world.get_node("WorldBounds/Ground").collision_mask = 0
	var terrain := Node2D.new()
	terrain.name = "Terraces"
	terrain.set_script(preload("res://scripts/world/terraces.gd"))
	world.add_child(terrain)
	var village = world.get_node("Village")
	for child in village.get_children():
		if child.get_script() == preload("res://scripts/village/street_details.gd"):
			child.hide()
	for child in village.rear_row.get_children():
		if not child is Sprite2D:
			child.hide()
	var xs := [790, 1030, 1290, 1550, 1780, 2000, 2400, 3700]
	for i in village.front_houses.size():
		var b = village.front_houses[i]
		place(b, Vector2(xs[i], 665 if i < 6 else 710), 225 if i < 6 else 180)
		if i >= 6:
			haze(b.get_node("Artwork"), 0.07)
	for i in village.rear_houses.size():
		var b = village.rear_houses[i]
		b.scale *= 0.94
		var x: float = 710 + i * 125
		b.position = Vector2(x-b.texture.get_width()*b.scale.x/2, 630-b.texture.get_height()*b.scale.y)
	var businesses = world.get_node("Businesses")
	var bx := [905, 1160, 1440, 1660, 2720, 2990, 3260, 3530]
	for i in businesses.buildings.size():
		var b = businesses.buildings[i]
		place(b, Vector2(bx[i], 665 if i < 4 else 710), 205 if i < 4 else 330)
		if i >= 4:
			haze(b.get_node("Artwork"), 0.09)
		b.get_node("NameLabel").hide()
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/composition/nobles.json"))
	for i in range(6):
		var tex := AtlasTexture.new()
		tex.atlas = NobleSheet
		var r: Array = rows[i % 4]
		tex.region = Rect2(r[0],r[1],r[2],r[3])
		tex.filter_clip = true
		if i < 4:
			var b := make_building("NobleHouse%d" % (i+1), tex)
			place(b, Vector2([4320,4580,4830,5080][i], 665 if i < 3 else 625), [265,220,260,245][i])
			haze(b.get_node("Artwork"), 0.10)
			noble_houses.append(b)
		else:
			var b := Sprite2D.new()
			b.texture = tex
			b.centered = false
			b.scale = Vector2.ONE * (195.0 / tex.get_width())
			b.position = Vector2(4390+(i-4)*410, 630-tex.get_height()*b.scale.y)
			b.z_index = -5
			haze(b, 0.17)
			add_child(b)
	var castle = world.get_node("Structures/Castle")
	replace_art(castle, preload("res://assets/composition/castle.png"))
	place(castle, Vector2(6250,535), 950)
	haze(castle.get_node("Artwork"), 0.055)
	# The new enclosing wall belongs to the castle silhouette. Retire the old mock wall.
	for id in ["Wall", "Mirror", "School"]:
		var b = world.get_node("Structures/"+id)
		b.hide()
		b.collision_layer = 0
		b.get_node("CollisionShape2D").disabled = true
		b.remove_from_group("structures")
	var knight = world.get_node("Knight")
	knight.position = Vector2(180,475)
	knight.get_node("Body").hide()
	var sprite := Sprite2D.new()
	sprite.texture = preload("res://assets/composition/knight.png")
	sprite.centered = false
	sprite.scale = Vector2.ONE * 0.135
	sprite.position = Vector2(-137,-135)
	knight.add_child(sprite)
	knight.get_node("CannonPivot").position = Vector2(24,-28)
	knight.get_node("CannonPivot").z_index = 2
	var cannon_art := Node2D.new()
	cannon_art.set_script(preload("res://scripts/art/cannon_carriage.gd"))
	knight.add_child(cannon_art)
	for person in world.get_node("Characters").get_children():
		person.scale *= 0.64
		if person.label != "Soldier":
			person.position.x = 950 + person.get_index()*77
			person.left_x = 850
			person.right_x = 3700

func haze(item: CanvasItem, amount: float) -> void:
	var material := ShaderMaterial.new()
	material.shader = Haze
	material.set_shader_parameter("haze_amount", amount)
	item.material = material

func replace_art(b: Node2D, texture: Texture2D) -> void:
	var old = b.get_node_or_null("Artwork")
	if old:
		b.remove_child(old)
		old.queue_free()
	var art := Node2D.new()
	art.name = "Artwork"
	art.set_script(HouseArt)
	art.house_texture = texture
	b.add_child(art)

func place(b: Node2D, foot: Vector2, width: float) -> void:
	b.position = foot - Vector2(0,70)
	b._base_position = b.position
	var art = b.get_node("Artwork")
	art.ground_y = foot.y
	art.house_width = width
	art.queue_redraw()
	var height: float = width * art.house_texture.get_height() / art.house_texture.get_width()
	var visual: ColorRect = b.get_node("Visual")
	visual.position = Vector2(-width*0.40,70-height*0.88)
	visual.size = Vector2(width*0.80,height*0.88)
	var shape := RectangleShape2D.new()
	shape.size = visual.size
	b.get_node("CollisionShape2D").shape = shape
	b.get_node("CollisionShape2D").position = visual.position+visual.size/2

func make_building(id: String, texture: Texture2D) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = id
	b.set_script(Structure)
	b.add_to_group("structures")
	var visual := ColorRect.new()
	visual.name = "Visual"
	b.add_child(visual)
	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	b.add_child(collision)
	var label := Label.new()
	label.name = "NameLabel"
	b.add_child(label)
	world.get_node("Structures").add_child(b)
	replace_art(b,texture)
	return b
