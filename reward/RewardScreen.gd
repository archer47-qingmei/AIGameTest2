extends Control

enum State { LIST, CARD_PICK }

@onready var _vbox: VBoxContainer = $VBoxContainer

var _state: State = State.LIST
var _btn_relic: Button
var _btn_gold: Button
var _btn_card: Button
var _card_container: VBoxContainer
var _btn_continue: Button

func _ready() -> void:
	for child in _vbox.get_children():
		_vbox.remove_child(child)
		child.free()

	_btn_relic = Button.new()
	_vbox.add_child(_btn_relic)
	_btn_relic.pressed.connect(_on_relic_pressed)

	_btn_gold = Button.new()
	_vbox.add_child(_btn_gold)
	_btn_gold.pressed.connect(_on_gold_pressed)

	_btn_card = Button.new()
	_btn_card.text = "卡牌"
	_vbox.add_child(_btn_card)
	_btn_card.pressed.connect(_on_card_btn_pressed)

	_card_container = VBoxContainer.new()
	_vbox.add_child(_card_container)
	_card_container.hide()

	_btn_continue = Button.new()
	_btn_continue.text = "继续"
	_vbox.add_child(_btn_continue)
	_btn_continue.pressed.connect(_on_continue_pressed)

	_show_list()

func _show_list() -> void:
	_state = State.LIST
	_card_container.hide()
	if GameManager.pending_card_reward:
		_btn_card.show()
	else:
		_btn_card.hide()
	_btn_continue.show()

	if _btn_relic.disabled:
		_btn_relic.show()
	else:
		var relic: RelicData = GameManager.pending_relic
		if relic != null:
			_btn_relic.text = "%s — %s" % [relic.display_name, _relic_effect_text(relic)]
			_btn_relic.show()
		else:
			_btn_relic.hide()

	if _btn_gold.disabled:
		_btn_gold.show()
	else:
		var amount: int = GameManager.pending_gold
		if amount > 0:
			_btn_gold.text = "领取 %d 金币" % amount
			_btn_gold.show()
		else:
			_btn_gold.hide()

func _relic_effect_text(relic: RelicData) -> String:
	var parts := relic.description.split("\n\n")
	return parts[0]

func _on_relic_pressed() -> void:
	_btn_relic.text = "%s — %s" % [GameManager.pending_relic.display_name, _relic_effect_text(GameManager.pending_relic)]
	GameManager.collect_relic()
	_btn_relic.disabled = true
	_btn_relic.text += " ✓"

func _on_gold_pressed() -> void:
	GameManager.collect_gold(GameManager.pending_gold)
	_btn_gold.disabled = true
	_btn_gold.text += " ✓"

func _on_card_btn_pressed() -> void:
	_state = State.CARD_PICK
	_btn_relic.hide()
	_btn_gold.hide()
	_btn_card.hide()
	_btn_continue.hide()
	_card_container.show()
	_build_card_options()

func _build_card_options() -> void:
	for child in _card_container.get_children():
		_card_container.remove_child(child)
		child.free()
	var options: Array[CardData] = RewardEngine.get_options(
		GameManager.player_state.character,
		_reward_card_count()
	)
	for card: CardData in options:
		var btn: Button = Button.new()
		btn.text = card.get_description()
		btn.pressed.connect(_on_card_selected.bind(card))
		_card_container.add_child(btn)
	var btn_skip: Button = Button.new()
	btn_skip.text = "跳过"
	btn_skip.pressed.connect(_on_skipped)
	_card_container.add_child(btn_skip)

func _on_card_selected(card: CardData) -> void:
	GameManager.player_state.deck.append(card.duplicate())
	_btn_card.text = "卡牌 ✓"
	_btn_card.disabled = true
	_show_list()

func _on_skipped() -> void:
	_btn_card.text = "卡牌（已跳过）"
	_btn_card.disabled = true
	_show_list()

func _reward_card_count() -> int:
	var count: int = 3
	for r: RelicData in GameManager.player_state.relics:
		if r.effect_type == RelicData.EffectType.EXTRA_REWARD_CARD or \
		   (r.has_effect_b and r.effect_type_b == RelicData.EffectType.EXTRA_REWARD_CARD):
			count += r.value
	return count

func _on_continue_pressed() -> void:
	if GameManager.is_final_node():
		if GameManager.is_last_realm():
			GameManager.go_to_win()
		else:
			GameManager.advance_realm()
	else:
		GameManager.go_to_map()
