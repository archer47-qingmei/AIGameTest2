extends Control

@onready var _lbl_hp: Label = $LblHP

var _node_positions: Dictionary = {}

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	_lbl_hp.text = "生命：%d / %d" % [state.hp, state.max_hp]
	_build_map(state)
	queue_redraw()

func _build_map(state: PlayerState) -> void:
	for nd: NodeData in state.map_all_nodes:
		var center: Vector2 = _get_node_pos(nd)
		_node_positions[nd] = center
		var btn := Button.new()
		btn.size = Vector2(110.0, 50.0)
		btn.position = center - Vector2(55.0, 25.0)
		var is_available: bool = state.available_nodes.has(nd)
		var is_completed: bool = state.completed_nodes.has(nd)
		if is_completed:
			btn.text = "✓ " + _get_node_label(nd)
			btn.disabled = true
		elif is_available:
			btn.text = _get_node_label(nd)
			btn.pressed.connect(GameManager.select_node.bind(nd))
		else:
			btn.text = _get_node_label(nd)
			btn.disabled = true
		add_child(btn)

func _draw() -> void:
	var state: PlayerState = GameManager.player_state
	for nd: NodeData in state.map_all_nodes:
		if not _node_positions.has(nd):
			continue
		var from: Vector2 = _node_positions[nd]
		for target: NodeData in nd.connections:
			if not _node_positions.has(target):
				continue
			var to: Vector2 = _node_positions[target]
			var color: Color = Color(0.4, 1.0, 0.4) if state.completed_nodes.has(nd) \
							   else Color(0.5, 0.5, 0.5)
			draw_line(from, to, color, 2.0)

func _get_node_pos(nd: NodeData) -> Vector2:
	if nd.column == 2:
		return Vector2(380.0, 375.0)
	return Vector2(100.0 if nd.column == 0 else 240.0,
				   250.0 if nd.row == 0 else 500.0)

func _get_node_label(nd: NodeData) -> String:
	if nd.connections.is_empty():
		return "Boss 战斗"
	if nd.type == NodeData.Type.REST:
		return "休息站"
	return "战斗"
