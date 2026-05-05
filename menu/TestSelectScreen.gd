extends Control

@onready var _vbox: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var _btn_back: Button = $BtnBack
@onready var _scroll: ScrollContainer = $ScrollContainer

var _drag_start_y: float = -1.0
var _scroll_start_y: int = 0

func _ready() -> void:
	_btn_back.pressed.connect(_on_back_pressed)
	var all_paths: Array[String] = []
	all_paths.append_array(MapGenerator.EARLY_GROUP_PATHS)
	all_paths.append_array(MapGenerator.MID_GROUP_PATHS)
	all_paths.append_array(MapGenerator.ELITE_GROUP_PATHS)
	all_paths.append(MapGenerator.BOSS_GROUP_PATH)
	all_paths.append_array(MapGenerator.JD_EARLY_GROUP_PATHS)
	all_paths.append_array(MapGenerator.JD_MID_GROUP_PATHS)
	all_paths.append_array(MapGenerator.JD_ELITE_GROUP_PATHS)
	all_paths.append(MapGenerator.JD_BOSS_GROUP_PATH)
	for path in all_paths:
		var group: EnemyGroupData = load(path) as EnemyGroupData
		var parts: PackedStringArray = PackedStringArray()
		for e in group.enemies:
			parts.append(e.display_name)
		var btn := Button.new()
		btn.text = " + ".join(parts)
		btn.custom_minimum_size = Vector2(0, 40)
		btn.pressed.connect(_on_group_pressed.bind(group))
		_vbox.add_child(btn)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _scroll.get_global_rect().has_point(event.global_position):
			_drag_start_y = event.global_position.y
			_scroll_start_y = _scroll.scroll_vertical
		else:
			_drag_start_y = -1.0
	elif event is InputEventMouseMotion and _drag_start_y >= 0.0:
		_scroll.scroll_vertical = _scroll_start_y - int(event.global_position.y - _drag_start_y)

func _on_group_pressed(group: EnemyGroupData) -> void:
	GameManager.start_test_combat(group)

func _on_back_pressed() -> void:
	GameManager.go_to_menu()
