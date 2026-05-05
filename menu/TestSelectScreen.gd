extends Control

@onready var _vbox: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var _btn_back: Button = $BtnBack

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

func _on_group_pressed(group: EnemyGroupData) -> void:
	GameManager.start_test_combat(group)

func _on_back_pressed() -> void:
	GameManager.go_to_menu()
