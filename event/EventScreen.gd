class_name EventScreen
extends Control

@onready var mood_label: Label = $MoodLabel
@onready var event_name_label: Label = $EventNameLabel
@onready var flavor_label: Label = $FlavorLabel
@onready var choices_container: VBoxContainer = $ChoicesContainer
@onready var result_view: VBoxContainer = $ResultView
@onready var result_label: Label = $ResultView/ResultLabel
@onready var effect_summary_label: Label = $ResultView/EffectSummaryLabel
@onready var confirm_button: Button = $ResultView/ConfirmButton
@onready var card_pick_panel: PanelContainer = $CardPickPanel
@onready var prompt_label: Label = $CardPickPanel/CenterContainer/VBoxContainer/PromptLabel
@onready var card_grid: GridContainer = $CardPickPanel/CenterContainer/VBoxContainer/CardScrollContainer/CardGrid
@onready var card_pick_confirm_button: Button = $CardPickPanel/CenterContainer/VBoxContainer/CardPickConfirmButton

var _current_event: EventData
var _pending_interactive: Array[EventEffectData] = []
var _selected_choice: EventChoiceData
var _selected_card: CardData = null

func _ready() -> void:
	result_view.hide()
	card_pick_panel.hide()
	_current_event = EventPool.pick_event(GameManager.player_state)
	_populate_event()
	confirm_button.pressed.connect(_on_confirm_pressed)
	card_pick_confirm_button.pressed.connect(_on_card_pick_confirm_pressed)

func _populate_event() -> void:
	mood_label.text = "[%s]" % _current_event.mood
	event_name_label.text = _current_event.display_name
	flavor_label.text = _current_event.flavor_text
	for child in choices_container.get_children():
		child.queue_free()
	for choice in _current_event.choices:
		var btn := Button.new()
		btn.text = choice.button_text
		var available: bool = EventEngine.check_choice_available(choice, GameManager.player_state)
		btn.disabled = not available
		btn.pressed.connect(_on_choice_pressed.bind(choice))
		choices_container.add_child(btn)

func _on_choice_pressed(choice: EventChoiceData) -> void:
	_selected_choice = choice
	choices_container.hide()
	result_label.text = choice.result_text
	effect_summary_label.text = EventEngine.describe_effects(choice)
	result_view.show()

func _on_confirm_pressed() -> void:
	_pending_interactive = EventEngine.apply_immediate_effects(_selected_choice, GameManager.player_state)
	if _pending_interactive.is_empty():
		GameManager.go_to_map()
	else:
		_show_card_pick(_pending_interactive[0])

func _show_card_pick(effect: EventEffectData) -> void:
	result_view.hide()
	var prompt_text: String
	match effect.effect_type:
		EventEffectData.EffectType.UPGRADE_CARD_CHOOSE:
			prompt_text = "请选择一张牌悟道"
		EventEffectData.EffectType.REMOVE_CARD_CHOOSE:
			prompt_text = "请选择一张牌移除"
		EventEffectData.EffectType.COPY_CARD_CHOOSE:
			prompt_text = "请选择一张牌复制"
		_:
			prompt_text = "请选择一张牌"
	prompt_label.text = prompt_text
	for child in card_grid.get_children():
		child.queue_free()
	_selected_card = null
	card_pick_confirm_button.disabled = true
	for card in GameManager.player_state.deck:
		var filtered: bool = _is_filtered(card, effect)
		var btn := Button.new()
		btn.text = card.card_name
		btn.disabled = filtered
		btn.pressed.connect(_on_card_selected.bind(card))
		card_grid.add_child(btn)
	card_pick_panel.show()

func _is_filtered(card: CardData, effect: EventEffectData) -> bool:
	if effect.card_type_filter.is_empty():
		return false
	match effect.card_type_filter:
		"心魔":
			return not card.is_curse
		"走火入魔":
			return not card.is_zahuorumuo
		_:
			return card.card_type != effect.card_type_filter

func _on_card_selected(card: CardData) -> void:
	_selected_card = card
	card_pick_confirm_button.disabled = false

func _on_card_pick_confirm_pressed() -> void:
	if _selected_card == null:
		return
	EventEngine.apply_interactive_effect(_pending_interactive[0], _selected_card, GameManager.player_state)
	_pending_interactive.remove_at(0)
	if _pending_interactive.is_empty():
		GameManager.go_to_map()
	else:
		_show_card_pick(_pending_interactive[0])
