extends CanvasLayer

@onready var ammo_label: Label = $AmmoLabel
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.intervention_ended.connect(_on_intervention_ended)
	status_label.visible = false


func _on_ammo_changed(current: int, maximum: int) -> void:
	ammo_label.text = "Ammo %d/%d" % [current, maximum]


func _on_intervention_ended(reason: String) -> void:
	status_label.visible = true
	match reason:
		"ammo_empty":
			status_label.text = "Intervention ended: no ammo"
		_:
			status_label.text = "Intervention ended"
