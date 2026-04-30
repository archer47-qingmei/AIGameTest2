class_name MapGenerator
extends RefCounted

const COMBAT_ENEMY_PATHS: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
const ELITE_ENEMY_PATH: String = "res://data/enemies/elite_guard.tres"
const BOSS_ENEMY_PATH: String = "res://data/enemies/boss.tres"
const ELITE_REWARD_RELIC_PATH: String = "res://data/relics/burning_gem.tres"
const BOSS_REWARD_RELIC_PATH: String = "res://data/relics/life_ring.tres"

static func generate() -> Array[NodeData]:
	var col0: Array[NodeData] = _make_col0()
	var col1: Array[NodeData] = _make_col1()
	var col2: Array[NodeData] = _make_col2()
	var col3: Array[NodeData] = _make_col3()
	for nd in col0:
		nd.connections.assign(col1)
	for nd in col1:
		nd.connections.assign(col2)
	for nd in col2:
		nd.connections.assign(col3)
	var all: Array[NodeData] = []
	all.append_array(col0)
	all.append_array(col1)
	all.append_array(col2)
	all.append_array(col3)
	_add_shop_node(all)
	return all

static func _make_col0() -> Array[NodeData]:
	var enemy_paths: Array[String] = COMBAT_ENEMY_PATHS.duplicate()
	enemy_paths.shuffle()
	var result: Array[NodeData] = []
	for row in 2:
		var nd := NodeData.new()
		nd.config = NodeConfig.new()
		nd.config.type = NodeConfig.Type.COMBAT
		nd.config.enemy_data = load(enemy_paths[row]) as EnemyData
		nd.config.column = 0
		nd.config.row = row
		result.append(nd)
	return result

static func _make_col1() -> Array[NodeData]:
	var types: Array = [NodeConfig.Type.COMBAT, NodeConfig.Type.REST]
	types.shuffle()
	var result: Array[NodeData] = []
	for row in 2:
		var nd := NodeData.new()
		nd.config = NodeConfig.new()
		nd.config.type = types[row]
		nd.config.column = 1
		nd.config.row = row
		if nd.config.type == NodeConfig.Type.COMBAT:
			nd.config.enemy_data = _random_combat_enemy()
		result.append(nd)
	return result

static func _make_col2() -> Array[NodeData]:
	var combos: Array = [
		[NodeConfig.Type.COMBAT, NodeConfig.Type.REST],
		[NodeConfig.Type.COMBAT, NodeConfig.Type.ELITE],
		[NodeConfig.Type.REST,   NodeConfig.Type.ELITE],
	]
	var combo: Array = combos[randi() % combos.size()].duplicate()
	combo.shuffle()
	var result: Array[NodeData] = []
	for row in 2:
		var nd := NodeData.new()
		nd.config = NodeConfig.new()
		nd.config.type = combo[row]
		nd.config.column = 2
		nd.config.row = row
		match nd.config.type:
			NodeConfig.Type.COMBAT:
				nd.config.enemy_data = _random_combat_enemy()
			NodeConfig.Type.ELITE:
				nd.config.enemy_data = load(ELITE_ENEMY_PATH) as EnemyData
				nd.config.reward_relic = load(ELITE_REWARD_RELIC_PATH) as RelicData
		result.append(nd)
	return result

static func _make_col3() -> Array[NodeData]:
	var nd := NodeData.new()
	nd.config = NodeConfig.new()
	nd.config.type = NodeConfig.Type.COMBAT
	nd.config.enemy_data = load(BOSS_ENEMY_PATH) as EnemyData
	nd.config.reward_relic = load(BOSS_REWARD_RELIC_PATH) as RelicData
	nd.config.column = 3
	nd.config.row = 0
	var result: Array[NodeData] = [nd]
	return result

static func _random_combat_enemy() -> EnemyData:
	return load(COMBAT_ENEMY_PATHS[randi() % COMBAT_ENEMY_PATHS.size()]) as EnemyData

static func _add_shop_node(all_nodes: Array[NodeData]) -> void:
	var candidates: Array[NodeData] = []
	for nd: NodeData in all_nodes:
		if nd.config.column in [1, 2] and nd.config.type != NodeConfig.Type.ELITE:
			candidates.append(nd)
	if candidates.is_empty():
		return
	var chosen: NodeData = candidates[randi() % candidates.size()]
	chosen.config.type = NodeConfig.Type.SHOP
	chosen.config.enemy_data = null
