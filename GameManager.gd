extends Node

enum Phase { MENU, MAP, COMBAT, REWARD, REST, WIN }

const NORMAL_POOL: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
const BOSS_ENEMY: String = "res://data/enemies/boss.tres"
const REST_NODE: String = "rest"

var current_phase: Phase = Phase.MENU
var player_state: PlayerState
var last_rest_heal: int = 0

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
	var pool: Array[String] = NORMAL_POOL.duplicate()
	pool.shuffle()
	player_state.enemy_sequence.assign(pool)
	player_state.enemy_sequence.append(REST_NODE)
	player_state.enemy_sequence.append(BOSS_ENEMY)
	current_phase = Phase.MAP
	get_tree().change_scene_to_file("res://map/MapScreen.tscn")

func go_to_combat() -> void:
	current_phase = Phase.COMBAT
	get_tree().change_scene_to_file("res://combat/CombatScreen.tscn")

func go_to_reward() -> void:
	current_phase = Phase.REWARD
	get_tree().change_scene_to_file("res://reward/RewardScreen.tscn")

func go_to_rest() -> void:
	last_rest_heal = int(player_state.max_hp * 0.3)
	player_state.hp = mini(player_state.hp + last_rest_heal, player_state.max_hp)
	current_phase = Phase.REST
	get_tree().change_scene_to_file("res://rest/RestScreen.tscn")

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
	return load(player_state.enemy_sequence[player_state.current_node]) as EnemyData

func is_final_node() -> bool:
	return player_state.current_node == player_state.enemy_sequence.size() - 1
