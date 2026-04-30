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
var _enemy_data: EnemyData
var _relics: Array[RelicData] = []

func setup(initial_deck: Array[CardData], enemy_data: EnemyData, initial_hp: int, max_hp: int, relics: Array[RelicData] = []) -> void:
	_relics = relics
	_enemy_data = enemy_data
	enemy = Combatant.new()
	enemy.display_name = _enemy_data.display_name
	enemy.hp = _enemy_data.hp
	enemy.max_hp = _enemy_data.hp
	enemy.block = 0

	player = Combatant.new()
	player.display_name = "玩家"
	player.hp = initial_hp
	player.max_hp = max_hp
	player.block = 0

	for card: CardData in initial_deck:
		_draw_pile.append(card.duplicate())
	_draw_pile.shuffle()
	_start_player_turn()

func get_current_enemy_action() -> EnemyActionData:
	return _enemy_data.actions[(turn_number - 1) % _enemy_data.actions.size()]

func get_draw_pile() -> Array[CardData]:
	return _draw_pile.duplicate()

func get_discard_pile() -> Array[CardData]:
	return _discard_pile.duplicate()

func play_card(card: CardData) -> void:
	if energy < card.cost:
		return
	energy -= card.cost
	EffectResolver.resolve(card, player, enemy)
	_apply_engine_effects(card)
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
	player.weak = max(0, player.weak - 1)
	turn_number += 1
	energy = 3
	player.block = 0
	_draw_hand()
	if turn_number == 1:
		RelicEngine.apply_combat_start(_relics, self)
	RelicEngine.apply_turn_start(_relics, self)
	state_changed.emit()

func _refill_draw_pile_if_needed() -> void:
	if _draw_pile.is_empty() and not _discard_pile.is_empty():
		for card: CardData in _discard_pile:
			_draw_pile.append(card)
		_discard_pile.clear()
		_draw_pile.shuffle()

func _draw_hand() -> void:
	hand.clear()
	for i in 5:
		_refill_draw_pile_if_needed()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _apply_engine_effects(card: CardData) -> void:
	for effect: CardEffectData in card.effects:
		if effect.type == "draw":
			_draw_cards(effect.value)
		elif effect.type == "energy":
			energy += effect.value

func _draw_cards(n: int) -> void:
	for i: int in n:
		_refill_draw_pile_if_needed()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _do_enemy_turn() -> void:
	enemy.block = 0
	enemy.vulnerable = max(0, enemy.vulnerable - 1)
	var action: EnemyActionData = get_current_enemy_action()
	if action.type == "attack":
		EffectResolver.apply_damage(enemy, player, action.value)
		enemy.weak = max(0, enemy.weak - 1)
	else:
		enemy.add_block(action.value)

func _check_end() -> bool:
	if enemy.hp <= 0:
		combat_ended.emit("victory")
		return true
	if player.hp <= 0:
		combat_ended.emit("game_over")
		return true
	return false
