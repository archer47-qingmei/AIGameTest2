extends Control

@onready var _panel_choice: VBoxContainer        = $VBoxContainer/PanelChoice
@onready var _btn_rest: Button                   = $VBoxContainer/PanelChoice/BtnRest
@onready var _btn_upgrade: Button                = $VBoxContainer/PanelChoice/BtnUpgrade
@onready var _lbl_heal: Label                    = $VBoxContainer/LblHeal
@onready var _lbl_hp: Label                      = $VBoxContainer/LblHP
@onready var _lbl_upgrade_prompt: Label          = $VBoxContainer/LblUpgradePrompt
@onready var _scroll: ScrollContainer            = $VBoxContainer/ScrollContainer
@onready var _card_list: VBoxContainer           = $VBoxContainer/ScrollContainer/CardList
@onready var _panel_preview: Panel               = $VBoxContainer/PanelPreview
@onready var _lbl_current: Label                 = $VBoxContainer/PanelPreview/PreviewContent/LblCurrent
@onready var _rtl_upgraded: RichTextLabel        = $VBoxContainer/PanelPreview/PreviewContent/RtlUpgraded
@onready var _btn_confirm_upgrade: Button        = $VBoxContainer/PanelPreview/PreviewContent/HBoxContainer/BtnConfirmUpgrade
@onready var _btn_cancel_preview: Button         = $VBoxContainer/PanelPreview/PreviewContent/HBoxContainer/BtnCancelPreview
@onready var _btn_continue: Button               = $VBoxContainer/BtnContinue

var _upgrade_buttons: Array[Button] = []
var _pending_card: CardData = null

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	var heal_amount: int = int(state.max_hp * PlayerState.REST_HEAL_RATIO)
	_btn_rest.text = "休息（+%d 生命）" % heal_amount
	_btn_rest.pressed.connect(_on_rest_chosen)
	_btn_upgrade.pressed.connect(_on_upgrade_chosen)
	_btn_confirm_upgrade.pressed.connect(_on_confirm_upgrade)
	_btn_cancel_preview.pressed.connect(_on_cancel_preview)
	_btn_continue.pressed.connect(GameManager.go_to_map)

func _on_rest_chosen() -> void:
	var state: PlayerState = GameManager.player_state
	var healed: int = state.apply_rest_heal()
	_panel_choice.hide()
	_lbl_heal.text = "恢复了 %d 点生命" % healed
	_lbl_hp.text = "当前生命：%d / %d" % [state.hp, state.max_hp]
	_lbl_heal.show()
	_lbl_hp.show()
	_btn_continue.show()

func _on_upgrade_chosen() -> void:
	_panel_choice.hide()
	_lbl_upgrade_prompt.show()
	_scroll.show()
	_populate_upgrade_list()

func _populate_upgrade_list() -> void:
	for card: CardData in GameManager.player_state.deck:
		var btn: Button = Button.new()
		btn.text = card.get_description()
		btn.disabled = card.is_upgraded
		btn.pressed.connect(_on_card_clicked.bind(card))
		_card_list.add_child(btn)
		_upgrade_buttons.append(btn)

func _on_card_clicked(card: CardData) -> void:
	_pending_card = card
	_lbl_current.text = card.get_description()
	_rtl_upgraded.text = card.get_upgrade_preview_bbcode()
	_lbl_upgrade_prompt.hide()
	_scroll.hide()
	_panel_preview.show()

func _on_confirm_upgrade() -> void:
	if _pending_card == null:
		return
	_pending_card.upgrade()
	_pending_card = null
	_panel_preview.hide()
	for btn: Button in _upgrade_buttons:
		btn.disabled = true
	_btn_continue.show()

func _on_cancel_preview() -> void:
	_pending_card = null
	_panel_preview.hide()
	_lbl_upgrade_prompt.show()
	_scroll.show()
