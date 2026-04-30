class_name ShopEngine
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
const RELIC_POOL: Array[String] = [
	"res://data/relics/burning_gem.tres",
	"res://data/relics/life_ring.tres",
]

var inventory_cards: Array[CardData] = []
var inventory_relics: Array[RelicData] = []

func generate() -> void:
	var cards: Array[CardData] = []
	for path: String in CARD_POOL:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	cards.shuffle()
	inventory_cards.assign(cards.slice(0, mini(4, cards.size())))
	var relics: Array[RelicData] = []
	for path: String in RELIC_POOL:
		var relic := load(path) as RelicData
		if relic != null:
			relics.append(relic)
	relics.shuffle()
	inventory_relics.assign(relics.slice(0, mini(2, relics.size())))

func buy_card(card: CardData, player_state: PlayerState) -> bool:
	if player_state.gold < card.price:
		return false
	player_state.gold -= card.price
	player_state.deck.append(card.duplicate())
	inventory_cards.erase(card)
	return true

func buy_relic(relic: RelicData, player_state: PlayerState) -> bool:
	if player_state.gold < relic.price:
		return false
	player_state.gold -= relic.price
	player_state.relics.append(relic.duplicate())
	inventory_relics.erase(relic)
	return true
