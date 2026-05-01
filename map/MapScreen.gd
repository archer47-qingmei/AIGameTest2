extends Control

@onready var _lbl_hp: Label = $LblHP
@onready var _scroll: ScrollContainer = $ScrollContainer
@onready var _map_content: Control = $ScrollContainer/MapContent

var _node_positions: Dictionary = {}
var _state: PlayerState = null

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	_state = state
	_lbl_hp.text = "生命：%d / %d" % [state.hp, state.max_hp]
	_build_map(state)
	_map_content.on_draw = _draw_connections
	_map_content.queue_redraw()
	_scroll.get_v_scroll_bar().custom_minimum_size.x = 0
	await get_tree().process_frame
	_scroll.scroll_vertical = int(_map_content.get_minimum_size().y)

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
		_map_content.add_child(btn)

func _draw_connections() -> void:
	if _state == null:
		return
	for nd: NodeData in _state.map_all_nodes:
		if not _node_positions.has(nd):
			continue
		var from: Vector2 = _node_positions[nd]
		for target: NodeData in nd.connections:
			if not _node_positions.has(target):
				continue
			var to: Vector2 = _node_positions[target]
			var color: Color = Color(0.4, 1.0, 0.4) if _state.completed_nodes.has(nd) \
							   else Color(0.5, 0.5, 0.5)
			_map_content.draw_line(from, to, color, 2.0)

func _get_node_pos(nd: NodeData) -> Vector2:
	if nd.config.column == MapGenerator.TOTAL_COLUMNS - 1:
		return Vector2(240.0, 150.0)
	var row_x: float = 140.0 if nd.config.row == 0 else 340.0
	var col_y: float = 1500.0 - nd.config.column * 150.0
	return Vector2(row_x, col_y)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		_scroll.scroll_vertical -= int(event.relative.y)

func _get_node_label(nd: NodeData) -> String:
	if nd.connections.is_empty():
		return "Boss 战斗"
	match nd.config.type:
		NodeConfig.Type.REST:
			return "休息站"
		NodeConfig.Type.ELITE:
			return "精英战斗"
		NodeConfig.Type.SHOP:
			return "商店"
	return "战斗"
