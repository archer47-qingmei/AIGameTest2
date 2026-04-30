class_name RewardEngine
extends RefCounted

static func get_options() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path: String in CardPool.CARDS:
		var card := load(path) as CardData
		if card != null:
			pool.append(card)
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))

static func get_gold_reward(is_elite: bool, is_final: bool) -> int:
	if is_final:
		return randi_range(40, 60)
	if is_elite:
		return randi_range(25, 40)
	return randi_range(15, 25)
