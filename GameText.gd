class_name GameText
extends Object

static func get_buff_info(key: String) -> Dictionary:
	match key:
		"weak":
			return {"name": "虚弱", "description": "造成的伤害降低 25%，每回合结束减少 1 层。"}
		"vulnerable":
			return {"name": "脆弱", "description": "受到的伤害增加 25%，每回合结束减少 1 层。"}
		"strength":
			return {"name": "力量", "description": "每点力量使普通攻击伤害 +1。"}
		"sword_intent":
			return {"name": "剑意", "description": "积累剑意可提升下次攻击伤害，每层 +1 伤害，上限 10 层。"}
	return {"name": key, "description": "（暂无说明）"}
