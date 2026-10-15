extends RigidBody2D

const Terraces = preload("res://scripts/world/terraces.gd")

@export var impact_severity := 0.25
@export var narrative_value := 0.1
@export var impact_effect_scene: PackedScene
@export var explosion_scene: PackedScene

var weapon := "Basic"
var _age := 0.0

var _has_impacted := false

func _ready() -> void:
	add_to_group("active_projectiles")
	# Rounds carry a layer of their own. Left on the default they share one with the
	# terrain they are meant to hit, so two in flight collide with each other and
	# both go off in the open sky.
	collision_layer = 2
	# Terrain and masonry only. Rubble is scenery, not a target: with the debris
	# layer in here a round detonates in mid air on whatever the last one threw up.
	# A blast still stirs any rubble inside its radius, so nothing is lost.
	collision_mask = 1 | 16
	if weapon == "Basic":
		mass = 6.0
		linear_damp = 0.0
	else:
		# A flash that bursts on a roof reaches nobody: the people it is meant for are
		# in the street. So it collides with nothing at all and goes off when it
		# crosses the line the kingdom walks on, wherever that is — over a house, in
		# front of it, behind it. Where it bursts is where it was aimed, which is what
		# an aimed non-lethal round has to be.
		collision_layer = 32
		collision_mask = 0
	continuous_cd = RigidBody2D.CCD_MODE_CAST_SHAPE
	body_entered.connect(_on_body_entered)


# A flash has nothing to hit, so it reports the ground it reached rather than a
# building it struck.
func _burst_on_the_street() -> void:
	_has_impacted = true
	EventBus.emit_projectile_impacted({
		"type": "PROJECTILE_IMPACTED",
		"cause": "knight",
		"target": "Street",
		"part": "street",
		"position": global_position,
		"severity": impact_severity,
		"narrative_value": narrative_value,
	})
	EventBus.emit_camera_shake_requested(2.0, 0.08)
	_spawn_impact_effect()
	_spawn_explosion()
	# The dazzle is on the screen, not in the world: whoever is watching took it in
	# the eyes too.
	var dazzle := CanvasLayer.new()
	dazzle.name = "FlashDazzle"
	dazzle.set_script(preload("res://scripts/effects/flash_dazzle.gd"))
	get_tree().current_scene.add_child(dazzle)
	queue_free()


func _on_body_entered(body: Node) -> void:
	if _has_impacted:
		return

	_has_impacted = true
	var structure = body.get_meta("structure_owner", body)
	EventBus.emit_projectile_impacted({
		"type": "PROJECTILE_IMPACTED",
		"cause": "knight",
		"target": structure.name,
		"part": str(body.name),
		"position": global_position,
		"severity": impact_severity,
		"narrative_value": narrative_value,
	})
	# The cannonball detonates on contact. Masonry is broken by the blast's local
	# energy, never by the solver passing the ball's momentum down the building.
	EventBus.emit_camera_shake_requested(5.0, 0.16)


	_spawn_impact_effect()
	_spawn_explosion()
	queue_free()


func _spawn_impact_effect() -> void:
	if impact_effect_scene == null:
		return

	var effect := impact_effect_scene.instantiate() as Node2D
	effect.global_position = global_position
	get_tree().current_scene.add_child(effect)


func _spawn_explosion() -> void:
	if explosion_scene == null:
		return

	var explosion := explosion_scene.instantiate() as Node2D
	explosion.weapon = weapon
	# The round's own line decides which way the cratered masonry is thrown.
	explosion.heading = linear_velocity.normalized()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)


func _physics_process(delta: float) -> void:
	_age += delta
	# A flash collides with nothing, so nothing tells it when to go off: it watches
	# for the street itself, at whatever height the terrace sits under it.
	if weapon == "Flash" and not _has_impacted \
		and global_position.y >= Terraces.walking_y(global_position.x):
		_burst_on_the_street()
		return
	if _age > 15.0 or global_position.y > 1200.0 or global_position.x < -600.0 or global_position.x > 8200.0:
		queue_free()
