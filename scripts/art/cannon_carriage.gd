extends Node2D
const Sheet = preload("res://assets/composition/cannon_parts.png")
var barrel: Sprite2D
var wheel: Sprite2D
var carriage: Sprite2D
var pivot: Node2D
var recoil := 0.0
var flash := 0.0
var smoke := 0.0
var pivot_home := Vector2(46,-44)

func part(region: Rect2, width: float) -> Sprite2D:
	var tex := AtlasTexture.new()
	tex.atlas = Sheet
	tex.region = region
	tex.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = tex
	sprite.scale = Vector2.ONE * width/region.size.x
	return sprite

func _ready() -> void:
	name = "CannonArt"
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	pivot = get_parent().get_node("CannonPivot")
	pivot.position = pivot_home
	pivot.rotation = -0.2
	pivot.get_node("Cannon").hide()
	carriage = part(Rect2(31,479,969,353),128)
	carriage.position = Vector2(20,-28)
	add_child(carriage)
	barrel = part(Rect2(34,119,962,216),148)
	barrel.position = Vector2(20,0)
	pivot.add_child(barrel)
	wheel = part(Rect2(223,875,578,580),56)
	wheel.position = Vector2(46,-28)
	wheel.z_index = 4
	add_child(wheel)
	EventBus.projectile_fired.connect(_on_fire)

func _on_fire(event: Dictionary) -> void:
	if event.get("cause") != "knight": return
	recoil = 1.0
	flash = 0.12
	smoke = 0.9

func _process(delta: float) -> void:
	recoil = move_toward(recoil,0.0,delta*2.4)
	flash = maxf(0,flash-delta)
	smoke = maxf(0,smoke-delta)
	var kick := sin(recoil*PI*0.5)*12.0
	pivot.position = pivot_home-Vector2(kick,0)
	carriage.position.x = 20-kick*0.5
	wheel.position.x = 46-kick*0.5
	wheel.rotation = -kick/28
	barrel.position.x = 20-kick*0.4
	queue_redraw()

func _draw() -> void:
	if pivot == null: return
	var muzzle: Vector2 = to_local(get_parent()._muzzle_global_position())
	var dir := Vector2.RIGHT.rotated(pivot.rotation)
	if flash > 0:
		var side := dir.orthogonal()
		draw_colored_polygon(PackedVector2Array([muzzle-side*9,muzzle+dir*48,muzzle+side*9]),Color(1,0.69,0.2,flash/0.12))
		draw_circle(muzzle+dir*12,9,Color(1,0.94,0.66,flash/0.12))
	if smoke > 0:
		var age := 0.9-smoke
		for i in 7:
			var p := muzzle+dir*(18+i*6+age*38)+Vector2(0,-age*44-sin(i*2.0)*9)
			draw_circle(p,5+i*1.2+age*9,Color(0.77,0.75,0.69,smoke*0.24))
		for i in 4:
			draw_circle(Vector2(25-i*11-age*19,-3),3+age*6,Color(0.66,0.58,0.4,smoke*0.28))
