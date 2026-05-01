class_name RelicData
extends Resource

enum Trigger { COMBAT_START, TURN_START }
enum EffectType { ENERGY, HEAL_HP, BLOCK, DRAW }
enum Source { SHOP, CHEST }

@export var display_name: String = ""
@export var description: String = ""
@export var trigger: Trigger = Trigger.COMBAT_START
@export var effect_type: EffectType = EffectType.ENERGY
@export var value: int = 0
@export var price: int = 0
@export var source: Source = Source.SHOP
