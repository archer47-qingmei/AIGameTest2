class_name RelicData
extends Resource

enum Trigger { COMBAT_START, TURN_START, TURN_END, COMBAT_END, ON_EQUIP }
enum EffectType {
	ENERGY, HEAL_HP, BLOCK, DRAW, SWORD_INTENT,
	SELF_DAMAGE, SWORD_INTENT_CAP, MAX_HP_PERCENT,
	FIRST_TURN_DRAW_PENALTY, BLOCK_DRAIN
}

@export var display_name: String = ""
@export var description: String = ""
@export var trigger: Trigger = Trigger.COMBAT_START
@export var effect_type: EffectType = EffectType.ENERGY
@export var value: int = 0
@export var trigger_b: Trigger = Trigger.COMBAT_START
@export var effect_type_b: EffectType = EffectType.ENERGY
@export var value_b: int = 0
@export var has_effect_b: bool = false
@export var blocks_relic_purchase: bool = false
@export var price: int = 0
