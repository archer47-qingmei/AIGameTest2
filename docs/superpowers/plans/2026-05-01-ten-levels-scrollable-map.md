# v0.27.0 十关卡滚动地图 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将地图从 4 列扩展到 10 列，地图界面加入 ScrollContainer 支持竖向滚动，玩家从底部起点向上滑动至 Boss。

**Architecture:** 重构 `MapGenerator.gd` 为通用列生成逻辑（`_make_column`），修改 `MapScreen.tscn` 加入 ScrollContainer + MapContent 层级，更新 `MapScreen.gd` 的坐标公式、按钮添加目标、连线绘制目标。

**Tech Stack:** Godot 4 GDScript，项目分辨率 480×854（已有）。

---

## 涉及文件

| 文件 | 改动 |
|------|------|
| `MapGenerator.gd` | 替换四个 _make_colN 方法为通用 _make_column，新增 TOTAL_COLUMNS，改 _add_shop_nodes |
| `map/MapScreen.tscn` | 加入 ScrollContainer + MapContent 节点 |
| `map/MapScreen.gd` | 更新 _get_node_pos()，按钮/连线绘制到 MapContent |

---

## Task 1: 重构 MapGenerator 为 10 列

**Files:**
- Modify: `MapGenerator.gd`

**背景：** 当前 `MapGenerator.gd` 有四个硬编码方法 `_make_col0/1/2/3()`，生成 4 列地图。新实现用通用方法 `_make_column(col: int)` 生成 10 列，按 phase 分配节点类型：col 0-3 全战斗，col 4-5 战斗/休息，col 6-7 精英/战斗，col 8 双精英，col 9（Boss）单节点居中。商店从 col 4-8 的战斗节点中随机选 2 个替换。

- [ ] **Step 1: 替换 MapGenerator.gd**

将 `MapGenerator.gd` 完整替换为以下内容：

```gdscript
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
		return [NodeConfig.Type.ELITE, NodeConfig.Type.ELITE]

static func _random_combat_enemy() -> EnemyData:
	return load(COMBAT_ENEMY_PATHS[randi() % COMBAT_ENEMY_PATHS.size()]) as EnemyData

static func _add_shop_nodes(all_nodes: Array[NodeData]) -> void:
	var candidates: Array[NodeData] = []
	for nd: NodeData in all_nodes:
		if nd.config.column >= 4 and nd.config.column <= 8 and nd.config.type == NodeConfig.Type.COMBAT:
			candidates.append(nd)
	candidates.shuffle()
	for i in mini(2, candidates.size()):
		candidates[i].config.type = NodeConfig.Type.SHOP
		candidates[i].config.enemy_data = null
```

- [ ] **Step 2: 运行项目验证无解析错误**

使用 `mcp__godot__run_project`（projectPath: `E:\MyWork\AIGameTest2`），等待 3 秒后用 `mcp__godot__get_debug_output` 确认无 GDScript 解析错误（`icon.svg` 相关报错是预存问题，忽略）。然后 `mcp__godot__stop_project`。

- [ ] **Step 3: Commit**

```bash
git add MapGenerator.gd
git commit -m "feat: generalize MapGenerator to 10 columns with phase-based node types"
```

---

## Task 2: 更新 MapScreen.tscn 加入滚动层级

**Files:**
- Modify: `map/MapScreen.tscn`

**背景：** 当前场景只有 MapScreen（Control）+ LblTitle + LblHP。需要在 MapScreen 下加入 ScrollContainer（高度从 y=100 到底部），其子节点 MapContent（Control，高度 1650px）用于放置地图按钮和连线绘制。LblTitle/LblHP 保持为 MapScreen 的直接子节点（作为顶部覆盖层）。

- [ ] **Step 1: 替换 map/MapScreen.tscn**

将 `map/MapScreen.tscn` 完整替换为以下内容：

```
[gd_scene load_steps=2 format=3 uid="uid://dmap8x3qnc5vy"]

[ext_resource type="Script" path="res://map/MapScreen.gd" id="1_script"]

[node name="MapScreen" type="Control"]
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
script = ExtResource("1_script")

[node name="LblTitle" type="Label" parent="."]
layout_mode = 1
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
offset_left = -100.0
offset_top = 20.0
offset_right = 100.0
offset_bottom = 55.0
text = "选择关卡"
horizontal_alignment = 1
z_index = 1

[node name="LblHP" type="Label" parent="."]
layout_mode = 1
anchor_left = 0.5
anchor_top = 0.0
anchor_right = 0.5
anchor_bottom = 0.0
offset_left = -100.0
offset_top = 60.0
offset_right = 100.0
offset_bottom = 90.0
text = "生命：? / ?"
horizontal_alignment = 1
z_index = 1

[node name="ScrollContainer" type="ScrollContainer" parent="."]
layout_mode = 1
anchor_right = 1.0
anchor_bottom = 1.0
offset_top = 100.0
scroll_horizontal_enabled = false

[node name="MapContent" type="Control" parent="ScrollContainer"]
layout_mode = 2
custom_minimum_size = Vector2(480, 1650)
```

- [ ] **Step 2: Commit**

```bash
git add map/MapScreen.tscn
git commit -m "feat: add ScrollContainer and MapContent to MapScreen scene"
```

---

## Task 3: 更新 MapScreen.gd 使用新布局

**Files:**
- Modify: `map/MapScreen.gd`

**背景：** 需要三处改动：
1. `_get_node_pos()` 使用新公式（10 列，col_y = 1500 - col×150，Boss 居中 (240,150)）
2. `_build_map()` 中 `add_child(btn)` 改为 `_map_content.add_child(btn)`
3. `_draw()` 改为连接 `_map_content.draw` 信号，在 MapContent 坐标系中绘制连线
4. `_ready()` 末尾延迟一帧后将 ScrollContainer 滚动到底部

**当前 `map/MapScreen.gd` 完整内容（已读取）：**

```gdscript
extends Control

@onready var _lbl_hp: Label = $LblHP

var _node_positions: Dictionary = {}
var _state: PlayerState = null

func _ready() -> void:
    var state: PlayerState = GameManager.player_state
    _state = state
    _lbl_hp.text = "生命：%d / %d" % [state.hp, state.max_hp]
    _build_map(state)
    queue_redraw()

func _build_map(state: PlayerState) -> void:
    for nd: NodeData in state.map_all_nodes:
        var center: Vector2 = _get_node_pos(nd)
        _node_positions[nd] = center
        var btn := Button.new()
        btn.size = Vector2(110.0, 50.0)
        btn.position = center - Vector2(55.0, 25.0)
        var is_available: bool = state.available_nodes.has(nd)
        var is_completed: bool = state.completed_nodes.has(nd)
        if is_completed:
            btn.text = "✓ " + _get_node_label(nd)
            btn.disabled = true
        elif is_available:
            btn.text = _get_node_label(nd)
            btn.pressed.connect(GameManager.select_node.bind(nd))
        else:
            btn.text = _get_node_label(nd)
            btn.disabled = true
        add_child(btn)

func _draw() -> void:
    if _state == null:
        return
    for nd: NodeData in _state.map_all_nodes:
        if not _node_positions.has(nd):
            continue
        var from: Vector2 = _node_positions[nd]
        for target: NodeData in nd.connections:
            if not _node_positions.has(target):
                continue
            var to: Vector2 = _node_positions[target]
            var color: Color = Color(0.4, 1.0, 0.4) if _state.completed_nodes.has(nd) \
                               else Color(0.5, 0.5, 0.5)
            draw_line(from, to, color, 2.0)

func _get_node_pos(nd: NodeData) -> Vector2:
    if nd.config.column == 3:
        return Vector2(240.0, 150.0)
    var row_x: float = 140.0 if nd.config.row == 0 else 340.0
    var col_y: float
    match nd.config.column:
        0: col_y = 660.0
        1: col_y = 490.0
        2: col_y = 320.0
        _: col_y = 660.0
    return Vector2(row_x, col_y)

func _get_node_label(nd: NodeData) -> String:
    if nd.connections.is_empty():
        return "Boss 战斗"
    match nd.config.type:
        NodeConfig.Type.REST:
            return "休息站"
        NodeConfig.Type.ELITE:
            return "精英战斗"
        NodeConfig.Type.SHOP:
            return "商店"
    return "战斗"
```

- [ ] **Step 1: 替换 map/MapScreen.gd**

将 `map/MapScreen.gd` 完整替换为以下内容：

```gdscript
extends Control

@onready var _lbl_hp: Label = $LblHP
@onready var _scroll: ScrollContainer = $ScrollContainer
@onready var _map_content: Control = $ScrollContainer/MapContent

var _node_positions: Dictionary = {}
var _state: PlayerState = null

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	_state = state
	_lbl_hp.text = "生命：%d / %d" % [state.hp, state.max_hp]
	_build_map(state)
	_map_content.draw.connect(_draw_connections)
	_map_content.queue_redraw()
	await get_tree().process_frame
	_scroll.scroll_vertical = 99999

func _build_map(state: PlayerState) -> void:
	for nd: NodeData in state.map_all_nodes:
		var center: Vector2 = _get_node_pos(nd)
		_node_positions[nd] = center
		var btn := Button.new()
		btn.size = Vector2(110.0, 50.0)
		btn.position = center - Vector2(55.0, 25.0)
		var is_available: bool = state.available_nodes.has(nd)
		var is_completed: bool = state.completed_nodes.has(nd)
		if is_completed:
			btn.text = "✓ " + _get_node_label(nd)
			btn.disabled = true
		elif is_available:
			btn.text = _get_node_label(nd)
			btn.pressed.connect(GameManager.select_node.bind(nd))
		else:
			btn.text = _get_node_label(nd)
			btn.disabled = true
		_map_content.add_child(btn)

func _draw_connections() -> void:
	if _state == null:
		return
	for nd: NodeData in _state.map_all_nodes:
		if not _node_positions.has(nd):
			continue
		var from: Vector2 = _node_positions[nd]
		for target: NodeData in nd.connections:
			if not _node_positions.has(target):
				continue
			var to: Vector2 = _node_positions[target]
			var color: Color = Color(0.4, 1.0, 0.4) if _state.completed_nodes.has(nd) \
							   else Color(0.5, 0.5, 0.5)
			_map_content.draw_line(from, to, color, 2.0)

func _get_node_pos(nd: NodeData) -> Vector2:
	if nd.config.column == MapGenerator.TOTAL_COLUMNS - 1:
		return Vector2(240.0, 150.0)
	var row_x: float = 140.0 if nd.config.row == 0 else 340.0
	var col_y: float = 1500.0 - nd.config.column * 150.0
	return Vector2(row_x, col_y)

func _get_node_label(nd: NodeData) -> String:
	if nd.connections.is_empty():
		return "Boss 战斗"
	match nd.config.type:
		NodeConfig.Type.REST:
			return "休息站"
		NodeConfig.Type.ELITE:
			return "精英战斗"
		NodeConfig.Type.SHOP:
			return "商店"
	return "战斗"
```

- [ ] **Step 2: 运行项目验证**

使用 `mcp__godot__run_project`（projectPath: `E:\MyWork\AIGameTest2`），等待 5 秒后用 `mcp__godot__get_debug_output` 确认：
1. 无 GDScript 解析错误
2. 无 `@onready` 节点找不到的错误（如 "Node not found: ScrollContainer"）

然后 `mcp__godot__stop_project`。

- [ ] **Step 3: Commit**

```bash
git add map/MapScreen.gd
git commit -m "feat: update MapScreen for 10-column scrollable portrait layout"
```
