class_name CombatEngine
extends RefCounted

const BASE_ENERGY: int = 3

signal state_changed
signal combat_ended(result: String)

var player: Combatant
var enemies: Array[Combatant] = []
var hand: Array[CardData] = []
var energy: int = 0
var turn_number: int = 0

var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _enemy_data_list: Array[EnemyData] = []
var _relics: Array[RelicData] = []

func setup(initial_deck: Array[CardData], enemy_group: EnemyGroupData, initial_hp: int, max_hp: int, relics: Array[RelicData] = []) -> void:
	assert(not enemy_group.enemies.is_empty(), "EnemyGroupData has no enemies")
	_relics = relics
	for data: EnemyData in enemy_group.enemies:
		var c := Combatant.new()
		c.display_name = data.display_name
		c.hp = data.hp
		c.max_hp = data.hp
		c.block = 0
		enemies.append(c)
		_enemy_data_list.append(data)

	player = Combatant.new()
	player.display_name = "玩家"
	player.hp = initial_hp
	player.max_hp = max_hp
	player.block = 0

	for card: CardData in initial_deck:
		_draw_pile.append(card.duplicate())
	_draw_pile.shuffle()
	_start_player_turn()

func get_enemy_action(i: int) -> EnemyActionData:
	var actions: Array = _enemy_data_list[i].actions
	return actions[(turn_number - 1) % actions.size()]

func get_draw_pile() -> Array[CardData]:
	return _draw_pile.duplicate()

func get_discard_pile() -> Array[CardData]:
	return _discard_pile.duplicate()

func play_card(card_index: int, target_index: int) -> bool:
	var card: CardData = hand[card_index]
	if card.cost > energy:
		return false
	energy -= card.cost
	if card.target_type == "all":
		for enemy in enemies:
			if enemy.hp > 0:
				EffectResolver.resolve(card, player, enemy)
	else:
		var target: Combatant = enemies[target_index] if target_index >= 0 else null
		EffectResolver.resolve(card, player, target)
	_apply_engine_effects(card)
	hand.remove_at(card_index)
	_discard_pile.append(card)
	state_changed.emit()
	if _check_end():
		return true
	return true

func end_turn() -> void:
	var venom_count: int = 0
	for card: CardData in hand:
		if card.is_venom:
			venom_count += 1
	if venom_count > 0:
		player.hp = max(0, player.hp - venom_count)
		state_changed.emit()
		if _check_end():
			return
	for card: CardData in hand:
		_discard_pile.append(card)
	hand.clear()
	if not player.sword_intent_retain:
		player.sword_intent = player.sword_intent / 2
	_do_enemy_turn()
	state_changed.emit()
	if not _check_end():
		_start_player_turn()

func _start_player_turn() -> void:
	player.played_style_this_turn = false
	player.gained_sword_intent_this_turn = false
	player.sword_intent = mini(
		player.sword_intent + player.next_turn_sword_intent,
		player.sword_intent_cap
	)
	player.next_turn_sword_intent = 0
	player.weak = max(0, player.weak - 1)
	turn_number += 1
	energy = BASE_ENERGY
	player.block = 0
	_draw_hand()
	if player.draw_per_turn > 0:
		_draw_cards(player.draw_per_turn)
	if player.next_turn_draw > 0:
		_draw_cards(player.next_turn_draw)
		player.next_turn_draw = 0
	for i in enemies.size():
		if enemies[i].hp > 0:
			enemies[i].current_intent = get_enemy_action(i).type
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
		elif effect.type == "sword_intent_cap":
			player.sword_intent_cap += effect.value
		elif effect.type == "sword_intent_bonus":
			player.sword_intent_damage_bonus += effect.value
		elif effect.type == "draw_per_turn":
			player.draw_per_turn += effect.value
		elif effect.type == "sword_intent_retain":
			player.sword_intent_retain = true
		elif effect.type == "sword_intent_block_bonus":
			player.sword_intent_block_bonus += effect.value
		elif effect.type == "sword_intent_if_no_style":
			# 仅用于非招式牌（招式打出后 played_style_this_turn 已为 true，会静默失效）
			if not player.played_style_this_turn:
				player.sword_intent = mini(player.sword_intent + effect.value, player.sword_intent_cap)
		elif effect.type == "next_turn_si":
			player.next_turn_sword_intent += effect.value
		elif effect.type == "next_turn_draw":
			player.next_turn_draw += effect.value
		elif effect.type == "finisher_block":
			player.finisher_block_bonus += effect.value
		elif effect.type == "first_si_block":
			player.first_si_block_bonus += effect.value

func draw_cards(n: int) -> void:
	_draw_cards(n)

func _draw_cards(n: int) -> void:
	for i: int in n:
		_refill_draw_pile_if_needed()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _do_enemy_turn() -> void:
	for i in enemies.size():
		if enemies[i].hp <= 0:
			continue
		enemies[i].block = 0
		enemies[i].vulnerable = max(0, enemies[i].vulnerable - 1)
		var action: EnemyActionData = get_enemy_action(i)
		if action.type == "attack":
			EffectResolver.apply_damage(enemies[i], player, action.value)
			enemies[i].weak = max(0, enemies[i].weak - 1)
		elif action.type == "poison":
			var venom_card: CardData = load("res://data/cards/venom.tres") as CardData
			for j in action.value:
				_draw_pile.append(venom_card.duplicate())
			_draw_pile.shuffle()
		else:
			enemies[i].add_block(action.value)

func _get_living_enemies() -> Array[Combatant]:
	return enemies.filter(func(e: Combatant) -> bool: return e.hp > 0)

func _check_end() -> bool:
	if _get_living_enemies().is_empty():
		combat_ended.emit("victory")
		return true
	if player.hp <= 0:
		combat_ended.emit("game_over")
		return true
	return false
