class_name EventEffectData
extends Resource

enum EffectType {
	NOTHING,
	GAIN_GOLD,
	LOSE_GOLD,
	GAIN_HP,
	LOSE_HP,
	HEAL_PERCENT_MAX,
	HEAL_FULL,
	LOSE_HP_PERCENT_CURRENT,
	LOSE_MAX_HP_PERCENT,
	GAIN_RELIC,
	LOSE_RELIC_RANDOM,
	GAIN_CARD,
	GAIN_CURSE_CARD,
	REMOVE_CARD_CHOOSE,
	REMOVE_CARDS_TYPE,
	REMOVE_CARDS_RANDOM,
	UPGRADE_CARD_CHOOSE,
	UPGRADE_CARDS_TYPE,
	COPY_CARD_CHOOSE,
	GAIN_REINCARNATION_FRAGMENT,
	GAIN_MAX_HP_PERCENT,
	GAIN_ENERGY_CAP,
	COMBAT_ELITE_STUB
}

@export var effect_type: EffectType = EffectType.NOTHING
@export var value: int = 0
@export var probability: float = 1.0
@export var card_grade: int = 0
@export var relic_grade: int = 0
@export var card_type_filter: String = ""
@export var curse_card_path: String = ""
