class_name MapGenerator
extends RefCounted

const TOTAL_COLUMNS: int = 10

const COMBAT_ENEMY_PATHS: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
const ELITE_ENEMY_PATH: String = "res://data/enemies/elite_guard.tres"
const BOSS_ENEMY_PATH: String = "res://data/enemies/boss.tres"
const ELITE_REWARD_RELIC_PATH: String = "res://data/relics/burning_gem.tres"
const BOSS_REWARD_RELIC_PATH: String = "res://data/relics/life_ring.tres"

static func generate() -> Array[NodeData]:
	var columns: Array = []
	for col in TOTAL_COLUMNS:
		columns.append(_make_column(col))
	for i in TOTAL_COLUMNS - 1:
		for nd in columns[i]:
			nd.connections.assign(columns[i + 1])
	var all: Array[NodeData] = []
	for col_nodes in columns:
		all.append_array(col_nodes)
	_add_shop_nodes(all)
	return all

static func _make_column(col: int) -> Array[NodeData]:
	if col == TOTAL_COLUMNS - 1:
		var nd := NodeData.new()
		nd.config = NodeConfig.new()
		nd.config.type = NodeConfig.Type.COMBAT
		nd.config.enemy_data = load(BOSS_ENEMY_PATH) as EnemyData
		nd.config.reward_relic = load(BOSS_REWARD_RELIC_PATH) as RelicData
		nd.config.column = col
		nd.config.row = 0
		return [nd]
	var types: Array = _get_column_types(col)
	var result: Array[NodeData] = []
	for row in 2:
		var nd := NodeData.new()
		nd.config = NodeConfig.new()
		nd.config.type = types[row]
		nd.config.column = col
		nd.config.row = row
		match nd.config.type:
			NodeConfig.Type.COMBAT:
				nd.config.enemy_data = _random_combat_enemy()
			NodeConfig.Type.ELITE:
				nd.config.enemy_data = load(ELITE_ENEMY_PATH) as EnemyData
				nd.config.reward_relic = load(ELITE_REWARD_RELIC_PATH) as RelicData
		result.append(nd)
	return result

static func _get_column_types(col: int) -> Array:
	if col <= 3:
		return [NodeConfig.Type.COMBAT, NodeConfig.Type.COMBAT]
	elif col <= 5:
		var types: Array = [NodeConfig.Type.COMBAT, NodeConfig.Type.REST]
		types.shuffle()
		return types
	elif col <= 7:
		var types: Array = [NodeConfig.Type.ELITE, NodeConfig.Type.COMBAT]
		types.shuffle()
		return types
	else:
		assert(col == 8, "unexpected column %d" % col)
		return [NodeConfig.Type.ELITE, NodeConfig.Type.ELITE]

static func _random_combat_enemy() -> EnemyData:
	return load(COMBAT_ENEMY_PATHS[randi() % COMBAT_ENEMY_PATHS.size()]) as EnemyData

static func _add_shop_nodes(all_nodes: Array[NodeData]) -> void:
	var candidates: Array[NodeData] = []
	for nd: NodeData in all_nodes:
		if nd.config.column >= 4 and nd.config.column <= 7 and nd.config.type == NodeConfig.Type.COMBAT:
			candidates.append(nd)
	candidates.shuffle()
	for i in mini(2, candidates.size()):
		candidates[i].config.type = NodeConfig.Type.SHOP
		candidates[i].config.enemy_data = null
