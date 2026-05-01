class_name RewardEngine
extends RefCounted

static func get_options(character: String) -> Array[CardData]:
	var pool_paths: Array[String] = []
	match character:
		"sword":
			pool_paths.assign(CardPool.SWORD_REWARD_CARDS)
		_:
			push_warning("RewardEngine.get_options: unknown character '%s', fallback to CARDS" % character)
			pool_paths.assign(CardPool.CARDS)
	var pool: Array[CardData] = []
	for path: String in pool_paths:
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
