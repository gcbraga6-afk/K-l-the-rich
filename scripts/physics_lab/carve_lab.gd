extends Node2D

# Bench for the carved model: a real village facade that rounds tear holes in.
const Carved = preload("res://scripts/destruction/carved_facade.gd")
const FLOOR_Y := 780.0
const LAUNCH := Vector2(220, 700)
const BLAST_RADIUS := 62.0

var facade: Node2D
var camera: Camera2D
var status: Label
var dragging := false
var pull := Vector2.ZERO
var shots := 0

func _ready() -> void:
	DisplayServer.window_set_title("Teste — buraco de bomba na casa")
	RenderingServer.set_default_clear_color(Color("8fb4d8"))
	camera = Camera2D.new()
	camera.position = Vector2(760, 500)
	add_child(camera)
	get_viewport().size_changed.connect(_fit)
	_fit()
	var ground := StaticBody2D.new()
	ground.position = Vector2(900, FLOOR_Y + 60)
	var collider := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(3400, 120)
	collider.shape = shape
	ground.add_child(collider)
	add_child(ground)
	_make_ui()
	_build()

func _fit() -> void:
	var view := get_viewport_rect().size
	camera.zoom = Vector2.ONE * minf(view.x / 1500.0, view.y / 980.0)

func _build() -> void:
	if facade != null:
		facade.queue_free()
	shots = 0
	facade = Node2D.new()
	facade.set_script(Carved)
	facade.position = Vector2(820, 0)
	add_child(facade)
	var catalog = load("res://scripts/village/house_catalog.gd")
	facade.setup(catalog.house(2), 430.0, FLOOR_Y)

func fire(velocity: Vector2) -> RigidBody2D:
	var ball := RigidBody2D.new()
	ball.position = LAUNCH
	ball.mass = 10
	ball.linear_velocity = velocity.limit_length(1700)
	ball.continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	ball.contact_monitor = true
	ball.max_contacts_reported = 4
	ball.collision_layer = 2
	ball.collision_mask = 1
	ball.z_as_relative = false
	ball.z_index = 6
	var shape := CircleShape2D.new()
	shape.radius = 15
	var collider := CollisionShape2D.new()
	collider.shape = shape
	ball.add_child(collider)
	var visual := Polygon2D.new()
	var circle := PackedVector2Array()
	for i in range(28):
		circle.append(Vector2.RIGHT.rotated(i * TAU / 28) * 15)
	visual.polygon = circle
	visual.color = Color("2b2420")
	ball.add_child(visual)
	ball.body_entered.connect(_on_hit.bind(ball))
	add_child(ball)
	shots += 1
	return ball

func _on_hit(_body: Node, ball: RigidBody2D) -> void:
	if not is_instance_valid(ball) or ball.has_meta("spent"):
		return
	ball.set_meta("spent", true)
	facade.carve(ball.global_position, BLAST_RADIUS)
	ball.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_R:
			_build()
		elif event.keycode == KEY_SPACE:
			fire(Vector2(1150, -210))
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and get_global_mouse_position().distance_to(LAUNCH) < 90:
			dragging = true
			pull = Vector2.ZERO
		elif not event.pressed and dragging:
			dragging = false
			if pull.length() > 15:
				fire(pull * 7.0)
	if event is InputEventMouseMotion and dragging:
		pull = (LAUNCH - get_global_mouse_position()).limit_length(240)

func _process(_delta: float) -> void:
	if is_instance_valid(facade):
		status.text = "Tiros: %d   ·   Parede de pé: %d%%" % [shots, int(facade.standing_ratio() * 100)]
	queue_redraw()

func _make_ui() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.position = Vector2(24, 24)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("24364a")
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 9)
	panel.add_child(column)
	var title := Label.new()
	title.text = "BURACO DE BOMBA — a casa continua de pé"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	var help := Label.new()
	help.text = "Arraste a bala e solte, ou Espaço. R reconstrói.\nAtire várias vezes no mesmo lado e veja a parte sem apoio cair sozinha."
	help.add_theme_font_size_override("font_size", 18)
	column.add_child(help)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 17)
	column.add_child(status)

func _draw() -> void:
	draw_rect(Rect2(-600, FLOOR_Y, 3400, 400), Color("6d7a52"))
	draw_line(Vector2(-600, FLOOR_Y), Vector2(2800, FLOOR_Y), Color("8a9668"), 3)
	draw_circle(LAUNCH, 15, Color("2b2420"))
	draw_arc(LAUNCH, 28, 0, TAU, 40, Color("2b2420"), 2, true)
	if dragging:
		draw_line(LAUNCH, LAUNCH - pull, Color("d8cdb5"), 3, true)
		var velocity := pull * 7.0
		for i in range(1, 26):
			var t := float(i) * 0.045
			var point := LAUNCH + velocity * t + Vector2(0, 980.0 * t * t / 2)
			if point.y > FLOOR_Y:
				break
			draw_circle(point, 2, Color("e8ddc6"))
