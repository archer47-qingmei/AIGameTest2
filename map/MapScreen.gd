extends Control

@onready var _node_container: VBoxContainer = $VBoxContainer/NodeContainer

func _ready() -> void:
	var current: int = GameManager.player_state.current_node
	var total: int = GameManager.player_state.enemy_sequence.size()
	for i: int in total:
		var btn: Button = Button.new()
		var label: String = "关卡 %d" % (i + 1)
		if i == total - 1:
			label = "关卡 %d（Boss）" % (i + 1)
		if i < current:
			btn.text = label + "（已完成）"
			btn.disabled = true
		elif i == current:
			btn.text = label
			btn.pressed.connect(GameManager.go_to_combat)
		else:
			btn.text = label + "（未解锁）"
			btn.disabled = true
		_node_container.add_child(btn)
