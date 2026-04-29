extends Control

@onready var _lbl_node: Label  = $VBoxContainer/LblNode
@onready var _btn_menu: Button = $VBoxContainer/BtnMenu

func _ready() -> void:
	var reached: int = GameManager.player_state.current_node + 1
	var total: int = GameManager.player_state.node_sequence.size()
	_lbl_node.text = "已抵达第 %d / %d 关" % [reached, total]
	_btn_menu.pressed.connect(GameManager.go_to_menu)
