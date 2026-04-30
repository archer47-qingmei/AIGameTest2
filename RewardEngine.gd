class_name RewardEngine
extends RefCounted

const CARD_POOL: Array[String] = [
	"res://data/cards/strike.tres",
	"res://data/cards/defend.tres",
	"res://data/cards/bash.tres",
	"res://data/cards/slash.tres",
	"res://data/cards/insight.tres",
	"res://data/cards/quick_strike.tres",
	"res://data/cards/energize.tres",
	"res://data/cards/dash.tres",
	"res://data/cards/entangle.tres",
]

static func get_options() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path: String in CARD_POOL:
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
