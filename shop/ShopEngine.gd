class_name ShopEngine
extends RefCounted

var inventory_cards: Array[CardData] = []
var inventory_relics: Array[RelicData] = []

func generate(card_pool: Array[CardData], relic_pool: Array[RelicData]) -> void:
	var cards := card_pool.duplicate()
	cards.shuffle()
	inventory_cards.assign(cards.slice(0, mini(4, cards.size())))
	var relics := relic_pool.duplicate()
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
