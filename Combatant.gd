class_name Combatant
extends RefCounted

var display_name: String
var hp: int
var max_hp: int
var block: int
var weak: int = 0
var vulnerable: int = 0
var sword_intent: int = 0
var sword_intent_cap: int = 10
var sword_intent_damage_bonus: int = 1
var draw_per_turn: int = 0
var sword_intent_retain: bool = false
var sword_intent_block_bonus: int = 0  # 心剑：打身法时每层剑意额外+N格挡
var played_style_this_turn: bool = false
var gained_sword_intent_this_turn: bool = false
var first_si_block_bonus: int = 0  # 意随心发：每回合首次获得剑意时+N格挡
var next_turn_sword_intent: int = 0
var next_turn_draw: int = 0
var finisher_block_bonus: int = 0
var current_intent: String = ""
var is_charging: bool = false
var charge_value: int = 0

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
