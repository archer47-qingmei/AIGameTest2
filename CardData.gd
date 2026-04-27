class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var effects: Array[CardEffectData]

func get_description() -> String:
	var dmg: int = 0
	var blk: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":
			dmg = effect.value
		elif effect.type == "block":
			blk = effect.value
	return "%s\n费用:%d  攻:%d  挡:%d" % [card_name, cost, dmg, blk]
