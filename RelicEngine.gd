class_name RelicEngine
extends RefCounted

static func apply_combat_start(relics: Array[RelicData], engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		if relic.trigger == RelicData.Trigger.COMBAT_START:
			_apply(relic, engine)

static func apply_turn_start(relics: Array[RelicData], engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		if relic.trigger == RelicData.Trigger.TURN_START:
			_apply(relic, engine)

static func _apply(relic: RelicData, engine: CombatEngine) -> void:
	match relic.effect_type:
		RelicData.EffectType.ENERGY:
			engine.energy += relic.value
		RelicData.EffectType.HEAL_HP:
			engine.player.hp = mini(engine.player.hp + relic.value, engine.player.max_hp)
		RelicData.EffectType.BLOCK:
			engine.player.add_block(relic.value)
		RelicData.EffectType.DRAW:
			engine.draw_cards(relic.value)
		RelicData.EffectType.SWORD_INTENT:
			engine.player.sword_intent = mini(
				engine.player.sword_intent + relic.value,
				engine.player.sword_intent_cap
			)
