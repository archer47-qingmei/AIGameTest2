class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> Array[int]:
	var hit_amounts: Array[int] = []
	for effect: CardEffectData in card.effects:
		for _i in effect.times:
			match effect.type:
				"damage":
					if defender != null:
						var dmg_bonus: int = 0
						if card.is_finisher:
							dmg_bonus = attacker.sword_intent * card.sword_intent_consume_bonus
						elif card.card_type == "招式":
							dmg_bonus = attacker.sword_intent * attacker.sword_intent_damage_bonus
						var hp_before := defender.hp
						apply_damage(attacker, defender, effect.value + dmg_bonus)
						hit_amounts.append(hp_before - defender.hp)
				"block":
					var blk_bonus: int = attacker.sword_intent * attacker.sword_intent_block_bonus
					attacker.add_block(effect.value + blk_bonus)
				"weak":
					if defender != null:
						defender.add_weak(effect.value)
				"vulnerable":
					if defender != null:
						defender.add_vulnerable(effect.value)
	if card.is_finisher:
		attacker.add_block(attacker.finisher_block_bonus)
		var skip_consume: bool = card.retain_si_if_target_attacks \
			and defender != null and defender.current_intent == "attack"
		if not skip_consume:
			attacker.sword_intent = 0
	elif card.card_type == "招式":
		var will_gain: bool = attacker.sword_intent < attacker.sword_intent_cap
		if will_gain and not attacker.gained_sword_intent_this_turn:
			attacker.add_block(attacker.first_si_block_bonus)
			attacker.gained_sword_intent_this_turn = true
		attacker.sword_intent = mini(attacker.sword_intent + 1, attacker.sword_intent_cap)
		attacker.played_style_this_turn = true
	return hit_amounts

static func preview_damage(card: CardData, attacker: Combatant, target: Combatant) -> Dictionary:
	for effect: CardEffectData in card.effects:
		if effect.type == "damage":
			var dmg_bonus: int = 0
			if card.is_finisher:
				dmg_bonus = attacker.sword_intent * card.sword_intent_consume_bonus
			elif card.card_type == "招式":
				dmg_bonus = attacker.sword_intent * attacker.sword_intent_damage_bonus
			var dmg: int = effect.value + dmg_bonus
			if attacker.weak > 0:
				dmg = int(dmg * 0.75)
			if target.vulnerable > 0:
				dmg = int(dmg * 1.5)
			var boosted: bool = (target.vulnerable > 0) or (dmg_bonus > 0)
			return {per_hit = dmg, hits = effect.times, boosted = boosted}
	return {}

static func apply_damage(source: Combatant, target: Combatant, amount: int) -> void:
	var dmg: int = amount
	if source.weak > 0:
		dmg = int(dmg * 0.75)
	if target.vulnerable > 0:
		dmg = int(dmg * 1.5)
	target.take_damage(dmg)
