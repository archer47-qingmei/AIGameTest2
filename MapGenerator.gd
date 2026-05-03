class_name MapGenerator
extends RefCounted

const TOTAL_COLUMNS: int = 10

const EARLY_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_stone_demon.tres",
	"res://data/enemy_groups/pair_fire_bat.tres",
	"res://data/enemy_groups/triple_fire_bat.tres",
	"res://data/enemy_groups/single_bronze_corpse.tres",
]
const MID_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_illusion_moth.tres",
	"res://data/enemy_groups/single_poison_slime.tres",
]
const ELITE_GROUP_PATH: String = "res://data/enemy_groups/single_elite_guard.tres"
const BOSS_GROUP_PATH: String = "res://data/enemy_groups/single_boss.tres"
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
		nd.config.enemy_group = load(BOSS_GROUP_PATH) as EnemyGroupData
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
				nd.config.enemy_group = _random_combat_group(col)
			NodeConfig.Type.ELITE:
				nd.config.enemy_group = load(ELITE_GROUP_PATH) as EnemyGroupData
				nd.config.reward_relic = load(ELITE_REWARD_RELIC_PATH) as RelicData
		result.append(nd)
	return result

static func _get_column_types(col: int) -> Array:
	match col:
		0, 1, 2, 3:
			return [NodeConfig.Type.COMBAT, NodeConfig.Type.COMBAT]
		4:
			var types: Array = [NodeConfig.Type.COMBAT, NodeConfig.Type.REST]
			types.shuffle()
			return types
		5:
			return [NodeConfig.Type.CHEST, NodeConfig.Type.REST]
		6, 7:
			var types: Array = [NodeConfig.Type.ELITE, NodeConfig.Type.COMBAT]
			types.shuffle()
			return types
		8:
			return [NodeConfig.Type.ELITE, NodeConfig.Type.ELITE]
		_:
			push_error("unexpected column %d" % col)
			return [NodeConfig.Type.COMBAT, NodeConfig.Type.COMBAT]

static func _random_combat_group(col: int) -> EnemyGroupData:
	var paths: Array[String] = EARLY_GROUP_PATHS if col <= 3 else MID_GROUP_PATHS
	return load(paths[randi() % paths.size()]) as EnemyGroupData

static func _add_shop_nodes(all_nodes: Array[NodeData]) -> void:
	var candidates: Array[NodeData] = []
	for nd: NodeData in all_nodes:
		if nd.config.column >= 4 and nd.config.column <= 7 and nd.config.type == NodeConfig.Type.COMBAT:
			candidates.append(nd)
	candidates.shuffle()
	for i in mini(2, candidates.size()):
		candidates[i].config.type = NodeConfig.Type.SHOP
		candidates[i].config.enemy_group = null
