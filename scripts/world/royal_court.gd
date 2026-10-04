extends Node2D

const Walker = preload("res://scenes/characters/simple_walker.tscn")
const ResidentArt = preload("res://scripts/village/resident_art.gd")
var king: CharacterBody2D
var mirror: StaticBody2D

func _ready() -> void:
	var world := get_parent()
	var composition = world.get_node("Composition")
	mirror = world.get_node("Structures/Mirror")
	mirror.show()
	mirror.add_to_group("structures")
	mirror.collision_layer = 1
	mirror.get_node("CollisionShape2D").disabled = false
	var texture := AtlasTexture.new()
	texture.atlas = preload("res://assets/characters/propaganda_mirror.png")
	var box: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/propaganda_mirror.json"))
	texture.region = Rect2(box[0], box[1], box[2], box[3])
	texture.filter_clip = true
	composition.replace_art(mirror, texture)
	composition.place(mirror, Vector2(5570, preload("res://scripts/world/terraces.gd").walking_y(5570)), 340)
	var art = mirror.get_node("Artwork")
	art.set_script(preload("res://scripts/art/mirror_art.gd"))
	art.house_texture = texture
	art.house_width = 340.0
	art.ground_y = preload("res://scripts/world/terraces.gd").walking_y(5570)
	art.building = mirror
	king = _person("King", "King", 5630, 5600, 5750, 30, 0.82)
	king.patrol_pause = 4.0
	king.add_to_group("royalty")
	_person("CastleGuard", "Soldier", 6450, 6370, 6590, 40, 0.68)
	_person("FactoryGuard", "Soldier", 3170, 2670, 3600, 47, 0.64)
	EventBus.world_event.connect(_on_world_event)

func _person(id: String, role: String, x: float, left: float, right: float, pace: float, size: float) -> CharacterBody2D:
	var person = Walker.instantiate()
	person.name = id
	person.label = role
	person.left_x = left
	person.right_x = right
	person.speed = pace
	person.scale = Vector2.ONE * size
	get_parent().get_node("Characters").add_child(person)
	person.position = Vector2(x, preload("res://scripts/world/terraces.gd").walking_y(x))
	person.z_index = 8
	var art := Node2D.new()
	art.name = "CharacterArt"
	art.set_script(ResidentArt)
	person.add_child(art)
	return person

func _on_world_event(event: Dictionary) -> void:
	if event.get("target") == "Mirror" and event.get("type") == "STRUCTURE_DESTROYED":
		king.react_to_blast(mirror.global_position, "Basic")
