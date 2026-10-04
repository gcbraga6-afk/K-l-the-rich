extends Node

# Four minutes per day; no intervention timer and no automatic ending.
var day := 1
var hour := 9.0
var day_seconds := 240.0
var light: CanvasModulate

func _ready() -> void:
	light = CanvasModulate.new()
	light.name = "Daylight"
	get_parent().add_child(light)

func _process(delta: float) -> void:
	hour += delta * 24.0 / day_seconds
	if hour >= 24:
		hour = fmod(hour,24)
		day += 1
	var dusk := smoothstep(17.0,21.0,hour)
	var dawn := 1.0-smoothstep(5.0,8.0,hour)
	light.color = Color.WHITE.lerp(Color("929eb7"),maxf(dusk,dawn))

func resting() -> bool:
	return hour >= 19 or hour < 6

func description() -> String:
	return "Dia %d · %02d:%02d" % [day,int(hour),int(fmod(hour,1.0)*60)]
