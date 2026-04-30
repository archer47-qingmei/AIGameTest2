class_name ShopEngine
extends RefCounted

var inventory_cards: Array[CardData] = []
var inventory_relics: Array[RelicData] = []

func generate() -> void:
	var cards: Array[CardData] = []
	for path: String in CardPool.CARDS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	cards.shuffle()
	inventory_cards.assign(cards.slice(0, mini(4, cards.size())))
	var relics: Array[RelicData] = []
	for path: String in CardPool.RELICS:
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
