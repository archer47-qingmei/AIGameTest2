class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant, out_block: Array[int]) -> Array[int]:
	var hit_amounts: Array[int] = []
	out_block.clear()
	for effect: CardEffectData in card.effects:
		for _i in effect.times:
			match effect.type:
				"damage":
					if defender != null:
						var hp_before := defender.hp
						var blk_before := defender.block
						apply_damage(attacker, defender, effect.value + _dmg_bonus(card, attacker))
						hit_amounts.append(hp_before - defender.hp)
						out_block.append(blk_before - defender.block)
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
			var dmg_bonus: int = _dmg_bonus(card, attacker)
			var dmg: int = _apply_modifiers(effect.value + dmg_bonus, attacker, target)
			var boosted: bool = (target.vulnerable > 0) or (dmg_bonus > 0)
			return {per_hit = dmg, hits = effect.times, boosted = boosted}
	return {}

static func apply_damage(source: Combatant, target: Combatant, amount: int) -> void:
	target.take_damage(_apply_modifiers(amount + source.strength, source, target))

static func _dmg_bonus(card: CardData, attacker: Combatant) -> int:
	if card.is_finisher:
		return attacker.sword_intent * card.sword_intent_consume_bonus
	if card.card_type == "招式":
		return attacker.sword_intent * attacker.sword_intent_damage_bonus
	return 0

static func _apply_modifiers(dmg: int, source: Combatant, target: Combatant) -> int:
	if source.weak > 0:
		dmg = int(dmg * 0.75)
	if target.vulnerable > 0:
		dmg = int(dmg * 1.5)
	return dmg
