extends Node2D

# The fireball of a round going off. Hand drawn rather than a particle resource so
# it needs no texture and behaves the same in the editor, in the game and in a
# headless capture.
#
# Three things happen at once and on different clocks, which is what reads as fire
# rather than as an orange circle: a flash that is over almost before it is seen,
# embers thrown out of it, and smoke that outlives both.

const CORE := Color("fff6d2")
const FLAME := Color("ff9b1e")
const DEEP := Color("c93a0c")
const SMOKE := Color("3c342b")

var _age := 0.0
var _life := 1.25
var _reach := 70.0
var _embers: Array = []
var _smoke: Array = []


func configure(radius: float, strength := 1.0) -> void:
	z_as_relative = false
	z_index = 7
	_reach = radius
	_life = 0.9 + strength * 0.5
	var rng := RandomNumberGenerator.new()
	for i in range(int(16 + strength * 16)):
		var angle := rng.randf_range(0.0, TAU)
		_embers.append({
			"at": Vector2.RIGHT.rotated(angle) * radius * rng.randf_range(0.1, 0.4),
			"velocity": Vector2.RIGHT.rotated(angle) * rng.randf_range(120.0, 520.0) * strength,
			"size": rng.randf_range(1.8, 4.2),
			"life": rng.randf_range(0.35, 1.0),
		})
	for i in range(10):
		var angle := rng.randf_range(0.0, TAU)
		_smoke.append({
			"at": Vector2.RIGHT.rotated(angle) * radius * rng.randf_range(0.0, 0.5),
			"velocity": Vector2.RIGHT.rotated(angle) * rng.randf_range(10.0, 50.0) + Vector2(0, -rng.randf_range(20.0, 60.0)),
			"radius": radius * rng.randf_range(0.2, 0.45),
			"grow": radius * rng.randf_range(0.3, 0.7),
			"lag": rng.randf_range(0.04, 0.3),
		})


func _process(delta: float) -> void:
	_age += delta
	for ember in _embers:
		ember.at += ember.velocity * delta
		# Embers are thrown, then fall and burn out.
		ember.velocity = ember.velocity.lerp(Vector2(0, 260.0), delta * 2.4)
	for puff in _smoke:
		if _age < puff.lag:
			continue
		puff.at += puff.velocity * delta
		puff.velocity = puff.velocity.lerp(Vector2(0, -26.0), delta * 1.8)
		puff.radius += puff.grow * delta
	queue_redraw()
	if _age > _life:
		queue_free()


# One ragged ring of the fireball. The outline wobbles with three harmonics, so no
# layer is ever a circle and no two layers wobble alike.
func _layer(size: float, colour: Color, alpha: float, phase: float) -> void:
	if alpha <= 0.0 or size <= 0.5:
		return
	var shape := PackedVector2Array()
	for i in range(22):
		var angle := TAU * i / 22.0
		var wobble: float = 1.0 + 0.26 * sin(angle * 3.0 + phase) \
			+ 0.15 * sin(angle * 7.0 - phase * 1.7) + 0.08 * sin(angle * 11.0 + phase * 0.6)
		shape.append(Vector2.RIGHT.rotated(angle) * size * wobble)
	var tinted := colour
	tinted.a = clampf(alpha, 0.0, 1.0)
	draw_colored_polygon(shape, tinted)


func _draw() -> void:
	# Smoke sits behind the flame, and is what is left once the flame is gone.
	for puff in _smoke:
		if _age < puff.lag:
			continue
		var fade: float = clampf(1.0 - (_age - puff.lag) / maxf(_life - puff.lag, 0.01), 0.0, 1.0)
		var colour := SMOKE
		colour.a = fade * 0.42
		draw_circle(puff.at, puff.radius, colour)
	# The flame is brief and layered: a dark body, a bright middle and a white
	# heart, each its own irregular shape. Layers read as fire; separate tongues
	# read as a flower.
	var burn: float = _age / 0.34
	if burn < 1.0:
		var swell: float = 0.5 + burn * 0.9
		_layer(_reach * swell, DEEP, (1.0 - burn) * 0.9, 0.0)
		_layer(_reach * 0.66 * swell, FLAME, (1.0 - burn * 1.3) * 0.95, 1.7)
		_layer(_reach * 0.34 * swell, CORE, 1.0 - burn * 1.9, 3.1)
	for ember in _embers:
		var left: float = 1.0 - _age / ember.life
		if left <= 0.0:
			continue
		var glow := CORE.lerp(DEEP, 1.0 - left)
		glow.a = left
		draw_circle(ember.at, ember.size * left, glow)
