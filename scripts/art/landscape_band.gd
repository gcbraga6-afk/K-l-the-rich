extends Node2D

var texture: Texture2D
var camera: Camera2D
var scroll_speed := 0.20
var texture_scale := 1.3
var bottom := 760.0
var haze_amount := 0.3

func _ready() -> void:
	var material := ShaderMaterial.new()
	material.shader = preload("res://scripts/village/house_haze.gdshader")
	material.set_shader_parameter("haze_color", Color("b6ccd9"))
	material.set_shader_parameter("haze_amount", haze_amount)
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.material = material
	sprite.position = Vector2(0,bottom-texture.get_height()*texture_scale)
	sprite.scale = Vector2.ONE*texture_scale
	add_child(sprite)
	_process(0.0)

func _process(_delta: float) -> void:
	position.x = -100.0+(camera.position.x-800.0)*(1.0-scroll_speed)
