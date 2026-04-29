class_name Combatant
extends RefCounted

var display_name: String
var hp: int
var max_hp: int
var block: int
var weak: int = 0
var vulnerable: int = 0

func take_damage(amount: int) -> void:
	if amount <= block:
		block -= amount
	else:
		hp -= amount - block
		block = 0
	if hp < 0:
		hp = 0

func add_block(amount: int) -> void:
	block += amount

func add_weak(n: int) -> void:
	weak += n

func add_vulnerable(n: int) -> void:
	vulnerable += n
