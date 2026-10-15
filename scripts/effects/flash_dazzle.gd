extends CanvasLayer

# What a flashbang does to whoever is looking at it, applied to the screen rather
# than to the kingdom: a white wall, the ringing, and then the eyes coming back
# slowly with the picture smeared into itself.

const SHADER = preload("res://scripts/effects/dazzle.gdshader")
const REPORT = preload("res://assets/audio/flashbang.mp3")

const WHITE_OUT := 0.18     # seconds held at full white before it begins to lift
const WHITE_FADE := 0.9     # and how long it takes to clear
const GHOST_IN := 0.35      # the after-image swelling once the white has gone
const GHOST_HOLD := 4.0     # how long the eyes stay spoiled

var _clock := 0.0
var _sheet: ColorRect
var _ghost: ColorRect

func _ready() -> void:
	layer = 100
	_ghost = ColorRect.new()
	_ghost.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var material := ShaderMaterial.new()
	material.shader = SHADER
	_ghost.material = material
	add_child(_ghost)
	_sheet = ColorRect.new()
	_sheet.set_anchors_preset(Control.PRESET_FULL_RECT)
	_sheet.color = Color(1, 1, 1, 1)
	_sheet.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sheet)
	var report := AudioStreamPlayer.new()
	report.stream = REPORT
	report.bus = "Master"
	add_child(report)
	report.play()

func _process(delta: float) -> void:
	_clock += delta
	# The white wall, held for an instant and then lifting.
	var white := 1.0 - clampf((_clock - WHITE_OUT) / WHITE_FADE, 0.0, 1.0)
	_sheet.color.a = white
	# The after-image swells as the white clears — the eyes do not recover into a
	# clean picture, they recover into a smeared one — and then fades out over the
	# seconds the dazzle lasts.
	var ghost := 0.0
	var since := _clock - WHITE_OUT
	if since > 0.0:
		ghost = clampf(since / GHOST_IN, 0.0, 1.0)
		ghost *= 1.0 - clampf((since - GHOST_IN) / GHOST_HOLD, 0.0, 1.0)
	_ghost.material.set_shader_parameter("strength", ghost)
	if _clock > WHITE_OUT + GHOST_IN + GHOST_HOLD + 0.2:
		queue_free()
