extends Control

@onready var _node_container: VBoxContainer = $VBoxContainer/NodeContainer

func _ready() -> void:
	var current: int = GameManager.player_state.current_node
	var sequence: Array[NodeData] = GameManager.player_state.node_sequence
	var total: int = sequence.size()
	for i: int in total:
		var btn: Button = Button.new()
		var label: String = _get_node_label(i, sequence, total)
		if i < current:
			btn.text = label + "（已完成）"
			btn.disabled = true
		elif i == current:
			btn.text = label
			if sequence[i].type == NodeData.Type.REST:
				btn.pressed.connect(GameManager.go_to_rest)
			else:
				btn.pressed.connect(GameManager.go_to_combat)
		else:
			btn.text = label + "（未解锁）"
			btn.disabled = true
		_node_container.add_child(btn)

func _get_node_label(i: int, sequence: Array[NodeData], total: int) -> String:
	if sequence[i].type == NodeData.Type.REST:
		return "休息站"
	elif i == total - 1:
		return "关卡 %d（Boss）" % (i + 1)
	else:
		return "关卡 %d" % (i + 1)
