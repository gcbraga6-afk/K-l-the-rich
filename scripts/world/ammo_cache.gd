extends Node2D

# Powder the Kingdom is holding, and the only way the cannon is fed once the load
# the Knight arrived with is gone. A round landing close enough breaks the cache
# open and what is inside is his.
#
# Every cache is finite and visible before it is attacked: the player counts the
# crates on the cart coming up the road, or the barrels stacked against the castle
# wall, and decides whether a shot is worth spending to get shots back. Shooting
# badly is what runs the intervention out, not a clock.

@export var crates := 3        # what is still inside
@export var per_hit := 3       # how many one well placed round frees
@export var reach := 120.0     # how near the blast has to land, past its own radius
@export var title := "Munição"

var spent := false

func _ready() -> void:
	add_to_group("ammo_caches")


func seize(blast: Vector2, radius: float) -> void:
	if spent or crates <= 0:
		return
	var distance := blast.distance_to(global_position)
	var span := reach + radius
	if distance > span:
		return
	# A round on top of the crates takes the lot. One at the edge of its reach
	# shakes a couple loose and no more.
	var taken := clampi(ceili(per_hit * (1.0 - distance / span)), 1, crates)
	crates -= taken
	EventBus.emit_ammo_seized(taken, global_position, title)
	_on_seized(taken, blast)
	if crates <= 0:
		# Set before the hook runs: a store that detonates sets off another blast,
		# and that blast asks every cache in the Kingdom to open, this one included.
		spent = true
		_on_emptied(blast)


# What a particular kind of cache does when it is cracked open, and when the last
# crate leaves it. A plain cache does neither.
func _on_seized(_taken: int, _blast: Vector2) -> void:
	pass


func _on_emptied(_blast: Vector2) -> void:
	pass
