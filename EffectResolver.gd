class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> void:
	for effect: CardEffectData in card.effects:
		if effect.type == "damage":
			defender.take_damage(effect.value)
		elif effect.type == "block":
			attacker.add_block(effect.value)
