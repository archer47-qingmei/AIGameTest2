class_name CombatEngine
extends RefCounted

const BASE_ENERGY: int = 3
const VENOM_CARD: CardData = preload("res://data/cards/venom.tres")

signal state_changed
signal combat_ended(result: String)
signal hits_dealt(enemy_index: int, hp_amounts: Array[int], block_amounts: Array[int])
signal player_damaged(amount: int)
signal player_gained_block(amount: int)
signal player_gained_sword_intent(amount: int)

var player: Combatant
var enemies: Array[Combatant] = []
var hand: Array[CardData] = []
var energy: int = 0
var energy_cap: int = BASE_ENERGY
var turn_number: int = 0

var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _exhaust_pile: Array[CardData] = []
var _enemy_data_list: Array[EnemyData] = []
var _relics: Array[RelicData] = []
var _pending_actions: Array[EnemyActionData] = []

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
	return _pending_actions[i]

func _resolve_enemy_actions() -> void:
	_pending_actions.resize(enemies.size())
	for i in enemies.size():
		if enemies[i].hp <= 0:
			_pending_actions[i] = null
			continue
		if enemies[i].is_charging:
			var a := EnemyActionData.new()
			a.type = "charge_attack"
			a.value = enemies[i].charge_value
			_pending_actions[i] = a
		elif _enemy_data_list[i].random_actions:
			_pending_actions[i] = _weighted_random_action(_enemy_data_list[i].actions)
		else:
			_pending_actions[i] = _enemy_data_list[i].actions[(turn_number - 1) % _enemy_data_list[i].actions.size()]

func _weighted_random_action(actions: Array[EnemyActionData]) -> EnemyActionData:
	var total: int = 0
	for a: EnemyActionData in actions:
		total += a.weight
	if total <= 0:
		return actions[randi() % actions.size()]
	var roll: int = randi() % total
	var cumulative: int = 0
	for a: EnemyActionData in actions:
		cumulative += a.weight
		if roll < cumulative:
			return a
	return actions[-1]

func get_draw_pile() -> Array[CardData]:
	return _draw_pile.duplicate()

func get_discard_pile() -> Array[CardData]:
	return _discard_pile.duplicate()

func get_exhaust_pile() -> Array[CardData]:
	return _exhaust_pile.duplicate()

func play_card(card_index: int, target_index: int) -> bool:
	var card: CardData = hand[card_index]
	if card.cost > energy:
		return false
	energy -= card.cost
	var block_before := player.block
	var si_before := player.sword_intent
	if card.target_type == "all":
		for i in enemies.size():
			if enemies[i].hp > 0:
				var blk_amounts: Array[int] = []
				var hp_amounts: Array[int] = EffectResolver.resolve(card, player, enemies[i], blk_amounts)
				if not hp_amounts.is_empty():
					hits_dealt.emit(i, hp_amounts, blk_amounts)
	else:
		var target: Combatant = enemies[target_index] if target_index >= 0 else null
		var blk_amounts: Array[int] = []
		var hp_amounts: Array[int] = EffectResolver.resolve(card, player, target, blk_amounts)
		if target_index >= 0 and not hp_amounts.is_empty():
			hits_dealt.emit(target_index, hp_amounts, blk_amounts)
	var block_gained := player.block - block_before
	if block_gained > 0:
		player_gained_block.emit(block_gained)
	_apply_engine_effects(card)
	var si_gained := player.sword_intent - si_before
	if si_gained > 0:
		player_gained_sword_intent.emit(si_gained)
	hand.remove_at(card_index)
	if card.card_type == "功法":
		_exhaust_pile.append(card)
	else:
		_discard_pile.append(card)
	state_changed.emit()
	_check_end()
	return true

func end_turn() -> void:
	var venom_count: int = 0
	for card: CardData in hand:
		if card.is_venom:
			venom_count += 1
	if venom_count > 0:
		player.hp = max(0, player.hp - venom_count)
		player_damaged.emit(venom_count)
		state_changed.emit()
		if _check_end():
			return
	for card: CardData in hand:
		_discard_pile.append(card)
	hand.clear()
	if not player.sword_intent_retain:
		player.sword_intent = player.sword_intent / 2
	RelicEngine.apply_turn_end(_relics, self)
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
	energy = energy_cap
	player.block = 0
	_draw_hand()
	if player.draw_per_turn > 0:
		_draw_cards(player.draw_per_turn)
	if player.next_turn_draw > 0:
		_draw_cards(player.next_turn_draw)
		player.next_turn_draw = 0
	_resolve_enemy_actions()
	for i in enemies.size():
		if enemies[i].hp > 0:
			enemies[i].current_intent = get_enemy_action(i).type
	if turn_number == 1:
		RelicEngine.apply_combat_start(_relics, self)
		energy = energy_cap
	RelicEngine.apply_turn_start(_relics, self)
	state_changed.emit()

func _refill_draw_pile_if_needed() -> void:
	if _draw_pile.is_empty() and not _discard_pile.is_empty():
		_draw_pile.append_array(_discard_pile)
		_discard_pile.clear()
		_draw_pile.shuffle()

func _draw_hand() -> void:
	hand.clear()
	_draw_cards(5)

func _apply_engine_effects(card: CardData) -> void:
	for effect: CardEffectData in card.effects:
		match effect.type:
			"draw":
				_draw_cards(effect.value)
			"energy":
				energy += effect.value
			"sword_intent_cap":
				player.sword_intent_cap += effect.value
			"sword_intent_bonus":
				player.sword_intent_damage_bonus += effect.value
			"draw_per_turn":
				player.draw_per_turn += effect.value
			"sword_intent_retain":
				player.sword_intent_retain = true
			"sword_intent_block_bonus":
				player.sword_intent_block_bonus += effect.value
			"sword_intent_if_no_style":
				# 仅用于非招式牌（招式打出后 played_style_this_turn 已为 true，会静默失效）
				if not player.played_style_this_turn:
					player.sword_intent = mini(player.sword_intent + effect.value, player.sword_intent_cap)
			"next_turn_si":
				player.next_turn_sword_intent += effect.value
			"next_turn_draw":
				player.next_turn_draw += effect.value
			"finisher_block":
				player.finisher_block_bonus += effect.value
			"first_si_block":
				player.first_si_block_bonus += effect.value

func draw_cards(n: int) -> void:
	_draw_cards(n)

func _draw_cards(n: int) -> void:
	for _i in n:
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
		enemies[i].is_charging = false
		enemies[i].charge_value = 0
		match action.type:
			"attack", "charge_attack":
				var hp_before: int = player.hp
				EffectResolver.apply_damage(enemies[i], player, action.value)
				var dmg: int = hp_before - player.hp
				if dmg > 0:
					player_damaged.emit(dmg)
				enemies[i].weak = max(0, enemies[i].weak - 1)
			"attack_weak":
				var hp_before: int = player.hp
				EffectResolver.apply_damage(enemies[i], player, action.value)
				var dmg: int = hp_before - player.hp
				if dmg > 0:
					player_damaged.emit(dmg)
				player.add_weak(1)
				enemies[i].weak = max(0, enemies[i].weak - 1)
			"attack_vulnerable":
				var hp_before: int = player.hp
				EffectResolver.apply_damage(enemies[i], player, action.value)
				var dmg: int = hp_before - player.hp
				if dmg > 0:
					player_damaged.emit(dmg)
				player.add_vulnerable(1)
				enemies[i].weak = max(0, enemies[i].weak - 1)
			"multi_attack":
				var hp_before: int = player.hp
				for _hit in action.count:
					EffectResolver.apply_damage(enemies[i], player, action.value)
				var dmg: int = hp_before - player.hp
				if dmg > 0:
					player_damaged.emit(dmg)
				enemies[i].weak = max(0, enemies[i].weak - 1)
			"charge":
				enemies[i].is_charging = true
				enemies[i].charge_value = action.value
			"pre_charge":
				pass
			"group_strengthen":
				for j in enemies.size():
					if enemies[j].hp > 0:
						enemies[j].strength += action.value
			"group_block":
				for j in enemies.size():
					if enemies[j].hp > 0:
						enemies[j].add_block(action.value)
			"poison":
				for _j in action.value:
					_draw_pile.append(VENOM_CARD.duplicate())
				_draw_pile.shuffle()
			"discard_curse":
				for _j in action.value:
					_discard_pile.append(VENOM_CARD.duplicate())
			_:
				enemies[i].add_block(action.value)

func _get_living_enemies() -> Array[Combatant]:
	return enemies.filter(func(e: Combatant) -> bool: return e.hp > 0)

func _check_end() -> bool:
	if _get_living_enemies().is_empty():
		RelicEngine.apply_combat_end(_relics, self)
		combat_ended.emit("victory")
		return true
	if player.hp <= 0:
		combat_ended.emit("game_over")
		return true
	return false
