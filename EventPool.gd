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
]

static func pick_event(player_state: PlayerState) -> EventData:
	var candidates: Array[EventData] = []
	for path in EVENTS:
		var event: EventData = load(path) as EventData
		if EventEngine.check_condition(event, player_state):
			candidates.append(event)
	if candidates.is_empty():
		return load(EVENTS[0]) as EventData
	return candidates[randi() % candidates.size()]
