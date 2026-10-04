extends Node2D

enum State { READY, FLYING, DORMANT, LIVE, RETURNING, COOLDOWN }
var state := State.READY
var targets: Array[Node2D] = []
var selected := 0
var awareness := 0.0
var cooldown := 0.0
var ended := false
var mirror: Node2D
var knight: Node2D
var broadcast: Node2D
var bird: Sprite2D
var frames: Array[AtlasTexture] = []
var clock := 0.0
var tip := "T: marcar alvo sob o cursor · P: enviar Pigeon"
var live_view: SubViewport
var live_camera: Camera2D

func _ready() -> void:
	mirror = get_parent().get_node("Structures/Mirror")
	knight = get_parent().get_node("Knight")
	broadcast = mirror.get_node("Broadcast")
	var boxes: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/characters/pigeon.json"))
	for box in boxes:
		var frame := AtlasTexture.new()
		frame.atlas = preload("res://assets/characters/pigeon.png")
		frame.region = Rect2(box[0],box[1],box[2],box[3])
		frame.filter_clip = true
		frames.append(frame)
	bird = Sprite2D.new()
	bird.texture = frames[0]
	bird.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	bird.z_index = 10
	bird.position = home()
	add_child(bird)
	live_view = SubViewport.new()
	live_view.size = Vector2i(640,360)
	live_view.world_2d = get_viewport().world_2d
	live_view.canvas_cull_mask = 1 # Exclude the mirror display, avoiding recursive video.
	live_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(live_view)
	live_camera = Camera2D.new()
	live_view.add_child(live_camera)
	EventBus.intervention_ended.connect(_intervention_ended)

func home() -> Vector2:
	return knight.position+Vector2(-24,-85)

func perch() -> Vector2:
	var art = mirror.get_node("Artwork")
	return mirror.position+Vector2(0,70-art.house_width*art.house_texture.get_height()/art.house_texture.get_width()-8)

func _process(delta: float) -> void:
	clock += delta
	_prune_targets()
	if ended and state not in [State.READY,State.RETURNING,State.COOLDOWN] and get_tree().get_nodes_in_group("active_projectiles").is_empty():
		return_home()
	if mirror._integrity <= 0 and state in [State.FLYING,State.DORMANT,State.LIVE]:
		return_home()
	match state:
		State.READY:
			bird.position = home()
		State.FLYING:
			bird.position = bird.position.move_toward(perch(),delta*1050)
			if bird.position.distance_to(perch()) < 2:
				state = State.DORMANT
				tip = "Pigeon pousado · C: conectar LIVE · T: marcar · P: recolher"
		State.DORMANT:
			bird.position = perch()
		State.LIVE:
			_update_live(delta)
		State.RETURNING:
			bird.position = bird.position.move_toward(home(),delta*1400)
			if bird.position.distance_to(home()) < 2:
				state = State.COOLDOWN
				cooldown = 12
		State.COOLDOWN:
			cooldown = maxf(0,cooldown-delta)
			if cooldown <= 0:
				state = State.READY
				tip = "T: marcar alvo sob o cursor · P: enviar Pigeon"
	var flying := state in [State.FLYING,State.RETURNING]
	bird.texture = frames[1+int(clock*10)%3] if flying else frames[0]
	var scale_value := 38.0/frames[0].get_height()
	bird.scale = Vector2.ONE*scale_value
	bird.flip_h = state == State.RETURNING
	queue_redraw()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or ended:
		return
	match event.keycode:
		KEY_T:
			if state in [State.READY,State.FLYING,State.DORMANT]:
				_mark_under_cursor()
		KEY_P:
			if state == State.READY:
				deploy()
			elif state in [State.FLYING,State.DORMANT,State.LIVE]:
				return_home()
		KEY_C:
			connect_live()
		KEY_TAB:
			if state == State.LIVE and targets.size() > 1:
				selected = (selected+1)%targets.size()
				_update_live_camera(1.0)

func mark_target(target: Node2D) -> bool:
	if state not in [State.READY,State.FLYING,State.DORMANT] or not _valid_target(target):
		return false
	if target in targets:
		targets.erase(target)
		return true
	if targets.size() >= 4:
		tip = "Até 4 alvos · T no alvo marcado remove a marca"
		return false
	targets.append(target)
	_emit("PIGEON_TARGET_MARKED",str(target.name))
	return true

func _mark_under_cursor() -> void:
	var pointer := get_global_mouse_position()
	var nearest: Node2D
	var distance := 95.0
	var candidates := get_tree().get_nodes_in_group("people") + get_tree().get_nodes_in_group("structures")
	for candidate in candidates:
		if not _valid_target(candidate):
			continue
		var point: Vector2 = candidate.closest_point(pointer) if candidate.has_method("closest_point") else candidate.global_position-Vector2(0,25)
		var d: float = pointer.distance_to(point)
		if d < distance:
			distance = d
			nearest = candidate
	if nearest:
		mark_target(nearest)
	else:
		tip = "Aponte para uma pessoa ou construção e pressione T"

func _valid_target(target: Node2D) -> bool:
	if not is_instance_valid(target) or not target.is_visible_in_tree():
		return false
	return not target.has_method("apply_explosion_damage") or target._integrity > 0

func _prune_targets() -> void:
	for i in range(targets.size()-1,-1,-1):
		if not _valid_target(targets[i]):
			targets.remove_at(i)
	selected = mini(selected,maxi(0,targets.size()-1))
	if state == State.LIVE and targets.is_empty():
		return_home()

func deploy() -> bool:
	if state != State.READY or mirror._integrity <= 0 or ended:
		return false
	if targets.is_empty():
		tip = "Marque pelo menos um alvo com T antes de enviar"
		return false
	state = State.FLYING
	awareness = 0
	tip = "Pigeon a caminho do Espelho"
	return true

func connect_live() -> bool:
	if state != State.DORMANT or targets.is_empty() or mirror._integrity <= 0:
		return false
	state = State.LIVE
	awareness = 0
	live_view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_update_live_camera(1.0)
	broadcast.begin_live(live_view.get_texture())
	_emit("PIGEON_CONNECTED","Mirror")
	_emit("LIVE_STARTED",str(targets[selected].name))
	return true

func _update_live_camera(delta: float) -> void:
	if targets.is_empty():
		return
	var target := targets[selected]
	var center := target.global_position-Vector2(0,30)
	var zoom_value := 1.8
	if target.has_node("Visual"):
		var rect: Rect2 = target.get_node("Visual").get_global_rect()
		center = rect.get_center()
		zoom_value = minf(520.0/maxf(1,rect.size.x),280.0/maxf(1,rect.size.y))
	live_camera.position = live_camera.position.lerp(center,minf(1,delta*7))
	live_camera.zoom = Vector2.ONE*zoom_value

func _update_live(delta: float) -> void:
	_update_live_camera(delta)
	var spotted := false
	for person in get_tree().get_nodes_in_group("people"):
		if person.label != "Soldier" or person.disorganized_seconds > 0 or person.fear_seconds > 0:
			continue
		if absf(person.position.x-mirror.position.x) < 700:
			person.alert_target_x = mirror.position.x
			if absf(person.position.x-mirror.position.x) < 220:
				spotted = true
	awareness = clampf(awareness+delta*(1.0/8.0 if spotted else -0.04),0,1)
	tip = "LIVE · Tab: trocar alvo · P: recolher · Atenção dos guardas %d%%" % int(awareness*100)
	if awareness >= 1:
		_emit("PIGEON_SCARED_AWAY","Pigeon")
		return_home()

func return_home() -> void:
	if state == State.LIVE:
		broadcast.end_live()
		_emit("LIVE_ENDED","Mirror")
	live_view.render_target_update_mode = SubViewport.UPDATE_DISABLED
	state = State.RETURNING
	targets.clear()
	selected = 0
	awareness = 0
	for person in get_tree().get_nodes_in_group("people"):
		person.alert_target_x = NAN
	tip = "Pigeon retornando ao Cavaleiro"

func _intervention_ended(reason: String) -> void:
	ended = true
	if reason != "ammo_empty" and state not in [State.READY,State.COOLDOWN]:
		return_home()

func _emit(type: String, target: String) -> void:
	EventBus.world_event.emit({"type":type,"target":target,"cause":"pigeon","position":bird.position,"narrative_value":0.4})

func description() -> String:
	if ended and state in [State.READY,State.COOLDOWN]:
		return "Pigeon recolhido · intervenção encerrada"
	if state == State.COOLDOWN:
		return "Pigeon descansando · %ds" % ceili(cooldown)
	return "%s · %d/4 alvos" % [tip,targets.size()]

func _draw() -> void:
	for i in targets.size():
		var target := targets[i]
		if not is_instance_valid(target):
			continue
		var point := target.global_position-Vector2(0,85)
		if target.has_node("Visual"):
			var rect: Rect2 = target.get_node("Visual").get_global_rect()
			point = Vector2(rect.get_center().x,rect.position.y-14)
		draw_arc(point,14,0,TAU,24,Color("a6f4ea") if i != selected else Color("ffe287"),2)
		draw_string(ThemeDB.fallback_font,point+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color.WHITE)
