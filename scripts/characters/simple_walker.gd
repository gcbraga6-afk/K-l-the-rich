extends CharacterBody2D

@export var speed := 70.0
var social_group := "Workers"
var social_alarm := 0.0
@export var patrol_pause := 0.0
var patrol_wait := 0.0
@export var left_x := 800.0
@export var right_x := 2200.0
@export var label := "Worker"
@export var body_color := Color(0.22, 0.19, 0.16, 1.0)
@export var head_color := Color(0.63, 0.46, 0.34, 1.0)

@onready var body: ColorRect = $Body
@onready var head: ColorRect = $Head
@onready var name_label: Label = $NameLabel

var routine_sites: Array = []
var routine_index := 0
var routine_wait := 0.0
var current_activity := "caminhando"

var fear_seconds := 0.0
var disorganized_seconds := 0.0
var _flee_direction := 1.0

var _direction := 1.0

func _ready() -> void:
	add_to_group("people")
	if label == "Soldier":
		social_group = "Soldiers"
	elif label == "King":
		social_group = "Nobility"
	global_position.y = 620.0
	collision_layer = 2
	collision_mask = 0
	name_label.text = label
	name_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	body.color = body_color
	head.color = head_color


func _physics_process(delta: float) -> void:
	social_alarm = maxf(0, social_alarm - delta)
	fear_seconds = maxf(0.0, fear_seconds - delta)
	var recovery := 1.0
	var society = get_parent().get_parent().get_node_or_null("Society")
	if label == "Soldier" and society != null:
		recovery = 0.4 + 0.6 * society.cohesion / 85.0
	disorganized_seconds = maxf(0.0, disorganized_seconds - delta * recovery)
	name_label.text = label
	if disorganized_seconds > 0.0:
		name_label.text += " · desorganizado"
		velocity.x = 0.0
	elif fear_seconds > 0.0:
		name_label.text += " · fugindo"
		velocity.x = _flee_direction * speed * 1.8
	elif not routine_sites.is_empty():
		_follow_routine(delta)
	elif patrol_wait > 0.0:
		patrol_wait = maxf(0.0, patrol_wait - delta)
		velocity.x = 0.0
	else:
		velocity.x = _direction * speed
	body.color = body_color.lerp(Color(0.8, 0.7, 0.4), 0.55) if disorganized_seconds > 0.0 else body_color
	move_and_slide()
	global_position.y = preload("res://scripts/world/terraces.gd").walking_y(global_position.x)
	global_position.x = clampf(global_position.x, 400.0, 6800.0)

	if global_position.x >= right_x and _direction > 0:
		_direction = -1.0
		patrol_wait = patrol_pause
	elif global_position.x <= left_x and _direction < 0:
		_direction = 1.0
		patrol_wait = patrol_pause

	name_label.visible = fear_seconds > 0.0 or disorganized_seconds > 0.0
	body.scale.x = _direction


func react_to_blast(source: Vector2, weapon: String) -> void:
	var distance := global_position.distance_to(source)
	var reach := 380.0 if weapon == "Flash" else 300.0
	if distance > reach:
		return
	fear_seconds = 4.0 + (1.0 - distance / reach) * 4.0
	_flee_direction = -1.0 if source.x > global_position.x else 1.0
	if label == "Soldier" and weapon == "Flash":
		disorganized_seconds = 7.0
	EventBus.world_event.emit({
		"type": "SOLDIER_DISORGANIZED" if disorganized_seconds > 0.0 else "PERSON_FRIGHTENED",
		"target": str(name), "cause": weapon, "position": global_position,
		"severity": 1.0 - distance / reach, "narrative_value": 0.3,
	})


func _follow_routine(delta: float) -> void:
	# Ruined destinations are skipped, so people do not work inside debris.
	for attempt in range(routine_sites.size()):
		var target = routine_sites[routine_index]
		if not is_instance_valid(target) or target._integrity <= 0:
			routine_index = (routine_index + 1) % routine_sites.size()
			routine_wait = 0.0
			continue
		if routine_wait > 0.0:
			routine_wait = maxf(0.0, routine_wait - delta)
			velocity.x = 0.0
			current_activity = str(target.get_meta("business", "em casa"))
			if routine_wait <= 0.0:
				routine_index = (routine_index + 1) % routine_sites.size()
			return
		var distance: float = target.global_position.x - global_position.x
		if absf(distance) < 9.0:
			routine_wait = 4.0 + float(get_index() % 4)
			velocity.x = 0.0
		else:
			_direction = signf(distance)
			velocity.x = _direction * speed
			current_activity = "caminhando"
		return
	velocity.x = 0.0
	current_activity = "sem destino"
