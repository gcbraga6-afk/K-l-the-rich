extends Node2D

# Stone breaks into dust, and dust is most of what the eye reads as stone. Hand
# drawn rather than a particle resource so it needs no texture and behaves the
# same in the editor, in the game and in a headless test.

var _motes: Array = []
var _tint := Color("b8b2a4")
var _age := 0.0
var _life := 1.6

# `scale` is how big the thing that raised this dust was. Without it the cloud is
# sized for one building and swallows every smaller one.
func configure(strength: float, stone_tint := Color("9aafbf"), scale := 1.0) -> void:
	# Dust has to read in front of the scenery, like the rubble it comes off.
	z_as_relative = false
	z_index = 6
	_tint = stone_tint.lightened(0.5)
	_life = 1.1 + strength * 1.1
	var count := int(clampf(7.0 + strength * 30.0, 7.0, 40.0))
	var rng := RandomNumberGenerator.new()
	for i in count:
		var angle := rng.randf_range(0.0, TAU)
		var speed := rng.randf_range(16.0, 95.0) * (0.45 + strength) * scale
		_motes.append({
			"at": Vector2.ZERO,
			"velocity": Vector2.RIGHT.rotated(angle) * speed + Vector2(0, -rng.randf_range(10.0, 48.0) * scale),
			"radius": rng.randf_range(3.0, 10.0) * (0.7 + strength) * scale,
			"grow": rng.randf_range(10.0, 26.0) * scale,
			"delay": rng.randf_range(0.0, 0.18),
		})

func _process(delta: float) -> void:
	_age += delta
	for mote in _motes:
		if _age < mote.delay:
			continue
		mote.at += mote.velocity * delta
		# Dust loses its push quickly and then just hangs and drifts upward.
		mote.velocity = mote.velocity.lerp(Vector2(0, -12.0), delta * 2.2)
		mote.radius += mote.grow * delta
	queue_redraw()
	if _age > _life:
		queue_free()

func _draw() -> void:
	var fade := 1.0 - _age / _life
	for mote in _motes:
		if _age < mote.delay:
			continue
		var colour := _tint
		colour.a = clampf(fade * 0.5, 0.0, 0.5)
		draw_circle(mote.at, mote.radius, colour)
