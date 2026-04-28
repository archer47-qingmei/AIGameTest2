extends Control

const NODE_LABELS: Array[String] = ["关卡一：颚虫", "关卡二：精英守卫"]

@onready var _node_container: VBoxContainer = $VBoxContainer/NodeContainer

func _ready() -> void:
	var current: int = GameManager.player_state.current_node
	for i: int in NODE_LABELS.size():
		var btn: Button = Button.new()
		if i < current:
			btn.text = NODE_LABELS[i] + "（已完成）"
			btn.disabled = true
		elif i == current:
			btn.text = NODE_LABELS[i]
			btn.pressed.connect(GameManager.go_to_combat)
		else:
			btn.text = NODE_LABELS[i] + "（未解锁）"
			btn.disabled = true
		_node_container.add_child(btn)
