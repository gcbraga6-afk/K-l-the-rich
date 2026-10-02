extends RefCounted
const SHEETS := [preload("res://assets/businesses/shops_tents.png"), preload("res://assets/businesses/industry.png"), preload("res://assets/businesses/shops.png"), preload("res://assets/businesses/factories_v2.png")]
static var textures: Array[AtlasTexture] = []
static func building(index: int) -> AtlasTexture:
	if textures.is_empty():
		var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/businesses/catalog.json"))
		for row: Dictionary in rows:
			var atlas := AtlasTexture.new()
			atlas.atlas = SHEETS[int(row.sheet)]
			var r: Array = row.region
			atlas.region = Rect2(r[0], r[1], r[2], r[3])
			atlas.filter_clip = true
			textures.append(atlas)
	return textures[index]
