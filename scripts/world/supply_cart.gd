extends "res://scripts/world/ammo_cache.gd"

# A Fairy Defense cart crossing the Kingdom to deliver powder at the castle gate.
# The Knight's rounds and the King's come off the same wagon, which is the whole
# joke, and the only moving resupply in the Kingdom.
#
# It sets out at the village end and climbs the road to the powder store at the
# castle's flank, so the easy shot is early, in a street full of people, and the
# hard shot is late, far away and under guard. The cart chooses nothing: the
# player does.

const Terraces = preload("res://scripts/world/terraces.gd")
const CART = preload("res://assets/props/supply_cart.png")
const PEOPLE = preload("res://assets/characters/people_walk.png")

const START_X := 620.0
const GATE_X := 5800.0
const FIRST_RUN := 26.0
const BETWEEN_RUNS := 95.0

const WIDTH := 230.0        # the cart stands about one and two thirds of a person
const CARTER_HEIGHT := 80.0 # the same height the village walks at

var speed := 58.0
var rolling := false
var driver_struck := false
var _wait := FIRST_RUN
var _carter: AtlasTexture

func _ready() -> void:
	super._ready()
	reach = 85.0
	title = "Carroça da Fairy Defense"
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The painted cart has a horse and a load but nobody driving it, so the carter
	# is a villager off the same sheet the rest of the Kingdom walks on. He is a
	# worker, which is the whole weight of hitting him instead of the crates.
	var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/people_walk.json"))
	var box: Array = rows[0][1]
	_carter = AtlasTexture.new()
	_carter.atlas = PEOPLE
	_carter.region = Rect2(box[0], box[1], box[2], box[3])
	_carter.filter_clip = true
	_park()


func _park() -> void:
	rolling = false
	spent = false
	driver_struck = false
	crates = 3
	per_hit = 3
	visible = false
	position.x = START_X


func _process(delta: float) -> void:
	if not rolling:
		_wait -= delta
		if _wait <= 0.0:
			rolling = true
			visible = true
			queue_redraw()
		return

	# A bolted horse keeps the wreck where it stopped, so the crates that were not
	# taken stay on the road as a second chance rather than rolling out of reach.
	if not driver_struck:
		position.x += speed * delta
	position.y = Terraces.walking_y(position.x)

	if position.x >= GATE_X or (spent and driver_struck):
		_wait = BETWEEN_RUNS
		_park()


# The carter walks at the horse's head, a stride ahead of the load. A round that
# lands on the crates is a resupply; one that lands on him is a dead worker, and
# the Kingdom will hear about that instead.
func driver_position() -> Vector2:
	return global_position + Vector2(WIDTH * 0.5 + 24.0, -CARTER_HEIGHT * 0.5)


func _on_seized(_taken: int, blast: Vector2) -> void:
	if blast.distance_to(driver_position()) <= 78.0:
		_strike_driver()
	queue_redraw()


func _on_emptied(blast: Vector2) -> void:
	if blast.distance_to(driver_position()) <= 110.0:
		_strike_driver()
	queue_redraw()


func _strike_driver() -> void:
	if driver_struck:
		return
	driver_struck = true
	EventBus.world_event.emit({
		"type": "PERSON_HIT",
		"target": "Carreteiro", "cause": "knight", "position": driver_position(),
		"severity": 1.0, "narrative_value": 1.0, "group": "Workers",
	})
	queue_redraw()


func _draw() -> void:
	if not rolling:
		return
	var height := WIDTH * CART.get_height() / CART.get_width()
	draw_texture_rect(CART, Rect2(-WIDTH * 0.5, -height, WIDTH, height), false)
	if driver_struck:
		return
	var factor := CARTER_HEIGHT / _carter.get_height()
	var width := _carter.get_width() * factor
	draw_texture_rect(_carter,
		Rect2(WIDTH * 0.5 + 24.0 - width * 0.5, -CARTER_HEIGHT, width, CARTER_HEIGHT), false)
