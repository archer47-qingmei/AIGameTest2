extends Control

@onready var _btn_sword: Button = $VBoxContainer/BtnSword
@onready var _btn_back: Button = $VBoxContainer/BtnBack

func _ready() -> void:
	_btn_sword.pressed.connect(_on_sword_pressed)
	_btn_back.pressed.connect(_on_back_pressed)

func _on_sword_pressed() -> void:
	GameManager.start_new_run("sword")

func _on_back_pressed() -> void:
	GameManager.go_to_menu()
