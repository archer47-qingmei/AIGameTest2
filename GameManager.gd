extends Node

enum Phase { MENU, MAP, COMBAT, REWARD, REST, WIN, GAME_OVER }

func _ready() -> void:
	var font: FontFile = load("res://data/fonts/NotoSansSC-Regular.otf") as FontFile
	if font:
		var theme: Theme = Theme.new()
		theme.default_font = font
		theme.default_font_size = 16
		get_tree().root.theme = theme

var current_phase: Phase = Phase.MENU
var player_state: PlayerState
var pending_relic: RelicData = null

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
	a1.config = preload("res://data/nodes/node_a1.tres")
	var a2: NodeData = NodeData.new()
	a2.config = preload("res://data/nodes/node_a2.tres")
	var b1: NodeData = NodeData.new()
	b1.config = preload("res://data/nodes/node_b1.tres")
	var b2: NodeData = NodeData.new()
	b2.config = preload("res://data/nodes/node_b2.tres")
	var c1: NodeData = NodeData.new()
	c1.config = preload("res://data/nodes/node_c1.tres")

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
	if node.config.type == NodeConfig.Type.REST:
		go_to_rest()
	else:
		go_to_combat()

func go_to_combat() -> void:
	current_phase = Phase.COMBAT
	get_tree().change_scene_to_file("res://combat/CombatScreen.tscn")

func end_combat(final_hp: int) -> void:
	player_state.hp = final_hp
	if is_elite_node():
		pending_relic = preload("res://data/relics/burning_gem.tres")
	elif is_final_node():
		pending_relic = preload("res://data/relics/life_ring.tres")
	else:
		pending_relic = null
	go_to_reward()

func go_to_reward() -> void:
	current_phase = Phase.REWARD
	get_tree().change_scene_to_file("res://reward/RewardScreen.tscn")

func go_to_rest() -> void:
	player_state.apply_rest_heal()
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
	return player_state.current_node.config.enemy_data

func is_final_node() -> bool:
	return player_state.current_node.connections.is_empty()

func is_elite_node() -> bool:
	return player_state.current_node.config.type == NodeConfig.Type.ELITE
