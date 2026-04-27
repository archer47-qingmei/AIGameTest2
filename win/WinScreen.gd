extends Control

func _ready() -> void:
	$BtnMenu.pressed.connect(GameManager.go_to_menu)
