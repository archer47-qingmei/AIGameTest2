class_name RewardEngine
extends RefCounted

static func get_options() -> Array[CardData]:
	var options: Array[CardData] = []
	var dir := DirAccess.open("res://data/cards/")
	if dir == null:
		return options
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var card := load("res://data/cards/" + file_name) as CardData
			if card != null:
				options.append(card)
		file_name = dir.get_next()
	options.shuffle()
	return options.slice(0, mini(3, options.size()))
