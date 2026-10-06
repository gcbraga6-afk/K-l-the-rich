extends Node2D

# Propaganda that comes to the player instead of waiting for him.
#
# The Mirror stands in one place, and a player who never walks that far never
# hears the Kingdom speak. A dragon crosses the sky with the Crown's banner, back
# behind the village, hazed into the distance. It can be shot down, and when it
# falls it goes down behind the plateau: no wreck to simulate, no body on the
# street, just the Kingdom's voice dropping out of the sky.

const SHEET = preload("res://assets/propaganda/dragon_banner_blank.png")
const FALLING_SHEET = preload("res://assets/propaganda/dragon_banner_falling.png")
const HAZE = preload("res://scripts/village/house_haze.gdshader")
# The two sheets are cut differently. The flying one was rebuilt so every frame
# holds the banner at the same height — drawn as generated, its frames straddled
# the grid and the neighbour's wing bled into view. The falling sheet keeps the
# grid it was drawn on.
const FRAME := Vector2i(1024, 352)
const FALL_FRAME := Vector2i(1024, 307)
const POSES := 5

# The cloth, traced out of the artwork: for each column, where the banner's top
# and bottom edge sit inside a frame. The banner waves, so a single quad would
# bend the writing across its diagonal seam — the same fault the Mirror had. One
# strip per pair of columns keeps the line of text riding the wave.
const CLOTH := [
	Vector3(578,192,232), Vector3(593,186,241), Vector3(609,187,243), Vector3(624,190,245),
	Vector3(640,193,247), Vector3(655,195,249), Vector3(670,197,252), Vector3(686,202,252),
	Vector3(701,204,256), Vector3(716,207,260), Vector3(732,208,263), Vector3(747,210,263),
	Vector3(762,211,266), Vector3(778,211,265), Vector3(793,210,264), Vector3(809,207,261),
	Vector3(824,205,258), Vector3(839,202,255), Vector3(855,198,252), Vector3(870,195,250),
	Vector3(886,191,247), Vector3(901,188,245), Vector3(916,186,243), Vector3(932,185,242),
	Vector3(947,199,232),
]

# The falling poses are drawn art, not the flying dragon rotated, so the banner
# swings to a different place in every one of them. One traced outline per pose,
# and the cloth is rebuilt as the pose changes.
const FALL_CLOTH := [
	[Vector3(602,94,136), Vector3(629,81,133), Vector3(656,84,138), Vector3(683,92,148), Vector3(710,108,164), Vector3(737,140,180), Vector3(764,143,195), Vector3(790,150,202), Vector3(817,152,205), Vector3(844,146,201), Vector3(871,133,191), Vector3(898,121,179), Vector3(925,142,171)],
	[Vector3(613,104,133), Vector3(640,77,131), Vector3(667,81,135), Vector3(694,91,146), Vector3(721,105,161), Vector3(748,120,180), Vector3(775,132,192), Vector3(801,139,197), Vector3(828,137,195), Vector3(855,131,187), Vector3(882,123,177), Vector3(909,115,169), Vector3(936,131,166)],
	[Vector3(610,76,118), Vector3(637,63,118), Vector3(664,68,125), Vector3(690,81,139), Vector3(717,103,145), Vector3(744,132,187), Vector3(770,144,201), Vector3(797,150,206), Vector3(824,145,203), Vector3(851,133,191), Vector3(878,124,179), Vector3(904,119,171), Vector3(931,139,171)],
	[Vector3(610,54,99), Vector3(636,43,103), Vector3(662,48,106), Vector3(688,63,121), Vector3(714,90,138), Vector3(740,121,188), Vector3(766,145,208), Vector3(793,158,216), Vector3(819,160,216), Vector3(845,152,209), Vector3(871,140,197), Vector3(897,132,186), Vector3(923,151,180)],
	[Vector3(618,109,138), Vector3(644,80,135), Vector3(670,75,132), Vector3(697,75,135), Vector3(723,85,143), Vector3(749,104,157), Vector3(776,137,180), Vector3(802,152,198), Vector3(828,155,203), Vector3(854,143,198), Vector3(880,124,185), Vector3(907,112,171), Vector3(933,134,167)],
]

const GLASS := Vector2(660, 110)   # the viewport the banner text is written into
const BEAT := 0.17                 # seconds a wing pose is held
# The dragon is drawn facing left, with the banner trailing away to the right, so
# it travels left. Sent the other way it flew backwards, towing its own banner
# ahead of it.
const DRIFT := -74.0               # how fast it crosses the kingdom, and which way

var message := "STRONG KING. KIND HAND."
var art_scale := 0.92
var sprite: Sprite2D
var banner: Polygon2D
var viewport: SubViewport
var falling := false

var _pose := 0.0
var _drop := 0.0
var _shown := -1   # which falling pose the banner is currently cut for

func _ready() -> void:
	add_to_group("propaganda_dragons")
	# Out at the depth of the far landscape, so it passes behind the tree line. The
	# bands sit there too, and the sky node inserts the dragon between the valley
	# and the woodland, so the trees cross in front of it while the mountains stay
	# behind. It is also behind the terrain at -9, which is the whole shoot-down: a
	# falling dragon simply sinks behind the plateau, with nothing to clip or mask.
	z_index = -20
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
	var cell: Vector2i = FALL_FRAME if falling else FRAME
	sprite.texture.region = Rect2(0, pose * cell.y, cell.x, cell.y)
	if falling:
		# It never crashes in view. It loses the air and goes down behind the
		# plateau. The tumble is drawn, not a rotation applied to the flying pose,
		# so the banner is re-cut to follow the cloth in each falling frame.
		if pose != _shown:
			_shown = pose
			_cut_cloth(FALL_CLOTH[pose])
		_drop = minf(_drop + 520.0 * delta, 760.0)
		position += Vector2(DRIFT * 0.45, _drop) * delta
		if position.y > 1100.0:
			queue_free()
		return
	if _shown != -1:
		_shown = -1
	position.x += DRIFT * delta
	# A slow rise and fall, so it reads as flying rather than sliding.
	position.y += sin(_pose * 0.8) * 7.0 * delta
	if position.x < -1500.0:
		queue_free()

# A round in the banner takes the dragon down. There is no partial damage: a
# flying thing is either flying or it is not.
func apply_explosion_damage(_amount: int, _source: Vector2, _ratio := 1.0, _radius := 155.0, _heading := Vector2.ZERO, _cascade := true) -> void:
	if falling:
		return
	falling = true
	_pose = 0.0
	sprite.texture.atlas = FALLING_SHEET
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
	add_child(banner)
	_cut_cloth(CLOTH)


# Lays the written banner over one traced outline of the cloth.
func _cut_cloth(cloth: Array) -> void:
	var points := PackedVector2Array()
	var mapping := PackedVector2Array()
	var faces := []
	var span: float = cloth[cloth.size() - 1].x - cloth[0].x
	for i in cloth.size():
		var column: Vector3 = cloth[i]
		var along: float = (column.x - cloth[0].x) / span
		# Pulled a little inside the cloth so the writing never touches the hem.
		var top: float = lerpf(column.y, column.z, 0.14)
		var bottom: float = lerpf(column.y, column.z, 0.86)
		points.append(Vector2(column.x, top) * art_scale)
		mapping.append(Vector2(GLASS.x * along, 0.0))
		points.append(Vector2(column.x, bottom) * art_scale)
		mapping.append(Vector2(GLASS.x * along, GLASS.y))
	for i in cloth.size() - 1:
		faces.append(PackedInt32Array([i * 2, i * 2 + 2, i * 2 + 3, i * 2 + 1]))
	banner.polygon = points
	banner.uv = mapping
	banner.polygons = faces

func _haze(item: CanvasItem) -> void:
	var material := ShaderMaterial.new()
	material.shader = HAZE
	# Heavier than the far factories carry: it belongs to the sky, not the street.
	material.set_shader_parameter("haze_amount", 0.22)
	item.material = material
