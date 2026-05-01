extends Node

enum Phase { MENU, CHAR_SELECT, MAP, COMBAT, REWARD, REST, SHOP, WIN, GAME_OVER }

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
var pending_gold: int = 0
var pending_card_reward: bool = true

func start_new_run(character: String) -> void:
	pending_card_reward = true
	player_state = PlayerState.new()
	player_state.character = character
	var relic_paths: Array[String] = []
	match character:
		"sword":
			relic_paths.assign(CardPool.SWORD_START_RELICS)
	for path in relic_paths:
		player_state.relics.append((load(path) as RelicData).duplicate())

	var strike: CardData    = preload("res://data/cards/strike.tres")
	var defend: CardData    = preload("res://data/cards/defend.tres")
	var bash: CardData      = preload("res://data/cards/bash.tres")
	var slash: CardData     = preload("res://data/cards/slash.tres")
	var whirlwind: CardData = preload("res://data/cards/whirlwind.tres")
	for i in 4:
		player_state.deck.append(strike.duplicate())
	for i in 4:
		player_state.deck.append(defend.duplicate())
	player_state.deck.append(bash.duplicate())
	player_state.deck.append(slash.duplicate())
	player_state.deck.append(whirlwind.duplicate())

	var nodes: Array[NodeData] = MapGenerator.generate()
	player_state.map_all_nodes.assign(nodes)
	var start_nodes: Array[NodeData] = []
	for nd in nodes:
		if nd.config.column == 0:
			start_nodes.append(nd)
	player_state.available_nodes.assign(start_nodes)

	current_phase = Phase.MAP
	get_tree().change_scene_to_file("res://map/MapScreen.tscn")

func select_node(node: NodeData) -> void:
	player_state.current_node = node
	match node.config.type:
		NodeConfig.Type.REST:
			go_to_rest()
		NodeConfig.Type.SHOP:
			go_to_shop()
		NodeConfig.Type.CHEST:
			go_to_chest()
		_:
			go_to_combat()

func go_to_combat() -> void:
	current_phase = Phase.COMBAT
	get_tree().change_scene_to_file("res://combat/CombatScreen.tscn")

func end_combat(final_hp: int) -> void:
	player_state.hp = final_hp
	pending_gold = RewardEngine.get_gold_reward(is_elite_node(), is_final_node())
	pending_relic = player_state.current_node.config.reward_relic
	go_to_reward()

func go_to_reward() -> void:
	current_phase = Phase.REWARD
	get_tree().change_scene_to_file("res://reward/RewardScreen.tscn")

func go_to_rest() -> void:
	player_state.apply_rest_heal()
	current_phase = Phase.REST
	get_tree().change_scene_to_file("res://rest/RestScreen.tscn")

func go_to_shop() -> void:
	current_phase = Phase.SHOP
	get_tree().change_scene_to_file("res://shop/ShopScreen.tscn")

func go_to_chest() -> void:
	assert(!CardPool.CHEST_RELICS.is_empty(), "chest relic pool is empty")
	pending_relic = load(CardPool.CHEST_RELICS[randi() % CardPool.CHEST_RELICS.size()]) as RelicData
	pending_gold = 0
	pending_card_reward = false
	go_to_reward()

func go_to_map() -> void:
	pending_card_reward = true
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

func go_to_char_select() -> void:
	current_phase = Phase.CHAR_SELECT
	get_tree().change_scene_to_file("res://char_select/CharSelectScreen.tscn")

func go_to_menu() -> void:
	player_state = null
	current_phase = Phase.MENU
	get_tree().change_scene_to_file("res://menu/MainMenu.tscn")

func get_current_enemy_group() -> EnemyGroupData:
	return player_state.current_node.config.enemy_group

func is_final_node() -> bool:
	return player_state.current_node.connections.is_empty()

func is_elite_node() -> bool:
	return player_state.current_node.config.type == NodeConfig.Type.ELITE

func collect_gold(amount: int) -> void:
	player_state.gold += amount
	pending_gold = 0

func collect_relic() -> void:
	if pending_relic == null:
		return
	player_state.relics.append(pending_relic.duplicate())
	pending_relic = null
