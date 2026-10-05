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
const GRACE := 1.8              # seconds on the ground before damping begins at all
const SETTLE_BY := 9.0          # seconds on the ground after which a piece is scenery
# A ceiling on speed cannot tell a piece kicked by the solver from a piece simply
# falling: set low enough to stop the kick, it also caps the fall, which is the one
# thing masonry has to get right. What separates them is the jolt. Gravity adds
# about 33 px/s in a step; the separation impulse from a piece born overlapping the
# facade it broke off was measured adding thousands at once, launching fragments at
# 16500 against a cannon that throws at 520. So the step-to-step gain is capped, and
# the absolute ceiling is left high enough that it only catches what escapes that.
const MAX_JOLT := 620.0
const MAX_SPEED := 1800.0

var owner_structure: Node = null
var tint := Color("9d9280")
var shard := PackedVector2Array()
var generation := 1
var broken := false
var show_skin := false

var _quiet := 0.0
var _age := 0.0
var _rest := 0.0
var _was_going := 0.0
# Set the moment a piece stops counting as live rubble. `freeze` cannot answer that
# question within the frame it is decided, because the physics server only accepts
# the change once its query flush is over, so a piece asked to retire still reads as
# live for the rest of the frame.
var retired := false
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
	angular_velocity = clampf(angular_velocity, -4.0, 4.0)
	# Nothing a cannon throws here travels faster than this. Pieces are born
	# overlapping one another and the facade they broke off, whose collision is built
	# from segments and so has no inside for the solver to push them out of: measured,
	# the separation impulses reached 16500 px/s against a throw of 520. A piece given
	# thirty times its energy arcs most of the way across the kingdom and hangs near
	# the top of that arc, far away and barely moving, which is what reads on screen
	# as a fragment stopped in the sky.
	var speed_now := linear_velocity.length()
	if speed_now > _was_going + MAX_JOLT:
		linear_velocity = linear_velocity.normalized() * (_was_going + MAX_JOLT)
	linear_velocity = linear_velocity.limit_length(MAX_SPEED)
	_was_going = linear_velocity.length()
	var touching := get_contact_count() > 0
	# A body is allowed to sleep only once it is resting. Asleep in the air it stops
	# being simulated and simply hangs there, which is what a piece does at the top
	# of its arc, where its velocity passes through almost nothing.
	can_sleep = touching
	if touching:
		# Settling time runs from the moment the piece lands, not from the blast.
		# Counted from the blast, a piece that spent a second in the air came down
		# already thick with damping and crawled to a halt the instant it touched
		# anything: it never clattered, it oozed. GRACE buys it that clatter.
		_rest += delta
		var settling := maxf(_rest - GRACE, 0.0)
		linear_damp = 0.3 + settling * 0.9
		angular_damp = 2.4 + settling * 1.6
		gravity_scale = 1.0
	else:
		# Damping is for settling, so there is none in flight at all. Ramped in the
		# air it slowed a thrown piece to a hover and the deadline froze it there.
		_rest = 0.0
		linear_damp = 0.0
		angular_damp = 2.4
		# Masonry falls like masonry. At plain gravity a fragment stays in the air
		# long enough to read as weightless, whatever arc the blast threw it on.
		gravity_scale = 2.0
	var speed := linear_velocity.length()
	_peak = maxf(_peak * 0.96, speed)
	if touching:
		if not _landed and _peak > 120.0:
			_landed = true
			_raise_dust(0.45)
		if speed < 16.0 and absf(angular_velocity) < 0.15:
			_quiet += delta
		else:
			_quiet = 0.0
	else:
		_quiet = 0.0
	# A piece becomes scenery where it came to rest, never in the air. The deadline
	# is for rubble that creeps or jitters on the ground and never quite satisfies
	# the quiet test; one still in flight goes on falling. It counts from landing,
	# so a piece thrown far still gets its full time on the ground.
	if _quiet > 1.2 or (_rest > SETTLE_BY and is_down()):
		retired = true
		freeze = true
		set_physics_process(false)
	# Gone off the map, or still airborne long after any sane arc: either way it is
	# no longer part of the scene.
	if global_position.y > 2200.0 or _age > 20.0:
		queue_free()

# Lying on something and done travelling, rather than merely brushing against it on
# the way past. Contact alone is not enough: a piece scraping down a wall is in
# contact the whole way, and freezing that piece pins it to the side of the house
# in open air. The budget asks before it turns a piece to scenery where it lies,
# so this has to mean the ground, not the wall.
func is_down() -> bool:
	return _rest > 0.3 and linear_velocity.length() < 60.0


# Turned to scenery where it lies, to make room under the shard budget for rubble
# from a newer round. A frozen piece is static: it still shows and still blocks,
# but the solver stops paying for it, which is the whole point of the budget.
# The physics server refuses state changes during its own query flush, so this is
# allowed to land on the next idle frame.
func settle() -> void:
	retired = true
	set_deferred("freeze", true)
	set_deferred("contact_monitor", false)
	set_physics_process(false)


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
	retired = false
	freeze = false
	sleeping = false
	_quiet = 0.0
	_age = 0.0
	# Shaken loose again, it gets its full settling time back rather than landing
	# into whatever damping it had already built up.
	_rest = 0.0
	linear_damp = 0.3
	angular_damp = 2.4
	_landed = false
	set_physics_process(true)
	linear_velocity += push
	_was_going = linear_velocity.length()
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
