extends Control

@onready var _lbl_heal: Label      = $VBoxContainer/LblHeal
@onready var _lbl_hp: Label        = $VBoxContainer/LblHP
@onready var _btn_continue: Button = $VBoxContainer/BtnContinue

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	var heal: int = int(state.max_hp * 0.3)
	state.hp = min(state.hp + heal, state.max_hp)
	_lbl_heal.text = "恢复了 %d 点生命" % heal
	_lbl_hp.text = "当前生命：%d / %d" % [state.hp, state.max_hp]
	_btn_continue.pressed.connect(GameManager.go_to_map)
