extends Control

func _ready() -> void:
	$VBoxContainer/BtnMenu.pressed.connect(GameManager.go_to_menu)
