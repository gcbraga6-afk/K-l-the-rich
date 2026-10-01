extends CharacterBody2D

@export var speed := 70.0
@export var left_x := 800.0
@export var right_x := 2200.0
@export var label := "Worker"
@export var body_color := Color(0.22, 0.19, 0.16, 1.0)
@export var head_color := Color(0.63, 0.46, 0.34, 1.0)

@onready var body: ColorRect = $Body
@onready var head: ColorRect = $Head
@onready var name_label: Label = $NameLabel

var _direction := 1.0

func _ready() -> void:
	name_label.text = label
	body.color = body_color
	head.color = head_color


func _physics_process(delta: float) -> void:
	velocity.x = _direction * speed
	move_and_slide()

	if global_position.x >= right_x:
		_direction = -1.0
	elif global_position.x <= left_x:
		_direction = 1.0

	body.scale.x = _direction
