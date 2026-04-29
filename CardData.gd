class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var effects: Array[CardEffectData]
var is_upgraded: bool = false

func upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	card_name = card_name + "+"
	for effect: CardEffectData in effects:
		effect.value += effect.upgrade_bonus

func get_description() -> String:
	var dmg: int = 0
	var blk: int = 0
	var drw: int = 0
	var nrg: int = 0
	var wk: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":   dmg = effect.value
		elif effect.type == "block":  blk = effect.value
		elif effect.type == "draw":   drw = effect.value
		elif effect.type == "energy": nrg = effect.value
		elif effect.type == "weak":   wk = effect.value
	var desc: String = "%s\n费用:%d" % [card_name, cost]
	if dmg > 0: desc += "  攻:%d" % dmg
	if blk > 0: desc += "  挡:%d" % blk
	if drw > 0: desc += "  抽:%d" % drw
	if nrg > 0: desc += "  能:%d" % nrg
	if wk > 0: desc += "  虚弱:%d" % wk
	return desc
