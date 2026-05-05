class_name RelicEngine
extends RefCounted

static func apply_combat_start(relics: Array[RelicData], engine: CombatEngine) -> void:
	_apply_for_trigger(relics, RelicData.Trigger.COMBAT_START, engine)

static func apply_turn_start(relics: Array[RelicData], engine: CombatEngine) -> void:
	_apply_for_trigger(relics, RelicData.Trigger.TURN_START, engine)

static func apply_turn_end(relics: Array[RelicData], engine: CombatEngine) -> void:
	_apply_for_trigger(relics, RelicData.Trigger.TURN_END, engine)

static func apply_combat_end(relics: Array[RelicData], engine: CombatEngine) -> void:
	_apply_for_trigger(relics, RelicData.Trigger.COMBAT_END, engine)

static func apply_on_equip(relic: RelicData, player_state: PlayerState) -> void:
	if relic.trigger == RelicData.Trigger.ON_EQUIP:
		_apply_equip_effect(relic.effect_type, relic.value, player_state)
	if relic.has_effect_b and relic.trigger_b == RelicData.Trigger.ON_EQUIP:
		_apply_equip_effect(relic.effect_type_b, relic.value_b, player_state)

static func _apply_for_trigger(relics: Array[RelicData], trigger: RelicData.Trigger, engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		if relic.trigger == trigger:
			_apply_effect(relic.effect_type, relic.value, engine, relic)
		if relic.has_effect_b and relic.trigger_b == trigger:
			_apply_effect(relic.effect_type_b, relic.value_b, engine, relic)

static func _apply_effect(effect_type: RelicData.EffectType, value: int, engine: CombatEngine, relic: RelicData = null) -> void:
	match effect_type:
		RelicData.EffectType.ENERGY:
			engine.energy += value
		RelicData.EffectType.HEAL_HP:
			engine.player.hp = mini(engine.player.hp + value, engine.player.max_hp)
		RelicData.EffectType.BLOCK:
			engine.player.add_block(value)
		RelicData.EffectType.DRAW:
			engine.draw_cards(value)
		RelicData.EffectType.SWORD_INTENT:
			engine.player.sword_intent = mini(
				engine.player.sword_intent + value, engine.player.sword_intent_cap
			)
		RelicData.EffectType.SELF_DAMAGE:
			engine.player.hp = max(0, engine.player.hp - value)
		RelicData.EffectType.ENERGY_CAP:
			engine.energy_cap += value
		RelicData.EffectType.FIRST_TURN_DRAW_PENALTY:
			if engine.turn_number == 1:
				for i in value:
					if not engine.hand.is_empty():
						engine.hand.pop_back()
		RelicData.EffectType.BLOCK_DRAIN:
			if engine.player.block > 0:
				engine.player.block -= 1
			else:
				engine.player.hp = max(0, engine.player.hp - 1)
		RelicData.EffectType.FIRST_TURN_ENERGY:
			if engine.turn_number == 1:
				engine.energy += value
		RelicData.EffectType.SECOND_TURN_ENERGY_PENALTY:
			if engine.turn_number == 2:
				engine.energy = max(2, engine.energy - value)
		RelicData.EffectType.ENERGY_IF_LOW_HP:
			if engine.player.hp < int(engine.player.max_hp * 0.3):
				engine.energy += value
		RelicData.EffectType.DRAW_IF_LOW_HP:
			if engine.player.hp < int(engine.player.max_hp * 0.3):
				engine.draw_cards(value)
		RelicData.EffectType.HEAL_ONCE_IF_HALF_HP:
			if relic == null or relic.used:
				return
			if engine.player.hp < int(engine.player.max_hp * 0.5):
				engine.player.hp = mini(engine.player.hp + value, engine.player.max_hp)
				relic.used = true
		RelicData.EffectType.PREVENT_DEATH_ONCE:
			pass
		RelicData.EffectType.FIRST_ATTACK_BONUS:
			engine.player.first_attack_bonus += value
		RelicData.EffectType.GOLD_IF_NO_DAMAGE:
			if not engine.took_damage:
				engine.combat_gold += value

static func _apply_equip_effect(effect_type: RelicData.EffectType, value: int, player_state: PlayerState) -> void:
	match effect_type:
		RelicData.EffectType.MAX_HP_PERCENT:
			var reduction: int = max(1, int(player_state.max_hp * value / 100.0))
			player_state.max_hp = max(1, player_state.max_hp - reduction)
			player_state.hp = mini(player_state.hp, player_state.max_hp)
		RelicData.EffectType.REMOVE_CARDS:
			for i in value:
				if player_state.deck.is_empty():
					break
				player_state.deck.remove_at(randi() % player_state.deck.size())
		RelicData.EffectType.BUFF_BASE_ATTACKS:
			for card: CardData in player_state.deck:
				if card.card_type == "招式" and not card.is_upgraded:
					for effect: CardEffectData in card.effects:
						if effect.type == "damage":
							effect.value += value
		RelicData.EffectType.REDUCE_SKILL_COST:
			for card: CardData in player_state.deck:
				if card.card_type == "功法":
					card.cost = maxi(1, card.cost - 1)
		RelicData.EffectType.COPY_RANDOM_CARD:
			if not player_state.deck.is_empty():
				var src: CardData = player_state.deck[randi() % player_state.deck.size()]
				player_state.deck.append(src.duplicate())
		RelicData.EffectType.MAX_DECK_SIZE:
			player_state.max_deck_size += value
		RelicData.EffectType.GOLD_ON_EVENT:
			player_state.gold += value

static func apply_on_event_enter(relics: Array[RelicData], player_state: PlayerState) -> void:
	for relic: RelicData in relics:
		_apply_equip_effect(relic.effect_type, relic.value, player_state)
		if relic.has_effect_b:
			_apply_equip_effect(relic.effect_type_b, relic.value_b, player_state)

static func apply_on_attack_played(relics: Array[RelicData], engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		_apply_on_attack_effect(relic.effect_type, relic.value, engine)
		if relic.has_effect_b:
			_apply_on_attack_effect(relic.effect_type_b, relic.value_b, engine)

static func apply_on_block_success(relics: Array[RelicData], engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		_apply_on_block_effect(relic.effect_type, relic.value, engine)
		if relic.has_effect_b:
			_apply_on_block_effect(relic.effect_type_b, relic.value_b, engine)

static func _apply_on_attack_effect(effect_type: RelicData.EffectType, value: int, engine: CombatEngine) -> void:
	match effect_type:
		RelicData.EffectType.BLOCK_ON_ATTACK_PLAYED:
			engine.player.add_block(value)

static func _apply_on_block_effect(effect_type: RelicData.EffectType, value: int, engine: CombatEngine) -> void:
	match effect_type:
		RelicData.EffectType.GOLD_ON_BLOCK:
			if engine._block_gold_count < 15:
				engine.combat_gold += 1
				engine._block_gold_count += 1
