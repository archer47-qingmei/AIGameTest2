extends Node

enum Phase { MENU, COMBAT }

var current_phase: Phase = Phase.MENU

func go_to_combat() -> void:
	current_phase = Phase.COMBAT
	get_tree().change_scene_to_file("res://combat/CombatScreen.tscn")

func go_to_menu() -> void:
	current_phase = Phase.MENU
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")
