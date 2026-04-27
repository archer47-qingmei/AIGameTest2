extends Control

@onready var _btn_start: Button = $BtnStart

func _ready() -> void:
	_btn_start.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	GameManager.start_new_run()
