extends Node2D

const LANDSCAPE = preload("res://assets/backgrounds/distant_mountains.png")
const VALLEY = preload("res://assets/backgrounds/valley_midground.png")
const WOODLAND = preload("res://assets/backgrounds/near_vegetation.png")
const BACKGROUND_SCALE := 1.5
@export_range(0.0, 1.0) var far_scroll_speed := 0.16
var camera: Camera2D

func _ready() -> void:
	z_index = -20
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	camera = get_parent().get_node("KingdomCamera")
	_add_band("ValleyDepth", VALLEY, 0.20, 765.0, 0.38)
	_add_band("WoodlandDepth", WOODLAND, 0.24, 760.0, 0.24)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if camera == null: return
	draw_rect(Rect2(-10000,-12000,30000,22000),Color("568dce"))
	# Distant scenery travels slowly across the screen, at a fixed uniform scale.
	# It no longer needs to be enlarged to the full length of the game world.
	var shift := (camera.position.x-800.0)*(1.0-far_scroll_speed)
	var size := LANDSCAPE.get_size()*BACKGROUND_SCALE
	draw_texture_rect(LANDSCAPE,Rect2(Vector2(-300+shift,750-size.y),size),false)

func _add_band(id: String, texture: Texture2D, scroll: float, bottom: float, haze: float) -> void:
	var band := Node2D.new()
	band.name = id
	band.set_script(preload("res://scripts/art/landscape_band.gd"))
	band.texture = texture
	band.camera = camera
	band.scroll_speed = scroll
	band.bottom = bottom
	band.texture_scale = 1.3 if id == "ValleyDepth" else 1.4
	band.haze_amount = haze
	add_child(band)
