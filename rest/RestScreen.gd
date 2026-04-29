extends Control

@onready var _lbl_heal: Label = $VBoxContainer/LblHeal
@onready var _lbl_hp: Label = $VBoxContainer/LblHP
@onready var _card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var _btn_continue: Button = $VBoxContainer/BtnContinue

var _upgrade_buttons: Array[Button] = []

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	_lbl_heal.text = "恢复了 %d 点生命" % GameManager.last_rest_heal
	_lbl_hp.text = "当前生命：%d / %d" % [state.hp, state.max_hp]
	_btn_continue.pressed.connect(GameManager.go_to_map)
	_populate_upgrade_list()

func _populate_upgrade_list() -> void:
	var deck: Array[CardData] = GameManager.player_state.deck
	for card: CardData in deck:
		var btn: Button = Button.new()
		btn.text = card.get_description()
		btn.disabled = card.is_upgraded
		btn.pressed.connect(_on_upgrade_card.bind(card))
		_card_list.add_child(btn)
		_upgrade_buttons.append(btn)

func _on_upgrade_card(card: CardData) -> void:
	card.upgrade()
	var deck: Array[CardData] = GameManager.player_state.deck
	for i: int in _upgrade_buttons.size():
		_upgrade_buttons[i].text = deck[i].get_description()
		_upgrade_buttons[i].disabled = true
