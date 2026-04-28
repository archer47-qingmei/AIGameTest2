class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> void:
	for effect: CardEffectData in card.effects:
		if effect.type == "damage":
			apply_damage(attacker, defender, effect.value)
		elif effect.type == "block":
			attacker.add_block(effect.value)
		elif effect.type == "weak":
			defender.add_weak(effect.value)

static func apply_damage(source: Combatant, target: Combatant, amount: int) -> void:
	var dmg: int = amount
	if source.weak > 0:
		dmg = int(dmg * 0.75)
	target.take_damage(dmg)
