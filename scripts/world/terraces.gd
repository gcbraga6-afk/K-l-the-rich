extends Node2D

# Three newly authored full-resolution sections. Never sample the rejected
# terrain.png and never magnify terrain pixels to stretch the world.
const WEST = preload("res://assets/composition/terrain_long_v2/west.png")
const CENTRAL = preload("res://assets/composition/terrain_long_v2/central.png")
const EAST = preload("res://assets/composition/terrain_long_v2/east.png")
const CASTLE_PLATEAU = preload("res://assets/composition/terrain_long_v2/castle_plateau.png")
const WORLD_WIDTH := 6927.0
const RIDGE = [Vector2(-500,475),Vector2(235,475),Vector2(560,640),Vector2(710,665),Vector2(2130,665),Vector2(2350,710),Vector2(3460,710),Vector2(3740,720),Vector2(4050,670),Vector2(5020,670),Vector2(5320,560),Vector2(5630,535),Vector2(6500,535),Vector2(6927,620)]

static func walking_y(x: float) -> float:
	for i in range(RIDGE.size()-1):
		if x <= RIDGE[i+1].x:
			return lerpf(RIDGE[i].y,RIDGE[i+1].y,clampf((x-RIDGE[i].x)/(RIDGE[i+1].x-RIDGE[i].x),0,1))
	return 480.0

func _ready() -> void:
	z_index = -9
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var body := StaticBody2D.new()
	body.name = "SculptedTerrain"
	var collision := CollisionPolygon2D.new()
	var points := PackedVector2Array(RIDGE)
	points.append(Vector2(WORLD_WIDTH,1800))
	points.append(Vector2(-500,1800))
	collision.polygon = points
	body.add_child(collision)
	add_child(body)
	var textures := [WEST,CENTRAL,EAST,CASTLE_PLATEAU]
	var origins := [Vector2(0,100),Vector2(2044,240),Vector2(4088,165),Vector2(5100,0)]
	for i in textures.size():
		var tile := Sprite2D.new()
		tile.name = ["NewVillageTerrain","NewIndustrialTerrain","NewCastleTerrain","CastlePlateauExtension"][i]
		tile.texture = textures[i]
		tile.centered = false
		tile.position = origins[i]
		tile.scale = Vector2.ONE
		if i > 0:
			var shader := Shader.new()
			shader.code = "shader_type canvas_item; varying float local_x; void vertex(){ local_x = VERTEX.x; } void fragment(){ COLOR.a *= smoothstep(0.0, 128.0, local_x); }"
			var material := ShaderMaterial.new()
			material.shader = shader
			tile.material = material
		add_child(tile)

func _draw() -> void:
	# Below the authored cutaway, continue soil outside the usual play framing.
	draw_rect(Rect2(0,810,WORLD_WIDTH,1200),Color("574531"))
	draw_rect(Rect2(5100,700,WORLD_WIDTH-5100,1200),Color("574531"))
