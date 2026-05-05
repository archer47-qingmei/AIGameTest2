class_name EventEngine
extends RefCounted

static func check_condition(event: EventData, player_state: PlayerState) -> bool:
	if event.character_requirement != "" and event.character_requirement != player_state.character:
		return false
	match event.appear_condition:
		EventData.AppearCondition.NONE:
			return true
		# 境界系统尚未实装，暂时无条件通过
		EventData.AppearCondition.AFTER_REALM:
			return true
		EventData.AppearCondition.MIN_DECK_SIZE:
			return player_state.deck.size() >= event.appear_condition_value
		EventData.AppearCondition.MIN_RELIC_COUNT:
			return player_state.relics.size() >= event.appear_condition_value
		EventData.AppearCondition.MIN_HP_PERCENT:
			return player_state.hp * 100 >= player_state.max_hp * event.appear_condition_value
		EventData.AppearCondition.MIN_UNUPGRADED_ATTACKS:
			var count: int = 0
			for c: CardData in player_state.deck:
				if c.card_type == "招式" and not c.is_upgraded:
					count += 1
			return count >= event.appear_condition_value
		_:
			return false

static func check_choice_available(choice: EventChoiceData, player_state: PlayerState) -> bool:
	return choice.cost_gold == 0 or player_state.gold >= choice.cost_gold

static func apply_immediate_effects(choice: EventChoiceData, player_state: PlayerState) -> Array[EventEffectData]:
	var interactive: Array[EventEffectData] = []
	for effect: EventEffectData in choice.effects:
		if _is_interactive(effect):
			interactive.append(effect)
		else:
			_apply_effect(effect, player_state)
	return interactive

static func apply_interactive_effect(effect: EventEffectData, selected_card: CardData, player_state: PlayerState) -> void:
	match effect.effect_type:
		EventEffectData.EffectType.UPGRADE_CARD_CHOOSE:
			selected_card.upgrade()
		EventEffectData.EffectType.REMOVE_CARD_CHOOSE:
			player_state.deck.erase(selected_card)
		EventEffectData.EffectType.COPY_CARD_CHOOSE:
			player_state.deck.append(selected_card.duplicate())

static func describe_effects(choice: EventChoiceData) -> String:
	var parts: Array[String] = []
	for effect: EventEffectData in choice.effects:
		var desc: String = _describe_single(effect)
		if not desc.is_empty():
			parts.append(desc)
	return "、".join(parts) if not parts.is_empty() else "无事发生"

static func _is_interactive(effect: EventEffectData) -> bool:
	return effect.effect_type in [
		EventEffectData.EffectType.UPGRADE_CARD_CHOOSE,
		EventEffectData.EffectType.REMOVE_CARD_CHOOSE,
		EventEffectData.EffectType.COPY_CARD_CHOOSE,
	]

static func _apply_effect(effect: EventEffectData, player_state: PlayerState) -> void:
	if effect.probability < 1.0 and randf() > effect.probability:
		return
	match effect.effect_type:
		EventEffectData.EffectType.NOTHING:
			pass
		EventEffectData.EffectType.GAIN_GOLD:
			player_state.gold += effect.value
		EventEffectData.EffectType.LOSE_GOLD:
			player_state.gold = maxi(0, player_state.gold - effect.value)
		EventEffectData.EffectType.GAIN_HP:
			player_state.hp = mini(player_state.hp + effect.value, player_state.max_hp)
		EventEffectData.EffectType.LOSE_HP:
			player_state.hp = maxi(1, player_state.hp - effect.value)
		EventEffectData.EffectType.HEAL_PERCENT_MAX:
			player_state.hp = mini(player_state.hp + int(player_state.max_hp * effect.value / 100.0), player_state.max_hp)
		EventEffectData.EffectType.HEAL_FULL:
			player_state.hp = player_state.max_hp
		EventEffectData.EffectType.LOSE_HP_PERCENT_CURRENT:
			player_state.hp = maxi(1, player_state.hp - int(player_state.hp * effect.value / 100.0))
		EventEffectData.EffectType.LOSE_MAX_HP_PERCENT:
			var loss: int = int(player_state.max_hp * effect.value / 100.0)
			player_state.max_hp = maxi(1, player_state.max_hp - loss)
			player_state.hp = mini(player_state.hp, player_state.max_hp)
		# RelicData 无品级字段，暂从全池随机；relic_grade 仅用于描述文本
		EventEffectData.EffectType.GAIN_RELIC:
			if not CardPool.RELICS.is_empty():
				var idx: int = randi() % CardPool.RELICS.size()
				var relic: RelicData = (load(CardPool.RELICS[idx]) as RelicData).duplicate()
				player_state.relics.append(relic)
				RelicEngine.apply_on_equip(relic, player_state)
		EventEffectData.EffectType.GAIN_CURSE_CARD:
			var path: String = effect.curse_card_path if effect.curse_card_path != "" else "res://data/cards/xin_mo.tres"
			var curse: CardData = (load(path) as CardData).duplicate()
			player_state.deck.append(curse)
		EventEffectData.EffectType.REMOVE_CARDS_TYPE:
			var new_deck: Array[CardData] = []
			for c: CardData in player_state.deck:
				var remove: bool = false
				match effect.card_type_filter:
					"心魔": remove = c.is_curse
					"走火入魔": remove = c.is_zahuorumuo
					"诅咒": remove = c.is_curse or c.is_zahuorumuo
					"基础招式": remove = (c.card_type == "招式" and not c.is_upgraded)
					"基础身法": remove = (c.card_type == "身法" and not c.is_upgraded)
					_: remove = (c.card_type == effect.card_type_filter)
				if not remove:
					new_deck.append(c)
			player_state.deck = new_deck
		EventEffectData.EffectType.GAIN_REINCARNATION_FRAGMENT:
			player_state.reincarnation_fragments += effect.value
		EventEffectData.EffectType.GAIN_MAX_HP_PERCENT:
			var gain: int = int(player_state.max_hp * effect.value / 100.0)
			player_state.max_hp += gain
		EventEffectData.EffectType.LOSE_RELIC_RANDOM:
			if not player_state.relics.is_empty():
				var idx: int = randi() % player_state.relics.size()
				player_state.relics.remove_at(idx)
		EventEffectData.EffectType.GAIN_ENERGY_CAP:
			player_state.energy_cap += effect.value
		EventEffectData.EffectType.REMOVE_CARDS_RANDOM:
			var count: int = mini(effect.value, player_state.deck.size())
			for _i in count:
				var idx: int = randi() % player_state.deck.size()
				player_state.deck.remove_at(idx)
		EventEffectData.EffectType.GAIN_CARD:
			var pool: Array[String] = []
			match effect.card_grade:
				2: pool = CardPool.GRADE_2_CARDS
				1: pool = CardPool.GRADE_1_CARDS
				_: pool = CardPool.CARDS
			if effect.card_type_filter != "":
				var filtered: Array[String] = []
				for path in pool:
					var c: CardData = load(path) as CardData
					if c != null and c.card_type == effect.card_type_filter:
						filtered.append(path)
				pool = filtered
			if pool.is_empty():
				return
			var card: CardData = (load(pool[randi() % pool.size()]) as CardData).duplicate()
			player_state.deck.append(card)
		EventEffectData.EffectType.UPGRADE_CARDS_TYPE:
			for c: CardData in player_state.deck:
				if not c.is_upgraded and (effect.card_type_filter == "" or c.card_type == effect.card_type_filter):
					c.upgrade()
		EventEffectData.EffectType.COMBAT_ELITE_STUB:
			pass
		_:
			push_warning("EventEngine: unhandled effect_type %d" % effect.effect_type)

# Returns cards from deck that are eligible for selection for the given interactive effect.
# Filtered cards (return false) are excluded from the result.
static func get_eligible_cards(deck: Array[CardData], effect: EventEffectData) -> Array[CardData]:
	if effect.card_type_filter.is_empty():
		return deck
	var result: Array[CardData] = []
	for card in deck:
		var matches: bool
		match effect.card_type_filter:
			"心魔":
				matches = card.is_curse
			"走火入魔":
				matches = card.is_zahuorumuo
			"诅咒":
				matches = card.is_curse or card.is_zahuorumuo
			"基础招式":
				matches = (card.card_type == "招式" and not card.is_upgraded)
			"基础身法":
				matches = (card.card_type == "身法" and not card.is_upgraded)
			_:
				matches = card.card_type == effect.card_type_filter
		if matches:
			result.append(card)
	return result

static func _describe_single(effect: EventEffectData) -> String:
	var pct: String = "" if effect.probability >= 1.0 else "（%d%%概率）" % int(effect.probability * 100)
	match effect.effect_type:
		EventEffectData.EffectType.NOTHING: return ""
		EventEffectData.EffectType.GAIN_GOLD: return pct + "获得 %d 灵石" % effect.value
		EventEffectData.EffectType.LOSE_GOLD: return pct + "失去 %d 灵石" % effect.value
		EventEffectData.EffectType.GAIN_HP: return pct + "回复 %d HP" % effect.value
		EventEffectData.EffectType.LOSE_HP: return pct + "受到 %d 伤害" % effect.value
		EventEffectData.EffectType.HEAL_PERCENT_MAX: return pct + "回复最大 HP 的 %d%%" % effect.value
		EventEffectData.EffectType.HEAL_FULL: return pct + "回满 HP"
		EventEffectData.EffectType.LOSE_HP_PERCENT_CURRENT: return pct + "失去当前 HP 的 %d%%" % effect.value
		EventEffectData.EffectType.LOSE_MAX_HP_PERCENT: return pct + "最大 HP 降低 %d%%" % effect.value
		EventEffectData.EffectType.GAIN_RELIC:
			match effect.relic_grade:
				1: return pct + "获得随机法器"
				2: return pct + "获得随机灵器"
				3: return pct + "获得随机仙器"
				_: return pct + "获得随机遗物"
		EventEffectData.EffectType.GAIN_CURSE_CARD: return pct + "牌组加入心魔"
		EventEffectData.EffectType.REMOVE_CARDS_TYPE: return pct + "移除牌组中所有%s" % effect.card_type_filter
		EventEffectData.EffectType.UPGRADE_CARD_CHOOSE: return "选择一张牌悟道"
		EventEffectData.EffectType.REMOVE_CARD_CHOOSE: return "选择一张牌移除"
		EventEffectData.EffectType.COPY_CARD_CHOOSE: return "选择一张牌复制"
		EventEffectData.EffectType.GAIN_REINCARNATION_FRAGMENT: return pct + "获得 %d 个轮回碎片" % effect.value
		EventEffectData.EffectType.GAIN_MAX_HP_PERCENT: return pct + "最大 HP 永久 +%d%%" % effect.value
		EventEffectData.EffectType.LOSE_RELIC_RANDOM: return pct + "失去随机遗物"
		EventEffectData.EffectType.GAIN_ENERGY_CAP: return pct + "真气上限永久 +%d" % effect.value
		EventEffectData.EffectType.REMOVE_CARDS_RANDOM: return pct + "随机移除 %d 张牌" % effect.value
		EventEffectData.EffectType.GAIN_CARD:
			var grade_str: String
			match effect.card_grade:
				2: grade_str = "仙品"
				1: grade_str = "灵品"
				_: grade_str = "凡品"
			var type_str: String = effect.card_type_filter if effect.card_type_filter != "" else ""
			return pct + "获得随机%s%s牌" % [grade_str, type_str]
		EventEffectData.EffectType.UPGRADE_CARDS_TYPE:
			if effect.card_type_filter != "":
				return pct + "所有%s牌悟道" % effect.card_type_filter
			return pct + "所有牌悟道"
		_: return ""
