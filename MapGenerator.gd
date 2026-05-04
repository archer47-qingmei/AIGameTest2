class_name MapGenerator
extends RefCounted

const TOTAL_COLUMNS: int = 10
const NUM_PATHS: int = 5
const NUM_ROWS: int = 3

const EARLY_ELITE_MAX_COL: int = 3
const REST_COL: int = 4
const CHEST_REST_COL: int = 5
const ELITE_START_COL: int = 6
const ELITE_END_COL: int = 8
const BOSS_MAP_POSITION: Vector2 = Vector2(240.0, 80.0)

const EARLY_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_stone_demon.tres",
	"res://data/enemy_groups/single_bronze_corpse.tres",
	"res://data/enemy_groups/single_sword_shadow.tres",
	"res://data/enemy_groups/single_thunder_frog.tres",
	"res://data/enemy_groups/banner_stone_demon.tres",
]
const MID_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_illusion_moth.tres",
	"res://data/enemy_groups/single_poison_slime.tres",
	"res://data/enemy_groups/pair_fire_bat.tres",
	"res://data/enemy_groups/triple_fire_bat.tres",
	"res://data/enemy_groups/banner_fire_bat_pair.tres",
]
const ELITE_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_elite_sorcerer.tres",
	"res://data/enemy_groups/single_three_headed_python.tres",
	"res://data/enemy_groups/blood_fiend_group.tres",
]
const BOSS_GROUP_PATH: String = "res://data/enemy_groups/single_boss.tres"
const ELITE_REWARD_RELIC_PATH: String = "res://data/relics/burning_gem.tres"
const BOSS_REWARD_RELIC_PATH: String = "res://data/relics/life_ring.tres"

const ROW_BASE_X: Array[float] = [80.0, 240.0, 400.0]
const ROW_OFFSET_RANGE: float = 25.0
const COL_BASE_Y: float = 1500.0
const COL_STEP_Y: float = 150.0
const COL_OFFSET_RANGE: float = 20.0

static func generate() -> Array[NodeData]:
	var node_grid: Dictionary = {}

	var boss := NodeData.new()
	boss.config = NodeConfig.new()
	boss.config.column = TOTAL_COLUMNS - 1
	boss.config.row = 1
	boss.config.type = NodeConfig.Type.BOSS
	boss.config.enemy_group = load(BOSS_GROUP_PATH) as EnemyGroupData
	boss.config.reward_relic = load(BOSS_REWARD_RELIC_PATH) as RelicData
	boss.config.map_position = BOSS_MAP_POSITION
	node_grid[Vector2i(TOTAL_COLUMNS - 1, 1)] = boss

	for _p in NUM_PATHS:
		var row: int = randi() % NUM_ROWS
		var prev_nd: NodeData = null
		for col in TOTAL_COLUMNS - 1:
			var key := Vector2i(col, row)
			if not node_grid.has(key):
				node_grid[key] = _make_node(col, row)
			var nd: NodeData = node_grid[key]
			if prev_nd != null and not prev_nd.connections.has(nd):
				prev_nd.connections.append(nd)
			prev_nd = nd
			row = clampi(row + (randi() % 3) - 1, 0, NUM_ROWS - 1)
		if prev_nd != null and not prev_nd.connections.has(boss):
			prev_nd.connections.append(boss)

	var all: Array[NodeData] = []
	for nd: NodeData in node_grid.values():
		all.append(nd)
	_assign_types(all)
	_add_shop_nodes(all)
	return all

static func _make_node(col: int, row: int) -> NodeData:
	var nd := NodeData.new()
	nd.config = NodeConfig.new()
	nd.config.column = col
	nd.config.row = row
	nd.config.type = NodeConfig.Type.COMBAT
	nd.config.map_position = Vector2(
		ROW_BASE_X[row] + randf_range(-ROW_OFFSET_RANGE, ROW_OFFSET_RANGE),
		COL_BASE_Y - col * COL_STEP_Y + randf_range(-COL_OFFSET_RANGE, COL_OFFSET_RANGE)
	)
	return nd

static func _assign_types(all: Array[NodeData]) -> void:
	var by_col: Dictionary = {}
	for nd: NodeData in all:
		var col: int = nd.config.column
		if col == TOTAL_COLUMNS - 1:
			continue
		if not by_col.has(col):
			by_col[col] = []
		by_col[col].append(nd)

	for col in range(0, TOTAL_COLUMNS - 1):
		var nodes: Array = by_col.get(col, [])
		if nodes.is_empty():
			continue
		for nd: NodeData in nodes:
			nd.config.enemy_group = _random_combat_group(col)
		match col:
			REST_COL:
				if nodes.size() >= 2:
					nodes.shuffle()
					nodes[0].config.type = NodeConfig.Type.REST
					nodes[0].config.enemy_group = null
			CHEST_REST_COL:
				nodes.shuffle()
				nodes[0].config.type = NodeConfig.Type.CHEST
				nodes[0].config.enemy_group = null
				if nodes.size() >= 2:
					nodes[1].config.type = NodeConfig.Type.REST
					nodes[1].config.enemy_group = null
			ELITE_START_COL, ELITE_START_COL + 1, ELITE_END_COL:
				nodes.shuffle()
				nodes[0].config.type = NodeConfig.Type.ELITE
				nodes[0].config.enemy_group = load(ELITE_GROUP_PATHS[randi() % ELITE_GROUP_PATHS.size()]) as EnemyGroupData
				nodes[0].config.reward_relic = load(ELITE_REWARD_RELIC_PATH) as RelicData

	var early_elite_col: int = randi() % (EARLY_ELITE_MAX_COL + 1)
	var early_nodes: Array = by_col.get(early_elite_col, [])
	if not early_nodes.is_empty():
		early_nodes.shuffle()
		early_nodes[0].config.type = NodeConfig.Type.ELITE
		early_nodes[0].config.enemy_group = load(ELITE_GROUP_PATHS[randi() % ELITE_GROUP_PATHS.size()]) as EnemyGroupData
		early_nodes[0].config.reward_relic = load(ELITE_REWARD_RELIC_PATH) as RelicData

static func _random_combat_group(col: int) -> EnemyGroupData:
	var paths: Array[String] = EARLY_GROUP_PATHS if col <= 3 else MID_GROUP_PATHS
	return load(paths[randi() % paths.size()]) as EnemyGroupData

static func _add_shop_nodes(all_nodes: Array[NodeData]) -> void:
	var candidates: Array[NodeData] = []
	for nd: NodeData in all_nodes:
		if nd.config.column >= REST_COL and nd.config.column <= ELITE_START_COL + 1 and nd.config.type == NodeConfig.Type.COMBAT:
			candidates.append(nd)
	candidates.shuffle()
	for i in mini(2, candidates.size()):
		candidates[i].config.type = NodeConfig.Type.SHOP
		candidates[i].config.enemy_group = null
