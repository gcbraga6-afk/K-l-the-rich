extends RefCounted

const SHEETS := [
	preload("res://assets/houses/houses_01.png"),
	preload("res://assets/houses/houses_02.png"),
	preload("res://assets/houses/houses_03.png"),
	preload("res://assets/houses/houses_04.png"),
	preload("res://assets/houses/houses_05.png"),
]
static var _textures: Array[AtlasTexture] = []

static func house(index: int) -> AtlasTexture:
	if _textures.is_empty():
		var rows: Array = JSON.parse_string(FileAccess.get_file_as_string("res://assets/houses/catalog.json"))
		for row: Dictionary in rows:
			var atlas := AtlasTexture.new()
			atlas.atlas = SHEETS[int(row.sheet)]
			var box: Array = row.region
			atlas.region = Rect2(box[0], box[1], box[2], box[3])
			atlas.filter_clip = true
			_textures.append(atlas)
	return _textures[clampi(index, 0, 19)]
