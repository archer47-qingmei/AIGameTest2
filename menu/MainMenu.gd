extends Control

@onready var _btn_start: Button = $BtnStart
@onready var _btn_debug: Button = $BtnDebug

func _ready() -> void:
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_debug.pressed.connect(_on_debug_pressed)

func _on_start_pressed() -> void:
	GameManager.go_to_char_select()

func _on_debug_pressed() -> void:
	GameManager.go_to_test_select()
