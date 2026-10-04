extends CanvasLayer

@onready var ammo_label: Label = $AmmoLabel
@onready var status_label: Label = $StatusLabel
var weapon := "Basic"
var ammo := 8
var maximum := 8
var history: Array[String] = []
var event_label: Label
var social_label: Label

func _ready() -> void:
	EventBus.ammo_changed.connect(_on_ammo_changed)
	EventBus.intervention_ended.connect(_on_intervention_ended)
	EventBus.weapon_changed.connect(_on_weapon_changed)
	EventBus.world_event.connect(_on_world_event)
	status_label.visible = false
	var panel := Panel.new()
	panel.position = Vector2(14, 12)
	panel.size = Vector2(660, 78)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.09, 0.13, 0.14, 0.86)
	style.border_color = Color("b39a63")
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	move_child(panel, 0)
	ammo_label.position = Vector2(30, 20)
	status_label.position = Vector2(30, 56)
	status_label.add_theme_font_size_override("font_size", 16)
	var help := Label.new()
	help.position = Vector2(24, get_viewport().get_visible_rect().size.y - 72)
	help.add_theme_color_override("font_shadow_color", Color.BLACK)
	help.add_theme_constant_override("shadow_offset_x", 2)
	help.add_theme_constant_override("shadow_offset_y", 2)
	help.text = "Arraste para trás junto ao canhão e solte para disparar\nApós disparar, clique para voltar ao cavaleiro · A/D: lados · W/S: altura   Home: canhão   V: vila   M: espelho   1: Basic   2: Flash   Esc: retirar-se"
	help.add_theme_font_size_override("font_size", 18)
	add_child(help)
	event_label = Label.new()
	event_label.position = Vector2(24, 106)
	event_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	event_label.add_theme_constant_override("shadow_offset_x", 2)
	event_label.add_theme_constant_override("shadow_offset_y", 2)
	event_label.add_theme_font_size_override("font_size", 16)
	add_child(event_label)
	social_label = Label.new()
	social_label.position = Vector2(710, 20)
	social_label.add_theme_font_size_override("font_size", 18)
	social_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	social_label.add_theme_constant_override("shadow_offset_x", 2)
	social_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(social_label)

func _process(_delta: float) -> void:
	var society = get_parent().get_node_or_null("Society")
	if society == null or social_label == null:
		return
	var mood := "tranquila" if society.fear < 5 else ("apreensiva" if society.fear < 25 else "assustada")
	var guards := "organizados" if society.cohesion > 60 else ("abalados" if society.cohesion > 30 else "desorganizados")
	social_label.text = "População: %s · Guardas: %s" % [mood, guards]

func _on_ammo_changed(current: int, total: int) -> void:
	ammo = current
	maximum = total
	ammo_label.text = "%s · Munição %d/%d" % [weapon, ammo, maximum]

func _on_weapon_changed(selected: String) -> void:
	weapon = selected
	_on_ammo_changed(ammo, maximum)

func _on_intervention_ended(reason: String) -> void:
	status_label.visible = true
	status_label.text = "Sem munição. O Reino continua — observe as consequências." if reason == "ammo_empty" else "Você se retirou. O Reino continua."

func _on_world_event(event: Dictionary) -> void:
	if event.get("type") == "PROPAGANDA_BROADCAST":
		history.push_front("Espelho: " + event.get("message", ""))
		if history.size() > 5:
			history.pop_back()
		event_label.text = "\n".join(history)
		return
	var descriptions := {
		"WORKPLACE_CLOSED": "fechou; moradores procuram outro destino",
		"STRUCTURE_HIT": "foi atingido",
		"STRUCTURE_DESTROYED": "virou ruínas",
		"PERSON_FRIGHTENED": "fugiu do impacto",
		"SOLDIER_DISORGANIZED": "perdeu a formação",
	}
	history.push_front("%s — %s" % [event.target, descriptions.get(event.type, event.type)])
	if history.size() > 5:
		history.pop_back()
	event_label.text = "\n".join(history)
