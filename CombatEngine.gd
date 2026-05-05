class_name CombatEngine
extends RefCounted

const BASE_ENERGY: int = 3
const VENOM_CARD: CardData = preload("res://data/cards/venom.tres")
const CURSE_CARD: CardData = preload("res://data/cards/xin_mo.tres")
const ZAHUORUMUO_CARD: CardData = preload("res://data/cards/zao_huo_ru_mo.tres")
const BAO_NU_CARD: CardData = preload("res://data/cards/bao_nu.tres")
const KONG_JU_CARD: CardData = preload("res://data/cards/kong_ju.tres")
const BEI_SHANG_CARD: CardData = preload("res://data/cards/bei_shang.tres")
const ATTACK_TYPES_FOR_CHARGE: Array[String] = [
	"attack", "attack_weak", "attack_vulnerable", "multi_attack", "attack_curse", "vampiric_attack",
	"attack_self_damage", "attack_half_next_block", "attack_bao_nu", "attack_kong_ju", "attack_bei_shang", "attack_venom"
]

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
var took_damage: bool = false
var combat_gold: int = 0
var _block_gold_count: int = 0

var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _boss_copied_cards: Array[CardData] = []
var _exhaust_pile: Array[CardData] = []
var _enemy_data_list: Array[EnemyData] = []
var _relics: Array[RelicData] = []
var _pending_actions: Array[EnemyActionData] = []

func setup(initial_deck: Array[CardData], enemy_group: EnemyGroupData, initial_hp: int, max_hp: int, relics: Array[RelicData] = [], initial_energy_cap: int = BASE_ENERGY) -> void:
	energy_cap = initial_energy_cap
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
	for data: EnemyData in enemy_group.enemies:
		if data.copies_player_cards:
			var style_cards: Array[CardData] = []
			for card: CardData in _draw_pile:
				if _is_pure_damage_style(card):
					style_cards.append(card)
			style_cards.shuffle()
			_boss_copied_cards = style_cards.slice(0, mini(5, style_cards.size()))
			break
	_start_player_turn()

func get_enemy_action(i: int) -> EnemyActionData:
	return _pending_actions[i]

func _resolve_enemy_actions() -> void:
	_pending_actions.resize(enemies.size())
	for i in enemies.size():
		if enemies[i].hp <= 0:
			_pending_actions[i] = null
			continue
		var data: EnemyData = _enemy_data_list[i]
		if data.periodic_interval > 0 and data.periodic_action != null \
				and turn_number % data.periodic_interval == 0:
			_pending_actions[i] = data.periodic_action
			continue
		var use_phase2: bool = (
			data.phase2_threshold > 0.0
			and not data.phase2_actions.is_empty()
			and float(enemies[i].hp) / float(data.hp) <= data.phase2_threshold
		)
		var action_list: Array[EnemyActionData] = data.phase2_actions if use_phase2 else data.actions
		var action: EnemyActionData
		if data.random_actions:
			action = _weighted_random_action(action_list)
		else:
			var action_idx: int = (turn_number - 1) % action_list.size()
			action = action_list[action_idx]
			if action.type == "wave_gap" and data.skip_wave_gap_threshold > 0.0 \
					and float(enemies[i].hp) / float(data.hp) < data.skip_wave_gap_threshold:
				action = action_list[(action_idx + 1) % action_list.size()]
		if enemies[i].is_charging and action.type in ATTACK_TYPES_FOR_CHARGE:
			var doubled := EnemyActionData.new()
			doubled.type = action.type
			doubled.value = action.value * 2
			doubled.count = action.count
			_pending_actions[i] = doubled
		else:
			_pending_actions[i] = action
		if _pending_actions[i].type == "mirror_attack":
			var resolved := EnemyActionData.new()
			resolved.type = "mirror_attack"
			if _boss_copied_cards.is_empty():
				resolved.value = action.value
				resolved.display_label = "攻击"
			else:
				var chosen: CardData = _boss_copied_cards[randi() % _boss_copied_cards.size()]
				resolved.value = chosen.effects[0].value
				resolved.display_label = chosen.card_name
			_pending_actions[i] = resolved

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
	if card.is_curse or card.is_zahuorumuo:
		return false
	if card.cost > energy:
		return false
	if card.card_type == "身法" and hand.any(func(c: CardData) -> bool: return c.is_kong_ju):
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
	if card.card_type == "招式":
		RelicEngine.apply_on_attack_played(_relics, self)
		player.first_attack_bonus = 0
	var si_gained := player.sword_intent - si_before
	if si_gained > 0:
		player_gained_sword_intent.emit(si_gained)
	var bao_nu_count: int = 0
	for c in hand:
		if c.is_bao_nu:
			bao_nu_count += 1
	if bao_nu_count > 0:
		player.hp = max(0, player.hp - bao_nu_count * 2)
		player_damaged.emit(bao_nu_count * 2)
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
	var zao_count: int = 0
	for card: CardData in hand:
		if card.is_zahuorumuo:
			zao_count += 1
	for _z in zao_count:
		var victims: Array[int] = []
		for idx in hand.size():
			if not hand[idx].is_zahuorumuo and not hand[idx].is_curse:
				victims.append(idx)
		if not victims.is_empty():
			var victim_idx: int = victims[randi() % victims.size()]
			_exhaust_pile.append(hand[victim_idx])
			hand.remove_at(victim_idx)
	var bei_shang_count: int = 0
	for c in hand:
		if c.is_bei_shang:
			bei_shang_count += 1
	for _b in bei_shang_count:
		var non_curse_indices: Array[int] = []
		for idx in hand.size():
			var c: CardData = hand[idx]
			if not c.is_curse and not c.is_zahuorumuo and not c.is_venom \
					and not c.is_ye_huo and not c.is_bao_nu and not c.is_kong_ju and not c.is_bei_shang:
				non_curse_indices.append(idx)
		if non_curse_indices.is_empty():
			break
		var victim_idx: int = non_curse_indices[randi() % non_curse_indices.size()]
		_discard_pile.append(hand[victim_idx])
		hand.remove_at(victim_idx)
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
		var ye_huo_count: int = 0
		for c in _draw_pile:
			if c.is_ye_huo:
				ye_huo_count += 1
		for c in _discard_pile:
			if c.is_ye_huo:
				ye_huo_count += 1
		for c in _exhaust_pile:
			if c.is_ye_huo:
				ye_huo_count += 1
		for c in hand:
			if c.is_ye_huo:
				ye_huo_count += 1
		if ye_huo_count > 0:
			player.hp = max(0, player.hp - ye_huo_count * 2)
			player_damaged.emit(ye_huo_count * 2)
	if turn_number == 1:
		RelicEngine.apply_combat_start(_relics, self)
	RelicEngine.apply_turn_start(_relics, self)
	if player.next_block_halved:
		player.block = player.block / 2
		player.next_block_halved = false
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

func can_play_card(card: CardData) -> bool:
	if card.is_curse or card.is_zahuorumuo:
		return false
	if card.card_type == "身法" and hand.any(func(c: CardData) -> bool: return c.is_kong_ju):
		return false
	return true

func draw_cards(n: int) -> void:
	var actual: int = max(0, n - player.draw_reduction)
	player.draw_reduction = 0
	_draw_cards(actual)

func _draw_cards(n: int) -> void:
	for _i in n:
		_refill_draw_pile_if_needed()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _enemy_attack(attacker: Combatant, value: int, hits: int = 1) -> void:
	var hp_before: int = player.hp
	for _h in hits:
		EffectResolver.apply_damage(attacker, player, value)
	var dmg: int = hp_before - player.hp
	if dmg > 0:
		took_damage = true
		player_damaged.emit(dmg)
	elif value > 0:
		RelicEngine.apply_on_block_success(_relics, self)
	attacker.weak = max(0, attacker.weak - 1)

func _heal(c: Combatant, amount: int) -> void:
	c.hp = mini(c.hp + amount, c.max_hp)

func _add_curses_to_discard(n: int) -> void:
	for _j in n:
		_discard_pile.append(CURSE_CARD.duplicate())

func _add_venoms_to_draw(n: int) -> void:
	for _j in n:
		_draw_pile.append(VENOM_CARD.duplicate())
	_draw_pile.shuffle()

func _add_zahuorumuo_to_discard(n: int) -> void:
	for _j in n:
		_discard_pile.append(ZAHUORUMUO_CARD.duplicate())

func _do_enemy_turn() -> void:
	for i in enemies.size():
		if enemies[i].hp <= 0:
			continue
		var data: EnemyData = _enemy_data_list[i]
		enemies[i].block = 0
		if data.passive_block_per_turn > 0:
			enemies[i].add_block(data.passive_block_per_turn)
		enemies[i].vulnerable = max(0, enemies[i].vulnerable - 1)
		var action: EnemyActionData = get_enemy_action(i)
		enemies[i].is_charging = false
		match action.type:
			"attack":
				_enemy_attack(enemies[i], action.value)
			"attack_weak":
				_enemy_attack(enemies[i], action.value)
				player.add_weak(1)
			"attack_vulnerable":
				_enemy_attack(enemies[i], action.value)
				player.add_vulnerable(1)
			"multi_attack":
				_enemy_attack(enemies[i], action.value, action.count)
			"charge":
				enemies[i].is_charging = true
			"pre_charge":
				pass
			"steal_block":
				var stolen: int = player.block
				player.block = 0
				if stolen > 0:
					enemies[i].add_block(stolen)
				else:
					enemies[i].strength += 3
			"group_strengthen":
				for j in enemies.size():
					if enemies[j].hp > 0:
						enemies[j].strength += action.value
			"group_block":
				for j in enemies.size():
					if enemies[j].hp > 0:
						enemies[j].add_block(action.value)
			"poison":
				_add_venoms_to_draw(action.value)
			"attack_curse":
				_enemy_attack(enemies[i], action.value)
				_add_curses_to_discard(action.count)
			"block_curse":
				enemies[i].add_block(action.value)
				_add_curses_to_discard(action.count)
			"discard_curse":
				_add_curses_to_discard(action.value)
			"poison_curse":
				_add_venoms_to_draw(action.value)
				_add_curses_to_discard(action.count)
			"vampiric_attack":
				_enemy_attack(enemies[i], action.value)
				_heal(enemies[i], action.count)
			"devour_minion":
				var target_idx: int = -1
				for j in enemies.size():
					if j != i and enemies[j].hp > 0:
						if target_idx < 0 or enemies[j].hp < enemies[target_idx].hp:
							target_idx = j
				if target_idx >= 0:
					enemies[target_idx].hp = 0
					_heal(enemies[i], 20)
					enemies[i].strength += 3
			"revive_minions":
				for j in enemies.size():
					if j != i and enemies[j].hp <= 0:
						enemies[j].hp = enemies[j].max_hp
						enemies[j].block = 0
			"mirror_attack":
				_enemy_attack(enemies[i], action.value)
			"xin_mo_fanshi":
				_add_curses_to_discard(1)
			"attack_zahuorumuo":
				_enemy_attack(enemies[i], action.value)
				_add_zahuorumuo_to_discard(action.count)
			"attack_self_damage":
				_enemy_attack(enemies[i], action.value)
				enemies[i].hp = max(0, enemies[i].hp - action.count)
			"draw_penalty":
				player.draw_reduction += action.count
			"attack_half_next_block":
				_enemy_attack(enemies[i], action.value)
				player.next_block_halved = true
			"block_all_enemies":
				for j in enemies.size():
					if enemies[j].hp > 0:
						enemies[j].add_block(action.value)
			"aoe_all":
				_enemy_attack(enemies[i], action.value)
				for j in enemies.size():
					if enemies[j].hp > 0:
						enemies[j].hp = max(0, enemies[j].hp - action.value)
				if data.gains_strength_from_aoe:
					enemies[i].strength += 2
			"attack_bao_nu":
				_enemy_attack(enemies[i], action.value)
				for _k in action.count:
					_discard_pile.append(BAO_NU_CARD.duplicate())
			"attack_kong_ju":
				_enemy_attack(enemies[i], action.value)
				for _k in action.count:
					_discard_pile.append(KONG_JU_CARD.duplicate())
			"attack_bei_shang":
				_enemy_attack(enemies[i], action.value)
				for _k in action.count:
					_discard_pile.append(BEI_SHANG_CARD.duplicate())
			"attack_venom":
				_enemy_attack(enemies[i], action.value)
				_add_venoms_to_draw(action.count)
			"wave_gap":
				pass
			_:
				enemies[i].add_block(action.value)
		if data.copies_player_cards \
				and data.phase2_passive_threshold > 0.0 \
				and float(enemies[i].hp) / float(enemies[i].max_hp) < data.phase2_passive_threshold \
				and enemies[i].hp > 0:
			enemies[i].hp = max(0, enemies[i].hp - 3)
			enemies[i].strength += 3

func _check_end() -> bool:
	for i in enemies.size():
		if enemies[i].hp <= 0 and _enemy_data_list[i].death_kills_others:
			for j in enemies.size():
				if j != i:
					enemies[j].hp = 0
	var any_alive: bool = enemies.any(func(e: Combatant) -> bool: return e.hp > 0)
	if not any_alive:
		RelicEngine.apply_combat_end(_relics, self)
		combat_ended.emit("victory")
		return true
	if player.hp <= 0:
		for r: RelicData in _relics:
			if r.effect_type == RelicData.EffectType.PREVENT_DEATH_ONCE and not r.used:
				player.hp = 1
				r.used = true
				return false
		combat_ended.emit("game_over")
		return true
	return false

func _is_pure_damage_style(card: CardData) -> bool:
	if card.card_type != "招式" or card.effects.is_empty():
		return false
	for effect: CardEffectData in card.effects:
		if effect.type != "damage":
			return false
	return true
