extends RigidBody2D

# One piece of broken stone. It inherits the velocity of the masonry it came
# from, tumbles briefly, raises dust where it lands and then freezes into
# scenery. Stone does not bounce and does not roll far.
#
# A shard travelling fast damages whatever building it reaches, so a round can
# throw rubble into the house next door.

const DustPuff = preload("res://scripts/destruction/dust_puff.gd")
const Fracture = preload("res://scripts/destruction/fracture.gd")

const MAX_GENERATION := 2       # how many times stone may be broken down again
const MIN_SHATTER_AREA := 260.0 # below this a shard is gravel: it scatters, never splits

var owner_structure: Node = null
var tint := Color("9d9280")
var shard := PackedVector2Array()
var generation := 1
var broken := false
var show_skin := false

var _quiet := 0.0
var _age := 0.0
var _peak := 0.0
var _struck := {}
var _landed := false

func _ready() -> void:
	add_to_group("stone_shards")
	# Shards are small, slow and numerous. Shape-cast CCD on hundreds of them
	# costs far more than the tunnelling it would prevent, and a shard that never
	# sleeps keeps the solver busy long after it has come to rest.
	continuous_cd = RigidBody2D.CCD_MODE_DISABLED
	freeze_mode = RigidBody2D.FREEZE_MODE_STATIC
	linear_damp = 0.3
	angular_damp = 2.4
	can_sleep = true
	contact_monitor = true
	max_contacts_reported = 4
	var stone := PhysicsMaterial.new()
	stone.friction = 0.95
	stone.bounce = 0.0
	physics_material_override = stone
	body_entered.connect(_on_contact)

func _physics_process(delta: float) -> void:
	_age += delta
	# Settling, not stopping dead: the piece gets heavier to move the longer it has
	# been loose, so it slides to a halt instead of twitching forever.
	linear_damp = 0.3 + _age * 0.9
	angular_damp = 2.4 + _age * 1.6
	if _age > 5.0:
		freeze = true
		set_physics_process(false)
		return
	angular_velocity = clampf(angular_velocity, -4.0, 4.0)
	var speed := linear_velocity.length()
	_peak = maxf(_peak * 0.96, speed)
	if get_contact_count() > 0:
		if not _landed and _peak > 120.0:
			_landed = true
			_raise_dust(0.45)
		if speed < 16.0 and absf(angular_velocity) < 0.15:
			_quiet += delta
		else:
			_quiet = 0.0
	else:
		_quiet = 0.0
	if _quiet > 0.9:
		freeze = true
		set_physics_process(false)
	if global_position.y > 2200.0:
		queue_free()

# Rubble is not scenery: a round landing in it wakes it, moves it, knocks dust
# off it and breaks it down further.
static func disturb_all(tree: SceneTree, center: Vector2, radius: float, strength: float) -> int:
	var touched := 0
	for node in tree.get_nodes_in_group("stone_shards"):
		var piece := node as RigidBody2D
		if not is_instance_valid(piece) or piece.broken:
			continue
		var distance := piece.global_position.distance_to(center)
		if distance > radius:
			continue
		piece.disturb(center, pow(1.0 - distance / radius, 2.0) * strength)
		touched += 1
	return touched

func disturb(center: Vector2, energy: float) -> void:
	if broken:
		return
	var away := global_position - center
	if away.length() < 1.0:
		away = Vector2.UP
	away = away.normalized()
	# Lifted as well as pushed, so a heap is thrown up and out by a blast instead of
	# being shoved along the ground.
	var thrown := (away + Vector2.UP * 0.5).normalized()
	if generation < MAX_GENERATION and energy > 0.3 and Fracture.area(shard) > MIN_SHATTER_AREA:
		_break(thrown * 520.0 * energy, to_local(center))
		return
	# Too small or too far to split: it is thrown and sheds dust instead. The
	# physics server is only touched once its query flush is over.
	_rouse.call_deferred(thrown * 470.0 * energy, energy)

func _rouse(push: Vector2, energy: float) -> void:
	freeze = false
	sleeping = false
	_quiet = 0.0
	_age = 0.0
	linear_damp = 0.3
	angular_damp = 2.4
	_landed = false
	set_physics_process(true)
	linear_velocity += push
	angular_velocity = clampf(angular_velocity + energy * 3.0, -4.0, 4.0)
	_raise_dust(clampf(energy, 0.25, 1.0))

func _break(extra: Vector2, focus_local: Vector2) -> void:
	broken = true
	_split.call_deferred(extra, focus_local)

func _split(extra: Vector2, focus_local: Vector2) -> void:
	var made: int = Fracture.scatter(get_parent(), self, {
		"polygon": shard,
		"count": 5,
		"focus": focus_local,
		"inherited": linear_velocity + extra,
		"mass": mass,
		"tint": tint,
		"structure": owner_structure,
		"generation": generation + 1,
		"skin": get_node_or_null("Skin"),
	})
	var puff := DustPuff.new()
	puff.configure(0.7, tint)
	puff.global_position = to_global(focus_local)
	get_parent().add_child(puff)
	if made == 0:
		broken = false
		return
	queue_free()

func _on_contact(body: Node) -> void:
	if not broken and _peak >= 430.0 and generation < MAX_GENERATION and Fracture.area(shard) > MIN_SHATTER_AREA:
		# Stone that slams into something breaks down rather than bouncing off.
		_break(Vector2.ZERO, Vector2.ZERO)
	if _peak < 170.0:
		return
	var hit = body.get_meta("structure_owner") if body.has_meta("structure_owner") else null
	if hit == null or hit == owner_structure or not is_instance_valid(hit):
		return
	if _struck.has(hit.get_instance_id()) or not hit.has_method("apply_explosion_damage"):
		return
	_struck[hit.get_instance_id()] = true
	# Flying rubble is a real cause of damage, not just decoration.
	hit.call_deferred("apply_explosion_damage", 1 if _peak < 520.0 else 2, global_position, 0.5, 90.0, Vector2.ZERO, false)

func _raise_dust(strength: float) -> void:
	var puff := DustPuff.new()
	puff.configure(strength, tint)
	puff.global_position = global_position
	get_parent().add_child(puff)

func _draw() -> void:
	# A piece carrying real paint draws that instead of a flat silhouette.
	if show_skin or shard.size() < 3:
		return
	draw_colored_polygon(shard, tint)
	var border := shard.duplicate()
	border.append(shard[0])
	# The broken faces show raw stone, so a shard never reads as a painted cube.
	draw_polyline(border, tint.darkened(0.5), 1.5, true)
