extends Control

@onready var _card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardListContainer
@onready var _lbl_selected: Label = $VBoxContainer/LblSelected
@onready var _btn_start: Button = $VBoxContainer/BtnRow/BtnStart
@onready var _btn_back: Button = $VBoxContainer/BtnRow/BtnBack

var _cards: Array[CardData] = []
var _counts: Array[int] = []
var _relics: Array[RelicData] = []
var _relic_selected: Array[bool] = []
var _relic_row_offset: int = 0

func _ready() -> void:
	for path in CardPool.SWORD_REWARD_CARDS:
		_cards.append(load(path) as CardData)
		_counts.append(0)
	for path in CardPool.RELICS:
		_relics.append(load(path) as RelicData)
		_relic_selected.append(false)
	_build_rows()
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_back.pressed.connect(_on_back_pressed)
	_refresh()

func _build_rows() -> void:
	for i in _cards.size():
		var row := HBoxContainer.new()
		var lbl_name := Label.new()
		lbl_name.text = _cards[i].card_name
		lbl_name.custom_minimum_size.x = 80
		var lbl_desc := Label.new()
		lbl_desc.text = _cards[i].get_description()
		lbl_desc.custom_minimum_size.x = 280
		lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var btn_minus := Button.new()
		btn_minus.text = "−"
		btn_minus.custom_minimum_size.x = 30
		btn_minus.pressed.connect(_on_minus.bind(i))
		var lbl_count := Label.new()
		lbl_count.text = "0"
		lbl_count.custom_minimum_size.x = 30
		lbl_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var btn_plus := Button.new()
		btn_plus.text = "+"
		btn_plus.custom_minimum_size.x = 30
		btn_plus.pressed.connect(_on_plus.bind(i))
		row.add_child(lbl_name)
		row.add_child(lbl_desc)
		row.add_child(btn_minus)
		row.add_child(lbl_count)
		row.add_child(btn_plus)
		_card_list.add_child(row)

	var sep := Label.new()
	sep.text = "─── 遗物 ───"
	sep.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_card_list.add_child(sep)
	_relic_row_offset = _card_list.get_child_count()

	for i in _relics.size():
		var row := HBoxContainer.new()
		var btn_toggle := Button.new()
		btn_toggle.text = "○"
		btn_toggle.custom_minimum_size.x = 36
		btn_toggle.pressed.connect(_on_relic_toggle.bind(i))
		var lbl_name := Label.new()
		lbl_name.text = _relics[i].display_name
		lbl_name.custom_minimum_size.x = 80
		var lbl_desc := Label.new()
		lbl_desc.text = _relics[i].description
		lbl_desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		row.add_child(btn_toggle)
		row.add_child(lbl_name)
		row.add_child(lbl_desc)
		_card_list.add_child(row)

func _on_minus(i: int) -> void:
	_counts[i] = max(0, _counts[i] - 1)
	_refresh()

func _on_plus(i: int) -> void:
	_counts[i] = min(5, _counts[i] + 1)
	_refresh()

func _on_relic_toggle(i: int) -> void:
	_relic_selected[i] = not _relic_selected[i]
	_refresh()

func _refresh() -> void:
	var total := 0
	for i in _cards.size():
		total += _counts[i]
		var row: HBoxContainer = _card_list.get_child(i) as HBoxContainer
		(row.get_child(3) as Label).text = str(_counts[i])
	var relic_count := 0
	for i in _relics.size():
		if _relic_selected[i]:
			relic_count += 1
		var row: HBoxContainer = _card_list.get_child(_relic_row_offset + i) as HBoxContainer
		(row.get_child(0) as Button).text = "✓" if _relic_selected[i] else "○"
	_lbl_selected.text = "已选：%d 张卡牌  %d 个遗物" % [total, relic_count]
	_btn_start.disabled = total == 0

func _on_start_pressed() -> void:
	var cards: Array[CardData] = []
	for i in _cards.size():
		for _j in _counts[i]:
			cards.append(_cards[i])
	var relics: Array[RelicData] = []
	for i in _relics.size():
		if _relic_selected[i]:
			relics.append(_relics[i])
	GameManager.start_debug_run(cards, relics)

func _on_back_pressed() -> void:
	GameManager.go_to_char_select()
