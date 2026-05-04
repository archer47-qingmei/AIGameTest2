class_name EventScreen
extends Control

@onready var event_name_label: Label = $VBoxContainer/EventNameLabel
@onready var flavor_label: Label = $VBoxContainer/FlavorLabel
@onready var choices_container: VBoxContainer = $VBoxContainer/ChoicesContainer
@onready var result_view: VBoxContainer = $VBoxContainer/ResultView
@onready var result_label: Label = $VBoxContainer/ResultView/ResultLabel
@onready var effect_summary_label: Label = $VBoxContainer/ResultView/EffectSummaryLabel
@onready var confirm_button: Button = $VBoxContainer/ResultView/ConfirmButton
@onready var card_pick_panel: PanelContainer = $CardPickPanel
@onready var prompt_label: Label = $CardPickPanel/CenterContainer/InnerBox/PromptLabel
@onready var card_grid: GridContainer = $CardPickPanel/CenterContainer/InnerBox/CardScrollContainer/CardGrid
@onready var card_pick_confirm_button: Button = $CardPickPanel/CenterContainer/InnerBox/CardPickConfirmButton

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
	if _selected_choice == null:
		return
	if _selected_choice.cost_gold > 0:
		GameManager.player_state.gold -= _selected_choice.cost_gold
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
	var eligible: Array[CardData] = EventEngine.get_eligible_cards(GameManager.player_state.deck, effect)
	for card in eligible:
		var btn := Button.new()
		btn.text = card.card_name
		btn.pressed.connect(_on_card_selected.bind(card))
		card_grid.add_child(btn)
	if eligible.is_empty():
		GameManager.go_to_map()
		return
	card_pick_panel.show()

func _on_card_selected(card: CardData) -> void:
	_selected_card = card
	card_pick_confirm_button.disabled = false

func _on_card_pick_confirm_pressed() -> void:
	if _selected_card == null:
		return
	if _pending_interactive.is_empty():
		GameManager.go_to_map()
		return
	EventEngine.apply_interactive_effect(_pending_interactive[0], _selected_card, GameManager.player_state)
	_pending_interactive.remove_at(0)
	if _pending_interactive.is_empty():
		GameManager.go_to_map()
	else:
		_show_card_pick(_pending_interactive[0])
