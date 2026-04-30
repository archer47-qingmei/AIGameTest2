class_name MapGenerator
extends RefCounted

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
	return all

static func _make_col0() -> Array[NodeData]:
	var enemy_paths: Array[String] = [
		"res://data/enemies/jaw_worm.tres",
		"res://data/enemies/fire_lizard.tres",
	]
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
				nd.config.enemy_data = load("res://data/enemies/elite_guard.tres") as EnemyData
		result.append(nd)
	return result

static func _make_col3() -> Array[NodeData]:
	var nd := NodeData.new()
	nd.config = NodeConfig.new()
	nd.config.type = NodeConfig.Type.COMBAT
	nd.config.enemy_data = load("res://data/enemies/boss.tres") as EnemyData
	nd.config.column = 3
	nd.config.row = 0
	var result: Array[NodeData] = [nd]
	return result

static func _random_combat_enemy() -> EnemyData:
	var paths: Array[String] = [
		"res://data/enemies/jaw_worm.tres",
		"res://data/enemies/fire_lizard.tres",
	]
	return load(paths[randi() % paths.size()]) as EnemyData
