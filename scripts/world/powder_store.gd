extends "res://scripts/world/ammo_cache.gd"

# The Kingdom's powder, stacked against the castle wall where the carts unload.
# It is the largest resupply in the Kingdom and the loudest: the last crate does
# not leave quietly, it takes the store with it, and everything standing nearby
# finds out at once.
# A arte do paiol: pilha pintada de barris, caixas e balas.
const Explosion = preload("res://scenes/explosion.tscn")
const Terraces = preload("res://scripts/world/terraces.gd")
const PILE = preload("res://assets/props/powder_pile.png")

const WIDTH := 210.0        # how wide the pile stands in the Kingdom
const SCORCH := Color("2b2522")

func _ready() -> void:
	super._ready()
	crates = 7
	per_hit = 7
	reach = 150.0
	title = "Paiol real"
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# The caller picks where along the Kingdom it stands; the ground picks how high.
	position.y = Terraces.walking_y(position.x)


func _draw() -> void:
	if spent:
		# Nothing painted for a store that has gone up; scorch where the pile was.
		for i in range(11):
			draw_rect(Rect2(-WIDTH * 0.5 + i * WIDTH / 11.0, -14 - (i % 3) * 6, WIDTH / 13.0, 11),
				SCORCH.lightened(float(i % 3) * 0.1))
		return
	var height := WIDTH * PILE.get_height() / PILE.get_width()
	draw_texture_rect(PILE, Rect2(-WIDTH * 0.5, -height, WIDTH, height), false)


func _on_seized(_taken: int, _blast: Vector2) -> void:
	queue_redraw()


func _on_emptied(blast: Vector2) -> void:
	# The store answers with its own blast, from the pile rather than from where
	# the round happened to land, so the hole it leaves is where the powder was.
	var boom := Explosion.instantiate()
	boom.radius = 270.0
	boom.max_damage = 5
	boom.heading = (global_position - blast).normalized()
	boom.global_position = global_position + Vector2(0, -26)
	get_tree().current_scene.add_child(boom)
	EventBus.world_event.emit({
		"type": "POWDER_STORE_BLOWN",
		"target": title, "cause": "knight", "position": global_position,
		"severity": 1.0, "narrative_value": 0.8,
	})
	queue_redraw()
