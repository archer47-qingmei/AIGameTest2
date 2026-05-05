class_name ShopEngine
extends RefCounted

var inventory_cards: Array[CardData] = []
var inventory_relics: Array[RelicData] = []
var purchase_count: int = 0

func generate(player_state: PlayerState = null) -> void:
	var cards: Array[CardData] = []
	for path: String in CardPool.SWORD_REWARD_CARDS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	cards.shuffle()
	inventory_cards.clear()
	for c: CardData in cards.slice(0, mini(4, cards.size())):
		inventory_cards.append(c.duplicate())

	var all_relics: Array[RelicData] = []
	for path: String in CardPool.RELICS:
		var relic := load(path) as RelicData
		if relic != null:
			all_relics.append(relic)
	all_relics.shuffle()

	var relic_count: int = 2
	if player_state != null:
		for r: RelicData in player_state.relics:
			if (r.effect_type == RelicData.EffectType.EXTRA_SHOP_RELIC and not r.used) or \
			   (r.has_effect_b and r.effect_type_b == RelicData.EffectType.EXTRA_SHOP_RELIC and not r.used):
				relic_count += 1
				r.used = true
				break

	inventory_relics.clear()
	for r: RelicData in all_relics.slice(0, mini(relic_count, all_relics.size())):
		inventory_relics.append(r.duplicate())

	if player_state != null:
		_apply_shop_discount(player_state)

func buy_card(card: CardData, player_state: PlayerState) -> bool:
	if player_state.gold < card.price:
		return false
	player_state.gold -= card.price
	player_state.deck.append(card.duplicate())
	inventory_cards.erase(card)
	_maybe_apply_ledger_discount(player_state)
	return true

func buy_relic(relic: RelicData, player_state: PlayerState) -> bool:
	if player_state.gold < relic.price:
		return false
	player_state.gold -= relic.price
	var equipped: RelicData = relic.duplicate()
	player_state.relics.append(equipped)
	RelicEngine.apply_on_equip(equipped, player_state)
	inventory_relics.erase(relic)
	_maybe_apply_ledger_discount(player_state)
	return true

func _apply_shop_discount(player_state: PlayerState) -> void:
	var has_discount: bool = false
	for r: RelicData in player_state.relics:
		if r.effect_type == RelicData.EffectType.SHOP_DISCOUNT or \
		   (r.has_effect_b and r.effect_type_b == RelicData.EffectType.SHOP_DISCOUNT):
			has_discount = true
			break
	if not has_discount:
		return
	for c: CardData in inventory_cards:
		c.price = int(c.price * 0.85)
	for r: RelicData in inventory_relics:
		r.price = int(r.price * 0.85)

func _maybe_apply_ledger_discount(player_state: PlayerState) -> void:
	if purchase_count > 0:
		return
	purchase_count += 1
	var has_ledger: bool = false
	for r: RelicData in player_state.relics:
		if r.effect_type == RelicData.EffectType.SHOP_SECOND_HALF_PRICE or \
		   (r.has_effect_b and r.effect_type_b == RelicData.EffectType.SHOP_SECOND_HALF_PRICE):
			has_ledger = true
			break
	if not has_ledger:
		return
	for c: CardData in inventory_cards:
		c.price = maxi(1, c.price / 2)
	for r: RelicData in inventory_relics:
		r.price = maxi(1, r.price / 2)
