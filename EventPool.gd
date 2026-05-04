class_name EventPool
extends RefCounted

const EVENTS: Array[String] = [
	"res://data/events/ling_shi_kuang_mai.tres",
	"res://data/events/po_miao_jie_su.tres",
	"res://data/events/qiu_xian_ku.tres",
	"res://data/events/yu_chan.tres",
	"res://data/events/du_shi.tres",
	"res://data/events/wu_dao_shi.tres",
	"res://data/events/liang_ge_xiu_shi.tres",
	"res://data/events/lao_xiu_shi_yan_dou.tres",
	"res://data/events/ku_jing.tres",
	"res://data/events/si_ceng_xiang_shi.tres",
	"res://data/events/ya_bi_ke_zi.tres",
	"res://data/events/jian_hen.tres",
	"res://data/events/piao_lai_de_fu_hui.tres",
	"res://data/events/bu_shi_zhe_yi_shi_de_yu.tres",
	"res://data/events/wu_ming_mu_bei.tres",
	"res://data/events/jing_hu_huan_jing.tres",
	"res://data/events/bu_shi_zhe_yi_shi_de_yan_shen.tres",
	"res://data/events/tian_di_rong_lu.tres",
	"res://data/events/xue_ji_tan.tres",
]

static func pick_event(player_state: PlayerState) -> EventData:
	var candidates: Array[EventData] = []
	for path in EVENTS:
		var event: EventData = load(path) as EventData
		if EventEngine.check_condition(event, player_state):
			candidates.append(event)
	if candidates.is_empty():
		# 无满足条件的事件时，保底返回第一个（NONE条件，必然通过）
		return load(EVENTS[0]) as EventData
	return candidates[randi() % candidates.size()]
