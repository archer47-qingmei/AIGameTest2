class_name CombatEngine
extends RefCounted

signal state_changed
signal combat_ended(result: String)

var player: Combatant
var enemy: Combatant
var hand: Array[CardData] = []
var energy: int = 0
var turn_number: int = 0

var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []

func setup() -> void:
	player = Combatant.new()
	player.display_name = "玩家"
	player.hp = 70
	player.max_hp = 70
	player.block = 0

	enemy = Combatant.new()
	enemy.display_name = "颚虫"
	enemy.hp = 44
	enemy.max_hp = 44
	enemy.block = 0

	for i in 4:
		var c: CardData = CardData.new()
		c.card_name = "打击"
		c.cost = 1
		c.damage = 6
		c.block = 0
		_draw_pile.append(c)

	for i in 4:
		var c: CardData = CardData.new()
		c.card_name = "防御"
		c.cost = 1
		c.damage = 0
		c.block = 5
		_draw_pile.append(c)

	var bash: CardData = CardData.new()
	bash.card_name = "重击"
	bash.cost = 2
	bash.damage = 8
	bash.block = 0
	_draw_pile.append(bash)

	_draw_pile.shuffle()
	_start_player_turn()

func play_card(card: CardData) -> void:
	if energy < card.cost:
		return
	energy -= card.cost
	EffectResolver.resolve(card, player, enemy)
	var idx: int = hand.find(card)
	if idx >= 0:
		hand.remove_at(idx)
	_discard_pile.append(card)
	state_changed.emit()
	_check_end()

func end_turn() -> void:
	for card: CardData in hand:
		_discard_pile.append(card)
	hand.clear()
	_do_enemy_turn()
	state_changed.emit()
	if not _check_end():
		_start_player_turn()

func _start_player_turn() -> void:
	turn_number += 1
	energy = 3
	player.block = 0
	_draw_hand()
	state_changed.emit()

func _draw_hand() -> void:
	hand.clear()
	for i in 5:
		if _draw_pile.is_empty():
			if _discard_pile.is_empty():
				break
			for card: CardData in _discard_pile:
				_draw_pile.append(card)
			_discard_pile.clear()
			_draw_pile.shuffle()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _do_enemy_turn() -> void:
	enemy.block = 0
	if turn_number % 2 == 1:
		player.take_damage(11)
	else:
		enemy.add_block(6)

func _check_end() -> bool:
	if enemy.hp <= 0:
		combat_ended.emit("victory")
		return true
	if player.hp <= 0:
		combat_ended.emit("game_over")
		return true
	return false
