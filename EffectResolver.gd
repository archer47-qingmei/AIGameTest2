class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> void:
	if card.damage > 0:
		defender.take_damage(card.damage)
	if card.block > 0:
		attacker.add_block(card.block)
