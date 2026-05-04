class_name EventData
extends Resource

enum AppearCondition {
	NONE,
	AFTER_REALM,
	MIN_DECK_SIZE,
	MIN_RELIC_COUNT,
	MIN_HP_PERCENT,
	MIN_UNUPGRADED_ATTACKS
}

@export var display_name: String = ""
@export var mood: String = ""
@export var flavor_text: String = ""
@export var choices: Array[EventChoiceData] = []
@export var appear_condition: AppearCondition = AppearCondition.NONE
@export var appear_condition_value: int = 0
@export var character_requirement: String = ""
