extends Node

enum Phase { MENU, MAP, COMBAT, REWARD, WIN }

const STAGE_ENEMIES: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/boss.tres"
]

var current_phase: Phase = Phase.MENU
var player_state: PlayerState

func start_new_run() -> void:
	player_state = PlayerState.new()
	var strike: CardData = preload("res://data/cards/strike.tres")
	var defend: CardData = preload("res://data/cards/defend.tres")
	var bash: CardData   = preload("res://data/cards/bash.tres")
	var slash: CardData  = preload("res://data/cards/slash.tres")
	for i in 4:
		player_state.deck.append(strike.duplicate())
	for i in 4:
		player_state.deck.append(defend.duplicate())
	player_state.deck.append(bash.duplicate())
	player_state.deck.append(slash.duplicate())
	current_phase = Phase.MAP
	get_tree().change_scene_to_file("res://map/MapScreen.tscn")

func go_to_combat() -> void:
	current_phase = Phase.COMBAT
	get_tree().change_scene_to_file("res://combat/CombatScreen.tscn")

func go_to_reward() -> void:
	current_phase = Phase.REWARD
	get_tree().change_scene_to_file("res://reward/RewardScreen.tscn")

func go_to_map() -> void:
	player_state.current_node += 1
	current_phase = Phase.MAP
	get_tree().change_scene_to_file("res://map/MapScreen.tscn")

func go_to_win() -> void:
	current_phase = Phase.WIN
	get_tree().change_scene_to_file("res://win/WinScreen.tscn")

func go_to_menu() -> void:
	player_state = null
	current_phase = Phase.MENU
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")

func get_current_enemy_data() -> EnemyData:
	return load(STAGE_ENEMIES[player_state.current_node]) as EnemyData

func is_final_node() -> bool:
	return player_state.current_node == STAGE_ENEMIES.size() - 1
