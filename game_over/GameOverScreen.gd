extends Control

@onready var _lbl_node: Label  = $VBoxContainer/LblNode
@onready var _btn_menu: Button = $VBoxContainer/BtnMenu

func _ready() -> void:
	var completed: int = GameManager.player_state.completed_nodes.size()
	var total: int = GameManager.player_state.map_all_nodes.size()
	_lbl_node.text = "已完成 %d / %d 关" % [completed, total]
	_btn_menu.pressed.connect(GameManager.go_to_menu)
