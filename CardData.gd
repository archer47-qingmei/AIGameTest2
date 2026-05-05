class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var price: int = 0
@export var effects: Array[CardEffectData]
@export var is_venom: bool = false
@export var is_curse: bool = false
@export var is_zahuorumuo: bool = false
@export var is_ye_huo: bool = false
@export var is_bao_nu: bool = false
@export var is_kong_ju: bool = false
@export var is_bei_shang: bool = false
@export var special_text: String = ""
@export var target_type: String = "single"
@export var card_type: String = ""
@export var is_finisher: bool = false
@export var sword_intent_consume_bonus: int = 0
@export var retain_si_if_target_attacks: bool = false
var is_upgraded: bool = false

func upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	card_name = card_name + "+"
	for effect: CardEffectData in effects:
		effect.value += effect.upgrade_bonus

func get_description() -> String:
	if is_curse or is_zahuorumuo:
		return "%s\n%s" % [card_name, special_text]
	if is_venom:
		return "%s\n费用:%d  %s" % [card_name, cost, special_text]
	return _format_description(card_name, false)

func get_description_with_dmg(real_dmg: int) -> String:
	if is_curse or is_zahuorumuo:
		return "%s\n%s" % [card_name, special_text]
	if is_venom:
		return "%s\n费用:%d  %s" % [card_name, cost, special_text]
	return _format_description(card_name, false, real_dmg)

func get_upgrade_preview_bbcode() -> String:
	if is_upgraded or is_curse or is_zahuorumuo:
		return get_description()
	if is_venom:
		return "%s+\n费用:%d  %s" % [card_name, cost, special_text]
	return _format_description(card_name + "+", true)

func _format_description(name: String, show_bonuses: bool, real_dmg: int = -1) -> String:
	var v: Dictionary = _collect_effects()
	var desc: String = "%s\n费用:%d" % [name, cost]
	if v.dmg > 0:
		var dmg_str: String
		if real_dmg >= 0:
			dmg_str = _fmt_real_dmg(real_dmg, v.dmg)
		else:
			dmg_str = _fmt(v.dmg, v.dmg_bonus, show_bonuses)
		if v.dmg_times > 1:
			desc += "  攻:%s×%d" % [dmg_str, v.dmg_times]
		else:
			desc += "  攻:%s" % dmg_str
		if sword_intent_consume_bonus > 0:
			desc += "(+剑意×%d)" % sword_intent_consume_bonus
	if v.blk > 0:            desc += "  挡:%s" % _fmt(v.blk, v.blk_bonus, show_bonuses)
	if v.drw > 0:            desc += "  抽:%s" % _fmt(v.drw, v.drw_bonus, show_bonuses)
	if v.nrg > 0:            desc += "  能:%s" % _fmt(v.nrg, v.nrg_bonus, show_bonuses)
	if v.wk > 0:             desc += "  虚弱:%s" % _fmt(v.wk, v.wk_bonus, show_bonuses)
	if v.vul > 0:            desc += "  脆弱:%s" % _fmt(v.vul, v.vul_bonus, show_bonuses)
	if v.si_cap > 0:         desc += "  剑意上限+%s" % _fmt(v.si_cap, v.si_cap_bonus, show_bonuses)
	if v.si_bonus > 0:       desc += "  剑意加成+%s" % _fmt(v.si_bonus, v.si_bonus_bonus, show_bonuses)
	if v.dpt > 0:            desc += "  多抽+%s张/回" % _fmt(v.dpt, v.dpt_bonus, show_bonuses)
	if v.si_retain:          desc += "  剑意永续"
	if v.si_blk > 0:         desc += "  剑意挡加成+%s" % _fmt(v.si_blk, v.si_blk_bonus, show_bonuses)
	if v.next_turn_si > 0:   desc += "  下回合剑意+%s" % _fmt(v.next_turn_si, v.next_turn_si_bonus, show_bonuses)
	if v.next_turn_drw > 0:  desc += "  下回合抽+%s" % _fmt(v.next_turn_drw, v.next_turn_drw_bonus, show_bonuses)
	if v.finisher_blk > 0:   desc += "  终结技触发挡+%s" % _fmt(v.finisher_blk, v.finisher_blk_bonus, show_bonuses)
	if v.first_si_blk > 0:   desc += "  首剑意+挡%s" % _fmt(v.first_si_blk, v.first_si_blk_bonus, show_bonuses)
	if v.si_if_no_style > 0: desc += "  无招式时+剑意%s" % _fmt(v.si_if_no_style, v.si_if_no_style_bonus, show_bonuses)
	if retain_si_if_target_attacks:
		desc += "  攻击意图→剑意不消耗"
	if show_bonuses:
		var any_bonus: bool = effects.any(func(e: CardEffectData) -> bool: return e.upgrade_bonus > 0)
		if not any_bonus:
			desc += "\n（属性不变）"
	return desc

func _collect_effects() -> Dictionary:
	var v: Dictionary = {
		"dmg": 0, "dmg_bonus": 0, "dmg_times": 1,
		"blk": 0, "blk_bonus": 0,
		"drw": 0, "drw_bonus": 0,
		"nrg": 0, "nrg_bonus": 0,
		"wk": 0, "wk_bonus": 0,
		"vul": 0, "vul_bonus": 0,
		"si_cap": 0, "si_cap_bonus": 0,
		"si_bonus": 0, "si_bonus_bonus": 0,
		"dpt": 0, "dpt_bonus": 0,
		"si_retain": false,
		"si_blk": 0, "si_blk_bonus": 0,
		"next_turn_si": 0, "next_turn_si_bonus": 0,
		"next_turn_drw": 0, "next_turn_drw_bonus": 0,
		"finisher_blk": 0, "finisher_blk_bonus": 0,
		"first_si_blk": 0, "first_si_blk_bonus": 0,
		"si_if_no_style": 0, "si_if_no_style_bonus": 0,
	}
	for effect: CardEffectData in effects:
		match effect.type:
			"damage":
				v.dmg = effect.value
				v.dmg_bonus = effect.upgrade_bonus
				v.dmg_times = effect.times
			"block":
				v.blk = effect.value
				v.blk_bonus = effect.upgrade_bonus
			"draw":
				v.drw = effect.value
				v.drw_bonus = effect.upgrade_bonus
			"energy":
				v.nrg = effect.value
				v.nrg_bonus = effect.upgrade_bonus
			"weak":
				v.wk = effect.value
				v.wk_bonus = effect.upgrade_bonus
			"vulnerable":
				v.vul = effect.value
				v.vul_bonus = effect.upgrade_bonus
			"sword_intent_cap":
				v.si_cap = effect.value
				v.si_cap_bonus = effect.upgrade_bonus
			"sword_intent_bonus":
				v.si_bonus = effect.value
				v.si_bonus_bonus = effect.upgrade_bonus
			"draw_per_turn":
				v.dpt = effect.value
				v.dpt_bonus = effect.upgrade_bonus
			"sword_intent_retain":
				v.si_retain = true
			"sword_intent_block_bonus":
				v.si_blk = effect.value
				v.si_blk_bonus = effect.upgrade_bonus
			"next_turn_si":
				v.next_turn_si = effect.value
				v.next_turn_si_bonus = effect.upgrade_bonus
			"next_turn_draw":
				v.next_turn_drw = effect.value
				v.next_turn_drw_bonus = effect.upgrade_bonus
			"finisher_block":
				v.finisher_blk = effect.value
				v.finisher_blk_bonus = effect.upgrade_bonus
			"first_si_block":
				v.first_si_blk = effect.value
				v.first_si_blk_bonus = effect.upgrade_bonus
			"sword_intent_if_no_style":
				v.si_if_no_style = effect.value
				v.si_if_no_style_bonus = effect.upgrade_bonus
	return v

static func _fmt(val: int, bonus: int, show_bonus: bool) -> String:
	if show_bonus and bonus > 0:
		return "[color=green]%d[/color]" % (val + bonus)
	return "%d" % val

static func _fmt_real_dmg(real_dmg: int, base_dmg: int) -> String:
	if real_dmg > base_dmg:
		return "[color=green]%d[/color]" % real_dmg
	if real_dmg < base_dmg:
		return "[color=red]%d[/color]" % real_dmg
	return "%d" % real_dmg
