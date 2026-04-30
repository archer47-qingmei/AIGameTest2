class_name RelicData
extends Resource

enum Trigger { COMBAT_START, TURN_START }

@export var display_name: String = ""
@export var description: String = ""
@export var trigger: Trigger = Trigger.COMBAT_START
@export var effect_type: String = ""
@export var value: int = 0
