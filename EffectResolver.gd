class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> void:
	for effect: CardEffectData in card.effects:
		if effect.type == "damage":
			if defender != null:
				var bonus: int = 0
				if card.is_finisher:
					bonus = attacker.sword_intent * card.sword_intent_consume_bonus
				elif card.card_type == "招式":
					bonus = attacker.sword_intent * attacker.sword_intent_damage_bonus
				apply_damage(attacker, defender, effect.value + bonus)
		elif effect.type == "block":
			attacker.add_block(effect.value)
		elif effect.type == "weak":
			if defender != null:
				defender.add_weak(effect.value)
		elif effect.type == "vulnerable":
			if defender != null:
				defender.add_vulnerable(effect.value)
	if card.is_finisher:
		attacker.sword_intent = 0
	elif card.card_type == "招式":
		attacker.sword_intent = mini(attacker.sword_intent + 1, attacker.sword_intent_cap)

static func apply_damage(source: Combatant, target: Combatant, amount: int) -> void:
	var dmg: int = amount
	if source.weak > 0:
		dmg = int(dmg * 0.75)
	if target.vulnerable > 0:
		dmg = int(dmg * 1.5)
	target.take_damage(dmg)
