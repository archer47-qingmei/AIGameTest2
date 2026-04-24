class_name Combatant
extends RefCounted

var display_name: String
var hp: int
var max_hp: int
var block: int

func take_damage(amount: int) -> void:
	var remaining: int = amount - block
	block = 0
	if remaining > 0:
		hp -= remaining
	if hp < 0:
		hp = 0

func add_block(amount: int) -> void:
	block += amount
