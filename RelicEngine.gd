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
			_apply_effect(relic.effect_type, relic.value, engine)
		if relic.has_effect_b and relic.trigger_b == trigger:
			_apply_effect(relic.effect_type_b, relic.value_b, engine)

static func _apply_effect(effect_type: RelicData.EffectType, value: int, engine: CombatEngine) -> void:
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
		RelicData.EffectType.SWORD_INTENT_CAP:
			engine.player.sword_intent_cap += value
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

static func _apply_equip_effect(effect_type: RelicData.EffectType, value: int, player_state: PlayerState) -> void:
	match effect_type:
		RelicData.EffectType.MAX_HP_PERCENT:
			var reduction: int = max(1, int(player_state.max_hp * value / 100.0))
			player_state.max_hp = max(1, player_state.max_hp - reduction)
			player_state.hp = mini(player_state.hp, player_state.max_hp)
