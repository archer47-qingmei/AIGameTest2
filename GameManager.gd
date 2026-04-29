extends Node

enum Phase { MENU, MAP, COMBAT, REWARD, REST, WIN, GAME_OVER }

func _ready() -> void:
	var font: FontFile = load("res://data/fonts/NotoSansSC-Regular.otf") as FontFile
	if font:
		var theme: Theme = Theme.new()
		theme.default_font = font
		theme.default_font_size = 16
		get_tree().root.theme = theme

const NORMAL_POOL: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
const BOSS_ENEMY: String = "res://data/enemies/boss.tres"

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

	var a1: NodeData = NodeData.new()
	a1.type = NodeData.Type.COMBAT
	a1.enemy_data = load(NORMAL_POOL[0]) as EnemyData
	a1.column = 0; a1.row = 0

	var a2: NodeData = NodeData.new()
	a2.type = NodeData.Type.COMBAT
	a2.enemy_data = load(NORMAL_POOL[1]) as EnemyData
	a2.column = 0; a2.row = 1

	var b1: NodeData = NodeData.new()
	b1.type = NodeData.Type.REST
	b1.column = 1; b1.row = 0

	var b2: NodeData = NodeData.new()
	b2.type = NodeData.Type.COMBAT
	b2.enemy_data = load(NORMAL_POOL[0]) as EnemyData
	b2.column = 1; b2.row = 1

	var c1: NodeData = NodeData.new()
	c1.type = NodeData.Type.COMBAT
	c1.enemy_data = load(BOSS_ENEMY) as EnemyData
	c1.column = 2; c1.row = 0

	a1.connections.assign([b1, b2])
	a2.connections.assign([b1, b2])
	b1.connections.assign([c1])
	b2.connections.assign([c1])

	player_state.map_all_nodes.assign([a1, a2, b1, b2, c1])
	player_state.available_nodes.assign([a1, a2])

	current_phase = Phase.MAP
	get_tree().change_scene_to_file("res://map/MapScreen.tscn")

func select_node(node: NodeData) -> void:
	player_state.current_node = node
	if node.type == NodeData.Type.REST:
		go_to_rest()
	else:
		go_to_combat()

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
	if player_state.current_node != null:
		player_state.completed_nodes.append(player_state.current_node)
		player_state.available_nodes.assign(player_state.current_node.connections)
		player_state.current_node = null
	current_phase = Phase.MAP
	get_tree().change_scene_to_file("res://map/MapScreen.tscn")

func go_to_win() -> void:
	current_phase = Phase.WIN
	get_tree().change_scene_to_file("res://win/WinScreen.tscn")

func go_to_game_over() -> void:
	current_phase = Phase.GAME_OVER
	get_tree().change_scene_to_file("res://game_over/GameOverScreen.tscn")

func go_to_menu() -> void:
	player_state = null
	current_phase = Phase.MENU
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")

func get_current_enemy_data() -> EnemyData:
	return player_state.current_node.enemy_data

func is_final_node() -> bool:
	return player_state.current_node.connections.is_empty()
