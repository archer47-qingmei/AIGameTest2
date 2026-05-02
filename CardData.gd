class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var price: int = 0
@export var effects: Array[CardEffectData]
@export var is_venom: bool = false
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
	if is_venom:
		return "%s\n费用:%d  %s" % [card_name, cost, special_text]
	var dmg: int = 0
	var dmg_times: int = 1
	var blk: int = 0
	var drw: int = 0
	var nrg: int = 0
	var wk: int = 0
	var vul: int = 0
	var si_cap: int = 0
	var si_bonus: int = 0
	var dpt: int = 0
	var si_retain: bool = false
	var si_blk: int = 0
	var next_turn_si: int = 0
	var next_turn_drw: int = 0
	var finisher_blk: int = 0
	var first_si_blk: int = 0
	var si_if_no_style: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":
			dmg = effect.value
			dmg_times = effect.times
		elif effect.type == "block":              blk = effect.value
		elif effect.type == "draw":               drw = effect.value
		elif effect.type == "energy":             nrg = effect.value
		elif effect.type == "weak":               wk = effect.value
		elif effect.type == "vulnerable":         vul = effect.value
		elif effect.type == "sword_intent_cap":   si_cap = effect.value
		elif effect.type == "sword_intent_bonus": si_bonus = effect.value
		elif effect.type == "draw_per_turn":      dpt = effect.value
		elif effect.type == "sword_intent_retain": si_retain = true
		elif effect.type == "sword_intent_block_bonus": si_blk = effect.value
		elif effect.type == "next_turn_si":              next_turn_si = effect.value
		elif effect.type == "next_turn_draw":            next_turn_drw = effect.value
		elif effect.type == "finisher_block":            finisher_blk = effect.value
		elif effect.type == "first_si_block":            first_si_blk = effect.value
		elif effect.type == "sword_intent_if_no_style":  si_if_no_style = effect.value
	var desc: String = "%s\n费用:%d" % [card_name, cost]
	if dmg > 0:
		if dmg_times > 1:
			desc += "  攻:%d×%d" % [dmg, dmg_times]
		else:
			desc += "  攻:%d" % dmg
		if sword_intent_consume_bonus > 0:
			desc += "(+剑意×%d)" % sword_intent_consume_bonus
	if blk > 0:       desc += "  挡:%d" % blk
	if drw > 0:       desc += "  抽:%d" % drw
	if nrg > 0:       desc += "  能:%d" % nrg
	if wk > 0:        desc += "  虚弱:%d" % wk
	if vul > 0:       desc += "  脆弱:%d" % vul
	if si_cap > 0:    desc += "  剑意上限+%d" % si_cap
	if si_bonus > 0:  desc += "  剑意加成+%d" % si_bonus
	if dpt > 0:       desc += "  多抽+%d张/回" % dpt
	if si_retain:          desc += "  剑意永续"
	if si_blk > 0:         desc += "  剑意挡加成+%d" % si_blk
	if next_turn_si > 0:   desc += "  下回合剑意+%d" % next_turn_si
	if next_turn_drw > 0:  desc += "  下回合抽+%d" % next_turn_drw
	if finisher_blk > 0:   desc += "  终结技触发挡+%d" % finisher_blk
	if first_si_blk > 0:   desc += "  首剑意+挡%d" % first_si_blk
	if si_if_no_style > 0: desc += "  无招式时+剑意%d" % si_if_no_style
	if retain_si_if_target_attacks: desc += "  攻击意图→剑意不消耗"
	return desc

func get_upgrade_preview_bbcode() -> String:
	if is_upgraded:
		return get_description()
	if is_venom:
		return "%s+\n费用:%d  %s" % [card_name, cost, special_text]
	var dmg: int = 0
	var dmg_bonus: int = 0
	var dmg_times: int = 1
	var blk: int = 0
	var blk_bonus: int = 0
	var drw: int = 0
	var drw_bonus: int = 0
	var nrg: int = 0
	var nrg_bonus: int = 0
	var wk: int = 0
	var wk_bonus: int = 0
	var vul: int = 0
	var vul_bonus: int = 0
	var si_cap: int = 0
	var si_cap_bonus: int = 0
	var si_bonus: int = 0
	var si_bonus_bonus: int = 0
	var dpt: int = 0
	var dpt_bonus: int = 0
	var si_retain: bool = false
	var si_blk: int = 0
	var si_blk_bonus: int = 0
	var next_turn_si: int = 0
	var next_turn_si_bonus: int = 0
	var next_turn_drw: int = 0
	var next_turn_drw_bonus: int = 0
	var finisher_blk: int = 0
	var finisher_blk_bonus: int = 0
	var first_si_blk: int = 0
	var first_si_blk_bonus: int = 0
	var si_if_no_style: int = 0
	var si_if_no_style_bonus: int = 0
	for effect: CardEffectData in effects:
		match effect.type:
			"damage":
				dmg = effect.value
				dmg_bonus = effect.upgrade_bonus
				dmg_times = effect.times
			"block":
				blk = effect.value
				blk_bonus = effect.upgrade_bonus
			"draw":
				drw = effect.value
				drw_bonus = effect.upgrade_bonus
			"energy":
				nrg = effect.value
				nrg_bonus = effect.upgrade_bonus
			"weak":
				wk = effect.value
				wk_bonus = effect.upgrade_bonus
			"vulnerable":
				vul = effect.value
				vul_bonus = effect.upgrade_bonus
			"sword_intent_cap":
				si_cap = effect.value
				si_cap_bonus = effect.upgrade_bonus
			"sword_intent_bonus":
				si_bonus = effect.value
				si_bonus_bonus = effect.upgrade_bonus
			"draw_per_turn":
				dpt = effect.value
				dpt_bonus = effect.upgrade_bonus
			"sword_intent_retain":
				si_retain = true
			"sword_intent_block_bonus":
				si_blk = effect.value
				si_blk_bonus = effect.upgrade_bonus
			"next_turn_si":
				next_turn_si = effect.value
				next_turn_si_bonus = effect.upgrade_bonus
			"next_turn_draw":
				next_turn_drw = effect.value
				next_turn_drw_bonus = effect.upgrade_bonus
			"finisher_block":
				finisher_blk = effect.value
				finisher_blk_bonus = effect.upgrade_bonus
			"first_si_block":
				first_si_blk = effect.value
				first_si_blk_bonus = effect.upgrade_bonus
			"sword_intent_if_no_style":
				si_if_no_style = effect.value
				si_if_no_style_bonus = effect.upgrade_bonus
	var desc: String = "%s+\n费用:%d" % [card_name, cost]
	if dmg > 0:
		if dmg_times > 1:
			desc += "  攻:%s×%d" % [_green(dmg, dmg_bonus), dmg_times]
		else:
			desc += "  攻:%s" % _green(dmg, dmg_bonus)
		if sword_intent_consume_bonus > 0:
			desc += "(+剑意×%d)" % sword_intent_consume_bonus
	if blk  > 0: desc += "  挡:%s"           % _green(blk,          blk_bonus)
	if drw  > 0: desc += "  抽:%s"           % _green(drw,          drw_bonus)
	if nrg  > 0: desc += "  能:%s"           % _green(nrg,          nrg_bonus)
	if wk   > 0: desc += "  虚弱:%s"         % _green(wk,           wk_bonus)
	if vul  > 0: desc += "  脆弱:%s"         % _green(vul,          vul_bonus)
	if si_cap        > 0: desc += "  剑意上限+%s"    % _green(si_cap,        si_cap_bonus)
	if si_bonus      > 0: desc += "  剑意加成+%s"    % _green(si_bonus,      si_bonus_bonus)
	if dpt           > 0: desc += "  多抽+%s张/回"   % _green(dpt,           dpt_bonus)
	if si_retain:         desc += "  剑意永续"
	if si_blk        > 0: desc += "  剑意挡加成+%s"  % _green(si_blk,        si_blk_bonus)
	if next_turn_si  > 0: desc += "  下回合剑意+%s"  % _green(next_turn_si,  next_turn_si_bonus)
	if next_turn_drw > 0: desc += "  下回合抽+%s"    % _green(next_turn_drw, next_turn_drw_bonus)
	if finisher_blk  > 0: desc += "  终结技触发挡+%s" % _green(finisher_blk,  finisher_blk_bonus)
	if first_si_blk  > 0: desc += "  首剑意+挡%s"    % _green(first_si_blk,  first_si_blk_bonus)
	if si_if_no_style > 0: desc += "  无招式时+剑意%s" % _green(si_if_no_style, si_if_no_style_bonus)
	if retain_si_if_target_attacks: desc += "  攻击意图→剑意不消耗"
	var any_bonus: bool = effects.any(func(e: CardEffectData) -> bool: return e.upgrade_bonus > 0)
	if not any_bonus:
		desc += "\n（属性不变）"
	return desc

static func _green(val: int, bonus: int) -> String:
	if bonus > 0:
		return "[color=green]%d[/color]" % (val + bonus)
	return "%d" % val
