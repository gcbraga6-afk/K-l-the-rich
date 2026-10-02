extends Node2D

var building: Node2D
const INK := Color("302e32")
const STONE := Color("777b79")
const LIGHT := Color("a7a28c")
const ROOF := Color("734c43")
const GOLD := Color("dfb761")

func _ready() -> void:
	building = get_parent()
	for child in building.get_children():
		if child is CanvasItem and child != self:
			child.hide()
	queue_redraw()

func _process(_delta: float) -> void:
	queue_redraw()

func block(x: float, y: float, w: float, h: float, color: Color) -> void:
	draw_rect(Rect2(x, y, w, h), color)

func masonry(x: float, y: float, w: float, h: float, color: Color) -> void:
	block(x-4,y-4,w+8,h+8,INK)
	block(x,y,w,h,color)
	for row in range(int(h / 18)):
		block(x,y+row*18,w,2,color.darkened(0.18))
		for col in range(int(w / 32)):
			block(x+col*32+(16 if row%2 else 0),y+row*18,2,18,color.darkened(0.18))

func window(x: float, y: float) -> void:
	block(x-4,y-4,26,36,INK)
	block(x,y,18,28,GOLD)
	block(x+8,y,3,28,ROOF)
	block(x,y+12,18,3,ROOF)

func roof(x: float, y: float, w: float, h: float) -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(x-8,y+4),Vector2(x+w/2,y-h),Vector2(x+w+8,y+4)]),INK)
	draw_colored_polygon(PackedVector2Array([Vector2(x,y),Vector2(x+w/2,y-h+8),Vector2(x+w,y)]),ROOF)
	for i in range(1, int(h/10)):
		var inset := w*0.5*(float(i*10)/h)
		block(x+inset,y-i*10,w-inset*2,3,ROOF.lightened(0.13))

func _draw() -> void:
	if building == null:
		return
	var floor_y := 620.0 - building.global_position.y
	if building._integrity <= 0:
		for i in range(12):
			block(-85+i*15,floor_y-8-(i%3)*9,23,12,STONE.darkened(float(i%3)*0.12))
		return
	var id := str(building.name)
	if id == "Castle":
		masonry(-155,floor_y-245,310,245,STONE)
		masonry(-65,floor_y-330,130,330,LIGHT.darkened(0.13))
		roof(-72,floor_y-330,144,60)
		for x in [-205, 125]:
			masonry(x,floor_y-290,80,290,STONE.lightened(0.1))
			roof(x-8,floor_y-290,96,75)
			window(x+30,floor_y-240)
			window(x+30,floor_y-140)
		block(-35,floor_y-90,70,90,INK)
		for i in range(6):
			block(-31+i*12,floor_y-84,4,84,ROOF)
		window(-10,floor_y-280)
		block(0,floor_y-437,4,70,INK)
		block(4,floor_y-437,48,24,Color("a14e48"))
	elif id == "Wall":
		masonry(-90,floor_y-250,180,250,STONE)
		for i in range(5):
			masonry(-90+i*40,floor_y-275,20,25,STONE)
		block(-30,floor_y-125,60,125,INK)
		for i in range(5):
			block(-25+i*12,floor_y-120,4,120,ROOF)
	elif id == "Mirror":
		masonry(-45,floor_y-35,90,35,STONE)
		block(-58,floor_y-255,116,220,INK)
		block(-50,floor_y-247,100,204,GOLD.darkened(0.2))
		block(-40,floor_y-237,80,184,Color("5b929b"))
		block(-32,floor_y-225,8,155,Color("9cbfc0"))
		block(-10,floor_y-196,34,36,GOLD)
		block(-20,floor_y-155,54,65,Color("526a7d"))
	elif id == "Factory":
		masonry(-108,floor_y-176,216,176,Color("897a62"))
		masonry(58,floor_y-292,32,130,ROOF)
		for i in range(3):
			roof(-112+i*74,floor_y-176,80,46)
			window(-80+i*70,floor_y-125)
		block(-24,floor_y-67,48,67,INK)
		for i in range(5):
			block(60-i*6,floor_y-320-i*23,35+i*9,16,Color(0.3,0.32,0.31,0.24))
	else:
		var school := id == "School"
		masonry(-80,floor_y-140,160,140,Color("c0ad85") if school else Color("b79a76"))
		roof(-92,floor_y-140,184,75)
		block(-18,floor_y-63,36,63,ROOF.darkened(0.4))
		block(7,floor_y-35,4,4,GOLD)
		window(-60,floor_y-108)
		window(40,floor_y-108)
		if school:
			masonry(-19,floor_y-236,38,51,LIGHT)
			roof(-24,floor_y-236,48,28)
			block(-8,floor_y-224,16,23,GOLD)
		else:
			masonry(42,floor_y-214,20,45,ROOF)
	if building._integrity < building.max_integrity:
		draw_polyline(PackedVector2Array([Vector2(-20,floor_y-120),Vector2(4,floor_y-90),Vector2(-8,floor_y-60),Vector2(13,floor_y-30)]),INK,4)
