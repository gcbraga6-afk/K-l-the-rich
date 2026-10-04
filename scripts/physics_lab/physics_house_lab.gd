extends Node2D

const Piece = preload("res://scripts/physics_lab/physical_piece.gd")
const FLOOR_Y := 800.0
const LAUNCH := Vector2(230,720)
const GRAVITY := 980.0
var pieces: Array[RigidBody2D] = []
var projectiles: Array[RigidBody2D] = []
var container: Node2D
var camera: Camera2D
var dragging := false
var pull := Vector2.ZERO
var status: Label
var settling := 0.0
var shot_count := 0
var resetting := false

func _ready() -> void:
	DisplayServer.window_set_title("Teste de física — casa com peças reais")
	Engine.physics_ticks_per_second = 120
	RenderingServer.set_default_clear_color(Color("172333"))
	camera = Camera2D.new()
	camera.position = Vector2(880,500)
	add_child(camera)
	get_viewport().size_changed.connect(_fit_camera)
	_fit_camera()
	var ground := StaticBody2D.new()
	ground.position = Vector2(1800,FLOOR_Y+50)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(5600,100)
	collider.shape = shape
	ground.add_child(collider)
	var material := PhysicsMaterial.new()
	material.friction = 0.8
	material.bounce = 0.02
	ground.physics_material_override = material
	add_child(ground)
	_make_ui()
	_build_house()

func _fit_camera() -> void:
	var view := get_viewport_rect().size
	camera.zoom = Vector2.ONE*minf(view.x/1760.0,view.y/990.0)

func _build_house() -> void:
	container = Node2D.new()
	container.name = "PhysicalHouse"
	add_child(container)
	pieces.clear()
	projectiles.clear()
	shot_count = 0
	settling = 1.5
	for side in range(2):
		for row in range(5):
			var name := "%sWall%d" % ["Left" if side == 0 else "Right",row]
			_box(name,Vector2(1060+240*side,FLOOR_Y-24-row*48),Vector2(48,48),6,Color("a9b7bd") if row%2 == 0 else Color("94a5af"),"stone")
	_box("LoadBeam",Vector2(1180,548),Vector2(340,24),5,Color("b38552"),"wood")
	_polygon("RoofLeft",PackedVector2Array([Vector2(1010,536),Vector2(1180,402),Vector2(1180,536)]),5,Color("568ba8"),"roof")
	_polygon("RoofRight",PackedVector2Array([Vector2(1180,402),Vector2(1350,536),Vector2(1180,536)]),5,Color("44738f"),"roof")

func _box(id: String, at: Vector2, size: Vector2, weight: float, color: Color, type: String) -> void:
	_polygon(id,PackedVector2Array([at-size/2,at+Vector2(size.x/2,-size.y/2),at+size/2,at+Vector2(-size.x/2,size.y/2)]),weight,color,type)

func _polygon(id: String, vertices: PackedVector2Array, weight: float, color: Color, type: String) -> void:
	var center := Vector2.ZERO
	for point in vertices:
		center += point
	center /= vertices.size()
	var local := PackedVector2Array()
	for point in vertices:
		local.append(point-center)
	var body := RigidBody2D.new()
	body.name = id
	body.set_script(Piece)
	body.position = center
	body.mass = weight
	body.outline = local
	body.tint = color
	body.material_kind = type
	var material := PhysicsMaterial.new()
	material.friction = 0.68 if type == "stone" else 0.55
	material.bounce = 0.02
	body.physics_material_override = material
	var collider := CollisionShape2D.new()
	var shape := ConvexPolygonShape2D.new()
	shape.points = local
	collider.shape = shape
	body.add_child(collider)
	container.add_child(body)
	pieces.append(body)

func fire(velocity: Vector2) -> RigidBody2D:
	if resetting or settling > 0:
		return null
	var ball := RigidBody2D.new()
	ball.name = "Cannonball%d" % shot_count
	ball.position = LAUNCH
	ball.mass = 14
	ball.linear_velocity = velocity.limit_length(1700)
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	ball.linear_damp = 0
	ball.angular_damp = 0.1
	var material := PhysicsMaterial.new()
	material.friction = 0.6
	material.bounce = 0.07
	ball.physics_material_override = material
	var shape := CircleShape2D.new()
	shape.radius = 19
	var collider := CollisionShape2D.new()
	collider.shape = shape
	ball.add_child(collider)
	var visual := Polygon2D.new()
	var circle := PackedVector2Array()
	for i in range(32):
		circle.append(Vector2.RIGHT.rotated(i*TAU/32)*19)
	visual.polygon = circle
	visual.color = Color("edb868")
	ball.add_child(visual)
	container.add_child(ball)
	projectiles.append(ball)
	shot_count += 1
	return ball

func reset_house() -> void:
	if resetting:
		return
	resetting = true
	dragging = false
	container.queue_free()
	await get_tree().physics_frame
	await get_tree().process_frame
	_build_house()
	resetting = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			reset_house()
		elif event.keycode == KEY_SPACE:
			fire(Vector2(1250,-280))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and settling <= 0 and get_global_mouse_position().distance_to(LAUNCH) < 85:
			dragging = true
			pull = Vector2.ZERO
		elif not event.pressed and dragging:
			dragging = false
			if pull.length() > 15:
				fire(pull*7.0)
	if event is InputEventMouseMotion and dragging:
		pull = (LAUNCH-get_global_mouse_position()).limit_length(240)

func _process(delta: float) -> void:
	settling = maxf(0,settling-delta)
	var resting := 0
	for part in pieces:
		if is_instance_valid(part) and part.sleeping:
			resting += 1
	status.text = "Acomodando as peças…" if settling > 0 else "Tiros: %d · Peças apoiadas: %d/%d" % [shot_count,resting,pieces.size()]
	queue_redraw()

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24,24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("24364a")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel",style)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",9)
	panel.add_child(column)
	var title := Label.new()
	title.text = "CASA FÍSICA — TESTE DE IMPACTO"
	title.add_theme_font_size_override("font_size",24)
	column.add_child(title)
	var help := Label.new()
	help.text = "Arraste a bola para trás e solte. As peças têm peso e colidem entre si.\nEspaço: tiro na base da parede · R: reconstruir"
	help.add_theme_font_size_override("font_size",18)
	column.add_child(help)
	status = Label.new()
	status.add_theme_font_size_override("font_size",17)
	column.add_child(status)
	var controls := HBoxContainer.new()
	column.add_child(controls)
	var shoot := Button.new()
	shoot.text = "Atirar na base"
	shoot.pressed.connect(func(): fire(Vector2(1250,-280)))
	controls.add_child(shoot)
	var reset := Button.new()
	reset.text = "Reconstruir"
	reset.pressed.connect(reset_house)
	controls.add_child(reset)

func _draw() -> void:
	draw_rect(Rect2(-1000,FLOOR_Y,5600,1200),Color("34453b"))
	draw_line(Vector2(-1000,FLOOR_Y),Vector2(4600,FLOOR_Y),Color("b4c8ab"),3)
	for x in range(0,1800,100):
		draw_line(Vector2(x,FLOOR_Y+8),Vector2(x,FLOOR_Y+18),Color("728273"),1)
	draw_arc(LAUNCH,30,0,TAU,48,Color("edb868"),2,true)
	draw_circle(LAUNCH,19,Color("edb868"))
	if dragging:
		draw_line(LAUNCH,LAUNCH-pull,Color("f4d5a3"),3,true)
		var velocity := pull*7.0
		for i in range(1,25):
			var time := float(i)*0.045
			var point := LAUNCH+velocity*time+Vector2(0,GRAVITY*time*time/2)
			if point.y > FLOOR_Y:
				break
			draw_circle(point,2,Color("adbdcb"))
