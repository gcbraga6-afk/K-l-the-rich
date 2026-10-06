extends Node2D

# Propaganda that comes to the player instead of waiting for him.
#
# The Mirror stands in one place, and a player who never walks that far never
# hears the Kingdom speak. A dragon crosses the sky with the Crown's banner, back
# behind the village, hazed into the distance. It can be shot down, and when it
# falls it goes down behind the plateau: no wreck to simulate, no body on the
# street, just the Kingdom's voice dropping out of the sky.

const SHEET = preload("res://assets/propaganda/dragon_banner_blank.png")
const HAZE = preload("res://scripts/village/house_haze.gdshader")
const FRAME := Vector2i(1024, 307)
const POSES := 5

# The cloth, traced out of the artwork: for each column, where the banner's top
# and bottom edge sit inside a frame. The banner waves, so a single quad would
# bend the writing across its diagonal seam — the same fault the Mirror had. One
# strip per pair of columns keeps the line of text riding the wave.
const CLOTH := [
	Vector3(600, 211, 266), Vector3(614, 212, 268), Vector3(628, 215, 269),
	Vector3(641, 217, 271), Vector3(655, 220, 273), Vector3(669, 223, 276),
	Vector3(682, 226, 269), Vector3(696, 228, 280), Vector3(710, 231, 283),
	Vector3(724, 232, 286), Vector3(738, 234, 287), Vector3(751, 236, 283),
	Vector3(765, 236, 290), Vector3(779, 236, 289), Vector3(792, 234, 288),
	Vector3(806, 232, 285), Vector3(820, 232, 282), Vector3(834, 229, 278),
	Vector3(848, 225, 276), Vector3(861, 222, 275), Vector3(875, 219, 272),
	Vector3(889, 215, 271), Vector3(902, 212, 268), Vector3(916, 210, 267),
	Vector3(930, 209, 266),
]

const GLASS := Vector2(660, 110)   # the viewport the banner text is written into
const BEAT := 0.17                 # seconds a wing pose is held
const DRIFT := 74.0                # how fast it crosses the kingdom

var message := "STRONG KING. KIND HAND."
var art_scale := 0.46
var sprite: Sprite2D
var banner: Polygon2D
var viewport: SubViewport
var falling := false

var _pose := 0.0
var _drop := 0.0
var _tilt := 0.0

func _ready() -> void:
	# Behind the terrain, which sits at -9, and in front of the far landscape
	# bands at -20. That one number is the whole shoot-down: a falling dragon
	# simply sinks behind the plateau, with nothing to clip or mask.
	z_index = -10
	z_as_relative = false
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = Rect2(0, 0, FRAME.x, FRAME.y)
	atlas.filter_clip = true
	sprite = Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.scale = Vector2.ONE * art_scale
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)
	_write_banner()
	_haze(sprite)
	_haze(banner)
	# Layer 16 is what a round looks for besides the world itself, so the dragon
	# can be hit without the rubble on layer 8 colliding with it in mid air.
	var hit := StaticBody2D.new()
	hit.name = "Hitbox"
	hit.collision_layer = 16
	hit.collision_mask = 0
	hit.set_meta("structure_owner", self)
	var shape := CollisionShape2D.new()
	var box := RectangleShape2D.new()
	box.size = Vector2(430, 150) * art_scale
	shape.shape = box
	shape.position = Vector2(230, 150) * art_scale
	hit.add_child(shape)
	add_child(hit)

func _process(delta: float) -> void:
	_pose += delta
	var pose := int(_pose / BEAT) % POSES
	sprite.texture.region = Rect2(0, pose * FRAME.y, FRAME.x, FRAME.y)
	if falling:
		# It never crashes in view. It loses the air, slews over, and goes down
		# behind the plateau.
		_drop = minf(_drop + 520.0 * delta, 760.0)
		_tilt = minf(_tilt + 0.9 * delta, 0.62)
		rotation = _tilt
		position += Vector2(DRIFT * 0.45, _drop) * delta
		if position.y > 1100.0:
			queue_free()
		return
	position.x += DRIFT * delta
	# A slow rise and fall, so it reads as flying rather than sliding.
	position.y += sin(_pose * 0.8) * 7.0 * delta
	if position.x > preload("res://scripts/world/terraces.gd").WORLD_WIDTH + 700.0:
		queue_free()

# A round in the banner takes the dragon down. There is no partial damage: a
# flying thing is either flying or it is not.
func apply_explosion_damage(_amount: int, _source: Vector2, _ratio := 1.0, _radius := 155.0, _heading := Vector2.ZERO, _cascade := true) -> void:
	if falling:
		return
	falling = true
	get_node("Hitbox").collision_layer = 0
	EventBus.world_event.emit({
		"type": "PROPAGANDA_DRAGON_DOWNED",
		"target": "PropagandaDragon",
		"message": message,
		"position": global_position,
		"narrative_value": 0.6,
	})

func say(text: String) -> void:
	message = text
	if viewport != null:
		viewport.get_node("Line").text = text

func _write_banner() -> void:
	viewport = SubViewport.new()
	viewport.size = GLASS
	viewport.transparent_bg = true
	viewport.disable_3d = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(viewport)
	var line := Label.new()
	line.name = "Line"
	line.size = GLASS
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	line.add_theme_font_size_override("font_size", 46)
	line.add_theme_color_override("font_color", Color("23304a"))
	line.text = message
	viewport.add_child(line)
	banner = Polygon2D.new()
	banner.texture = viewport.get_texture()
	banner.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var points := PackedVector2Array()
	var mapping := PackedVector2Array()
	var faces := []
	var span: float = CLOTH[CLOTH.size() - 1].x - CLOTH[0].x
	for i in CLOTH.size():
		var column: Vector3 = CLOTH[i]
		var along: float = (column.x - CLOTH[0].x) / span
		# Pulled a little inside the cloth so the writing never touches the hem.
		var top: float = lerpf(column.y, column.z, 0.14)
		var bottom: float = lerpf(column.y, column.z, 0.86)
		points.append(Vector2(column.x, top) * art_scale)
		mapping.append(Vector2(GLASS.x * along, 0.0))
		points.append(Vector2(column.x, bottom) * art_scale)
		mapping.append(Vector2(GLASS.x * along, GLASS.y))
	for i in CLOTH.size() - 1:
		faces.append(PackedInt32Array([i * 2, i * 2 + 2, i * 2 + 3, i * 2 + 1]))
	banner.polygon = points
	banner.uv = mapping
	banner.polygons = faces
	add_child(banner)

func _haze(item: CanvasItem) -> void:
	var material := ShaderMaterial.new()
	material.shader = HAZE
	# Heavier than the far factories carry: it belongs to the sky, not the street.
	material.set_shader_parameter("haze_amount", 0.22)
	item.material = material
