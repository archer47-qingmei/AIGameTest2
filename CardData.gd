class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var effects: Array[CardEffectData]

func get_description() -> String:
	var dmg: int = 0
	var blk: int = 0
	var drw: int = 0
	var nrg: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":   dmg = effect.value
		elif effect.type == "block":  blk = effect.value
		elif effect.type == "draw":   drw = effect.value
		elif effect.type == "energy": nrg = effect.value
	var desc: String = "%s\n费用:%d" % [card_name, cost]
	if dmg > 0: desc += "  攻:%d" % dmg
	if blk > 0: desc += "  挡:%d" % blk
	if drw > 0: desc += "  抽:%d" % drw
	if nrg > 0: desc += "  能:%d" % nrg
	return desc
