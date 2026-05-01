class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var price: int = 0
@export var effects: Array[CardEffectData]
@export var is_venom: bool = false
@export var special_text: String = ""
@export var target_type: String = "single"
var is_upgraded: bool = false

func upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	card_name = card_name + "+"
	for effect: CardEffectData in effects:
		effect.value += effect.upgrade_bonus

func get_description() -> String:
	if is_venom:
		return "%s\n费用:%d  %s" % [card_name, cost, special_text]
	var dmg: int = 0
	var blk: int = 0
	var drw: int = 0
	var nrg: int = 0
	var wk: int = 0
	var vul: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":       dmg = effect.value
		elif effect.type == "block":      blk = effect.value
		elif effect.type == "draw":       drw = effect.value
		elif effect.type == "energy":     nrg = effect.value
		elif effect.type == "weak":       wk = effect.value
		elif effect.type == "vulnerable": vul = effect.value
	var desc: String = "%s\n费用:%d" % [card_name, cost]
	if dmg > 0: desc += "  攻:%d" % dmg
	if blk > 0: desc += "  挡:%d" % blk
	if drw > 0: desc += "  抽:%d" % drw
	if nrg > 0: desc += "  能:%d" % nrg
	if wk > 0: desc += "  虚弱:%d" % wk
	if vul > 0: desc += "  脆弱:%d" % vul
	return desc
