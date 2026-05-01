# v0.29.0 多敌人战斗 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 支持一场战斗最多出现 6 个敌人，玩家通过点选方式对单体敌人出牌，敌人按顺序依次行动。

**Architecture:** 新增 `EnemyGroupData` 资源替代单个 `EnemyData`；`CardData` 加 `target_type` 字段区分单体/无目标牌；`CombatEngine` 将 `enemy` 改为 `enemies: Array[Combatant]`，`play_card` 接受 `target_index`；`CombatScreen` 动态生成敌人按钮面板并管理目标选择状态；`NodeConfig`/`MapGenerator`/`GameManager` 切换到 group 粒度。

**Tech Stack:** Godot 4 GDScript，数据层 `.tres` 文件，无自动化测试框架（用 Godot 运行项目手动验证）。

---

### Task 1：EnemyGroupData.gd + group .tres 文件

**Files:**
- Create: `E:\MyWork\AIGameTest2\EnemyGroupData.gd`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\single_jaw_worm.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\single_fire_lizard.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\pair_early.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\single_poison_spider.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\single_swamp_slime.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\pair_mid.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\single_elite_guard.tres`
- Create: `E:\MyWork\AIGameTest2\data\enemy_groups\single_boss.tres`

- [ ] **Step 1: 创建 EnemyGroupData.gd**

```gdscript
class_name EnemyGroupData
extends Resource

@export var enemies: Array[EnemyData] = []
```

- [ ] **Step 2: 获取 EnemyGroupData.gd 的 UID**

用 `mcp__godot__get_uid` 工具查询路径 `res://EnemyGroupData.gd`。
若返回 UID，记录下来（形如 `uid://xxxxxxxxxx`），后续 .tres 文件中会用到。
若返回错误（文件还未被 Godot 扫描），先运行项目一次再重试，或者在 .tres 文件中省略 uid 属性。

- [ ] **Step 3: 获取各敌人文件的 UID**

依次用 `mcp__godot__get_uid` 查询以下路径，记录返回的 uid 值：
- `res://data/enemies/jaw_worm.tres`
- `res://data/enemies/fire_lizard.tres`
- `res://data/enemies/poison_spider.tres`
- `res://data/enemies/swamp_slime.tres`
- `res://data/enemies/elite_guard.tres`
- `res://data/enemies/boss.tres`

已知 `res://EnemyData.gd` 的 uid = `uid://bp7tc2xnj6g4e`（来自现有 .tres 文件）。

- [ ] **Step 4: 创建 data/enemy_groups/ 目录并写入 single_jaw_worm.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=4 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<jaw_worm_uid>" path="res://data/enemies/jaw_worm.tres" id="3_jaw_worm"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_jaw_worm")])
```

将 `<EnemyGroupData_uid>` 和 `<jaw_worm_uid>` 替换为 Step 2/3 获取的实际值。
若某个 uid 获取失败，省略该 `uid="..."` 属性，仅保留 `path=`。
load_steps 规则：ext_resource 数量 + 1（根 resource）= load_steps。

- [ ] **Step 5: 写入 single_fire_lizard.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=4 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<fire_lizard_uid>" path="res://data/enemies/fire_lizard.tres" id="3_fire_lizard"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_fire_lizard")])
```

- [ ] **Step 6: 写入 pair_early.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=5 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<jaw_worm_uid>" path="res://data/enemies/jaw_worm.tres" id="3_jaw_worm"]
[ext_resource type="Resource" uid="<fire_lizard_uid>" path="res://data/enemies/fire_lizard.tres" id="4_fire_lizard"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_jaw_worm"), ExtResource("4_fire_lizard")])
```

- [ ] **Step 7: 写入 single_poison_spider.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=4 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<poison_spider_uid>" path="res://data/enemies/poison_spider.tres" id="3_poison_spider"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_poison_spider")])
```

- [ ] **Step 8: 写入 single_swamp_slime.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=4 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<swamp_slime_uid>" path="res://data/enemies/swamp_slime.tres" id="3_swamp_slime"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_swamp_slime")])
```

- [ ] **Step 9: 写入 pair_mid.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=5 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<poison_spider_uid>" path="res://data/enemies/poison_spider.tres" id="3_poison_spider"]
[ext_resource type="Resource" uid="<swamp_slime_uid>" path="res://data/enemies/swamp_slime.tres" id="4_swamp_slime"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_poison_spider"), ExtResource("4_swamp_slime")])
```

- [ ] **Step 10: 写入 single_elite_guard.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=4 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<elite_guard_uid>" path="res://data/enemies/elite_guard.tres" id="3_elite_guard"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_elite_guard")])
```

- [ ] **Step 11: 写入 single_boss.tres**

```
[gd_resource type="Resource" script_class="EnemyGroupData" load_steps=4 format=3]

[ext_resource type="Script" uid="<EnemyGroupData_uid>" path="res://EnemyGroupData.gd" id="1_GroupData"]
[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="2_EnemyData"]
[ext_resource type="Resource" uid="<boss_uid>" path="res://data/enemies/boss.tres" id="3_boss"]

[resource]
script = ExtResource("1_GroupData")
enemies = Array[ExtResource("2_EnemyData")]([ExtResource("3_boss")])
```

- [ ] **Step 12: Commit**

```bash
git add EnemyGroupData.gd data/enemy_groups/
git commit -m "feat: add EnemyGroupData and 8 enemy group resource files"
```

---

### Task 2：CardData.gd + card .tres target_type

**Files:**
- Modify: `E:\MyWork\AIGameTest2\CardData.gd`
- Modify: `E:\MyWork\AIGameTest2\data\cards\defend.tres`
- Modify: `E:\MyWork\AIGameTest2\data\cards\energize.tres`
- Modify: `E:\MyWork\AIGameTest2\data\cards\insight.tres`
- Modify: `E:\MyWork\AIGameTest2\data\cards\venom.tres`

**Context:** 当前 `CardData.gd` 已有 `is_venom`, `special_text` 字段。需新增 `target_type`。其余攻击牌（strike、bash、slash、dash、quick_strike、entangle）保持默认 `"single"` 无需修改。

- [ ] **Step 1: 在 CardData.gd 新增字段**

在 `@export var special_text: String = ""` 后加一行：

```gdscript
@export var target_type: String = "single"
```

完整字段区域如下（仅展示新增行，其余不变）：

```gdscript
@export var is_venom: bool = false
@export var special_text: String = ""
@export var target_type: String = "single"
```

- [ ] **Step 2: 更新 defend.tres**

读取 `E:\MyWork\AIGameTest2\data\cards\defend.tres`，在 `[resource]` 块末尾加一行：

```
target_type = "none"
```

- [ ] **Step 3: 更新 energize.tres**

读取 `E:\MyWork\AIGameTest2\data\cards\energize.tres`，在 `[resource]` 块末尾加一行：

```
target_type = "none"
```

- [ ] **Step 4: 更新 insight.tres**

读取 `E:\MyWork\AIGameTest2\data\cards\insight.tres`，在 `[resource]` 块末尾加一行：

```
target_type = "none"
```

- [ ] **Step 5: 更新 venom.tres**

读取 `E:\MyWork\AIGameTest2\data\cards\venom.tres`，在 `[resource]` 块末尾加一行：

```
target_type = "none"
```

- [ ] **Step 6: Commit**

```bash
git add CardData.gd data/cards/defend.tres data/cards/energize.tres data/cards/insight.tres data/cards/venom.tres
git commit -m "feat: add target_type field to CardData; mark non-targeting cards as none"
```

---

### Task 3：NodeConfig.gd + MapGenerator.gd + GameManager.gd

**Files:**
- Modify: `E:\MyWork\AIGameTest2\NodeConfig.gd`
- Modify: `E:\MyWork\AIGameTest2\MapGenerator.gd`
- Modify: `E:\MyWork\AIGameTest2\GameManager.gd`

**Context — NodeConfig.gd 当前内容：**
```gdscript
class_name NodeConfig
extends Resource

enum Type { COMBAT, REST, ELITE, SHOP }

@export var type: Type = Type.COMBAT
@export var enemy_data: EnemyData
@export var column: int = 0
@export var row: int = 0
@export var reward_relic: RelicData
```

**Context — GameManager.gd 相关方法：**
```gdscript
func get_current_enemy_data() -> EnemyData:
    return player_state.current_node.config.enemy_data
```

- [ ] **Step 1: 修改 NodeConfig.gd**

将 `@export var enemy_data: EnemyData` 替换为：

```gdscript
@export var enemy_group: EnemyGroupData
```

完整文件如下：

```gdscript
class_name NodeConfig
extends Resource

enum Type { COMBAT, REST, ELITE, SHOP }

@export var type: Type = Type.COMBAT
@export var enemy_group: EnemyGroupData
@export var column: int = 0
@export var row: int = 0
@export var reward_relic: RelicData
```

- [ ] **Step 2: 修改 MapGenerator.gd**

用以下内容完整替换 `EARLY_ENEMY_PATHS` / `MID_ENEMY_PATHS` 常量区域，并更新相关方法。

完整新版 `MapGenerator.gd`：

```gdscript
class_name MapGenerator
extends RefCounted

const TOTAL_COLUMNS: int = 10

const EARLY_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_jaw_worm.tres",
	"res://data/enemy_groups/single_fire_lizard.tres",
	"res://data/enemy_groups/pair_early.tres",
]
const MID_GROUP_PATHS: Array[String] = [
	"res://data/enemy_groups/single_poison_spider.tres",
	"res://data/enemy_groups/single_swamp_slime.tres",
	"res://data/enemy_groups/pair_mid.tres",
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
	elif col == 8:
		return [NodeConfig.Type.ELITE, NodeConfig.Type.ELITE]
	else:
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
```

- [ ] **Step 3: 修改 GameManager.gd**

将 `get_current_enemy_data()` 方法替换为：

```gdscript
func get_current_enemy_group() -> EnemyGroupData:
	return player_state.current_node.config.enemy_group
```

- [ ] **Step 4: Commit**

```bash
git add NodeConfig.gd MapGenerator.gd GameManager.gd
git commit -m "refactor: replace enemy_data with enemy_group in NodeConfig, MapGenerator, GameManager"
```

---

### Task 4：EffectResolver.gd null guard + CombatEngine.gd 完整重构

**Files:**
- Modify: `E:\MyWork\AIGameTest2\EffectResolver.gd`
- Modify: `E:\MyWork\AIGameTest2\CombatEngine.gd`

**Context — 当前 EffectResolver.gd：**
```gdscript
static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> void:
    for effect: CardEffectData in card.effects:
        if effect.type == "damage":
            apply_damage(attacker, defender, effect.value)
        elif effect.type == "block":
            attacker.add_block(effect.value)
        elif effect.type == "weak":
            defender.add_weak(effect.value)
        elif effect.type == "vulnerable":
            defender.add_vulnerable(effect.value)
```

**Context — 当前 CombatEngine.gd 关键签名（见下方完整版）：**
- `var enemy: Combatant` → 改为 `var enemies: Array[Combatant]`
- `play_card(card: CardData)` → 改为 `play_card(card_index: int, target_index: int) -> bool`
- `get_current_enemy_action()` → 改为 `get_enemy_action(i: int) -> EnemyActionData`
- `_check_end()` 的胜利条件改为"存活敌人为 0"

- [ ] **Step 1: 修改 EffectResolver.gd 加 null guard**

```gdscript
class_name EffectResolver
extends RefCounted

static func resolve(card: CardData, attacker: Combatant, defender: Combatant) -> void:
	for effect: CardEffectData in card.effects:
		if effect.type == "damage":
			if defender != null:
				apply_damage(attacker, defender, effect.value)
		elif effect.type == "block":
			attacker.add_block(effect.value)
		elif effect.type == "weak":
			if defender != null:
				defender.add_weak(effect.value)
		elif effect.type == "vulnerable":
			if defender != null:
				defender.add_vulnerable(effect.value)

static func apply_damage(source: Combatant, target: Combatant, amount: int) -> void:
	var dmg: int = amount
	if source.weak > 0:
		dmg = int(dmg * 0.75)
	if target.vulnerable > 0:
		dmg = int(dmg * 1.5)
	target.take_damage(dmg)
```

- [ ] **Step 2: 用以下完整内容覆盖 CombatEngine.gd**

```gdscript
class_name CombatEngine
extends RefCounted

const BASE_ENERGY: int = 3

signal state_changed
signal combat_ended(result: String)

var player: Combatant
var enemies: Array[Combatant] = []
var hand: Array[CardData] = []
var energy: int = 0
var turn_number: int = 0

var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _enemy_data_list: Array[EnemyData] = []
var _relics: Array[RelicData] = []

func setup(initial_deck: Array[CardData], enemy_group: EnemyGroupData, initial_hp: int, max_hp: int, relics: Array[RelicData] = []) -> void:
	_relics = relics
	for data: EnemyData in enemy_group.enemies:
		var c := Combatant.new()
		c.display_name = data.display_name
		c.hp = data.hp
		c.max_hp = data.hp
		c.block = 0
		enemies.append(c)
		_enemy_data_list.append(data)

	player = Combatant.new()
	player.display_name = "玩家"
	player.hp = initial_hp
	player.max_hp = max_hp
	player.block = 0

	for card: CardData in initial_deck:
		_draw_pile.append(card.duplicate())
	_draw_pile.shuffle()
	_start_player_turn()

func get_enemy_action(i: int) -> EnemyActionData:
	var actions: Array = _enemy_data_list[i].actions
	return actions[(turn_number - 1) % actions.size()]

func get_draw_pile() -> Array[CardData]:
	return _draw_pile.duplicate()

func get_discard_pile() -> Array[CardData]:
	return _discard_pile.duplicate()

func play_card(card_index: int, target_index: int) -> bool:
	var card: CardData = hand[card_index]
	if card.cost > energy:
		return false
	energy -= card.cost
	var target: Combatant = enemies[target_index] if target_index >= 0 else null
	EffectResolver.resolve(card, player, target)
	_apply_engine_effects(card)
	hand.remove_at(card_index)
	_discard_pile.append(card)
	state_changed.emit()
	_check_end()
	return true

func end_turn() -> void:
	var venom_count: int = 0
	for card: CardData in hand:
		if card.is_venom:
			venom_count += 1
	if venom_count > 0:
		player.hp = max(0, player.hp - venom_count)
		state_changed.emit()
		if _check_end():
			return
	for card: CardData in hand:
		_discard_pile.append(card)
	hand.clear()
	_do_enemy_turn()
	state_changed.emit()
	if not _check_end():
		_start_player_turn()

func _start_player_turn() -> void:
	player.weak = max(0, player.weak - 1)
	turn_number += 1
	energy = BASE_ENERGY
	player.block = 0
	_draw_hand()
	if turn_number == 1:
		RelicEngine.apply_combat_start(_relics, self)
	RelicEngine.apply_turn_start(_relics, self)
	state_changed.emit()

func _refill_draw_pile_if_needed() -> void:
	if _draw_pile.is_empty() and not _discard_pile.is_empty():
		for card: CardData in _discard_pile:
			_draw_pile.append(card)
		_discard_pile.clear()
		_draw_pile.shuffle()

func _draw_hand() -> void:
	hand.clear()
	for i in 5:
		_refill_draw_pile_if_needed()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _apply_engine_effects(card: CardData) -> void:
	for effect: CardEffectData in card.effects:
		if effect.type == "draw":
			_draw_cards(effect.value)
		elif effect.type == "energy":
			energy += effect.value

func _draw_cards(n: int) -> void:
	for i: int in n:
		_refill_draw_pile_if_needed()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		hand.append(card)

func _do_enemy_turn() -> void:
	for i in enemies.size():
		if enemies[i].hp <= 0:
			continue
		enemies[i].block = 0
		enemies[i].vulnerable = max(0, enemies[i].vulnerable - 1)
		var action: EnemyActionData = get_enemy_action(i)
		if action.type == "attack":
			EffectResolver.apply_damage(enemies[i], player, action.value)
			enemies[i].weak = max(0, enemies[i].weak - 1)
		elif action.type == "poison":
			var venom_card: CardData = load("res://data/cards/venom.tres") as CardData
			for j in action.value:
				_draw_pile.append(venom_card.duplicate())
			_draw_pile.shuffle()
		else:
			enemies[i].add_block(action.value)

func _get_living_enemies() -> Array[Combatant]:
	return enemies.filter(func(e: Combatant) -> bool: return e.hp > 0)

func _check_end() -> bool:
	if _get_living_enemies().is_empty():
		combat_ended.emit("victory")
		return true
	if player.hp <= 0:
		combat_ended.emit("game_over")
		return true
	return false
```

- [ ] **Step 3: Commit**

```bash
git add EffectResolver.gd CombatEngine.gd
git commit -m "refactor: CombatEngine supports multiple enemies; EffectResolver handles null target"
```

---

### Task 5：CombatScreen.tscn + CombatScreen.gd 完整重构

**Files:**
- Modify: `E:\MyWork\AIGameTest2\combat\CombatScreen.tscn`
- Modify: `E:\MyWork\AIGameTest2\combat\CombatScreen.gd`

**Context — 场景变更：**
当前 `VBoxContainer` 下有 `EnemyPanel`（VBoxContainer）及其 6 个 Label 子节点。
需删除整个 `EnemyPanel`（含子节点），改为一个 `HBoxContainer`（名为 `EnemiesContainer`）。
敌人按钮在运行时动态添加，场景中不预先创建。

**Context — GDScript 变更：**
- 删除所有 `_lbl_enemy_*` @onready 引用（6 行）
- 新增 `@onready var _enemies_container: HBoxContainer`
- 新增 `var _pending_card_index: int = -1`
- `_on_card_pressed(card: CardData)` → `_on_card_pressed(card_index: int)`
- `_engine.setup()` 改用 `GameManager.get_current_enemy_group()`
- 新增 `_build_enemy_panels()`, `_on_enemy_pressed()`, `_set_targeting_mode()`
- `_refresh_ui()` 改为按 `_engine.enemies` 迭代

- [ ] **Step 1: 修改 CombatScreen.tscn**

读取当前 `E:\MyWork\AIGameTest2\combat\CombatScreen.tscn`，将整个 `EnemyPanel` 节点块（从 `[node name="EnemyPanel"...` 到最后一个 `LblEnemyIntent` 子节点，共 7 个 node 块）替换为一个 HBoxContainer：

```
[node name="EnemiesContainer" type="HBoxContainer" parent="VBoxContainer"]
layout_mode = 2
```

删除的节点包括：
- `[node name="EnemyPanel" ...]`
- `[node name="LblEnemyName" ...]`
- `[node name="LblEnemyHP" ...]`
- `[node name="LblEnemyBlock" ...]`
- `[node name="LblEnemyWeak" ...]`
- `[node name="LblEnemyVulnerable" ...]`
- `[node name="LblEnemyIntent" ...]`

替换后对应位置只有一个节点：`EnemiesContainer`。

- [ ] **Step 2: 用以下完整内容覆盖 CombatScreen.gd**

```gdscript
extends Control

@onready var _enemies_container: HBoxContainer = $VBoxContainer/EnemiesContainer
@onready var _lbl_player_hp: Label     = $VBoxContainer/PlayerPanel/LblPlayerHP
@onready var _lbl_player_block: Label  = $VBoxContainer/PlayerPanel/LblPlayerBlock
@onready var _lbl_energy: Label        = $VBoxContainer/PlayerPanel/LblEnergy
@onready var _hand_container: HBoxContainer = $VBoxContainer/HandScroll/HandContainer
@onready var _btn_end_turn: Button     = $VBoxContainer/BtnEndTurn
@onready var _lbl_result: Label        = $LblResult
@onready var _btn_return_menu: Button  = $BtnReturnMenu
@onready var _btn_get_reward: Button   = $BtnGetReward
@onready var _btn_win: Button          = $BtnWin
@onready var _btn_view_deck: Button    = $VBoxContainer/BtnViewDeck
@onready var _deck_view_panel: Panel   = $DeckViewPanel
@onready var _btn_close_deck: Button   = $DeckViewPanel/VBoxContainer/BtnCloseDeck
@onready var _all_cards_list: VBoxContainer = $DeckViewPanel/VBoxContainer/TabContainer/完整牌组/AllCardsList
@onready var _draw_list: VBoxContainer      = $DeckViewPanel/VBoxContainer/TabContainer/抽牌堆/DrawList
@onready var _discard_list: VBoxContainer   = $DeckViewPanel/VBoxContainer/TabContainer/弃牌堆/DiscardList

var _engine: CombatEngine
var _hand_buttons: Array[Button] = []
var _lbl_relics: Label
var _pending_card_index: int = -1

func _ready() -> void:
	_lbl_relics = Label.new()
	$VBoxContainer/PlayerPanel.add_child(_lbl_relics)
	_engine = CombatEngine.new()
	_engine.state_changed.connect(_refresh_ui)
	_engine.combat_ended.connect(_on_combat_ended)
	_btn_end_turn.pressed.connect(_engine.end_turn)
	_btn_return_menu.pressed.connect(GameManager.go_to_menu)
	_btn_get_reward.pressed.connect(_on_proceed)
	_btn_win.pressed.connect(_on_proceed)
	_btn_view_deck.pressed.connect(_on_view_deck_pressed)
	_btn_close_deck.pressed.connect(_deck_view_panel.hide)
	_engine.setup(
		GameManager.player_state.deck,
		GameManager.get_current_enemy_group(),
		GameManager.player_state.hp,
		GameManager.player_state.max_hp,
		GameManager.player_state.relics
	)
	_build_enemy_panels()

func _build_enemy_panels() -> void:
	for child in _enemies_container.get_children():
		child.queue_free()
	for i in _engine.enemies.size():
		var btn := Button.new()
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_enemy_pressed.bind(i))
		btn.disabled = true
		_enemies_container.add_child(btn)

func _on_card_pressed(card_index: int) -> void:
	if _pending_card_index >= 0:
		_pending_card_index = -1
		_set_targeting_mode(false)
		return
	var card: CardData = _engine.hand[card_index]
	if card.target_type == "none":
		_engine.play_card(card_index, -1)
	else:
		_pending_card_index = card_index
		_set_targeting_mode(true)

func _on_enemy_pressed(enemy_index: int) -> void:
	if _pending_card_index >= 0:
		_engine.play_card(_pending_card_index, enemy_index)
		_pending_card_index = -1
		_set_targeting_mode(false)

func _set_targeting_mode(active: bool) -> void:
	_btn_end_turn.disabled = active
	for i in _enemies_container.get_child_count():
		var btn: Button = _enemies_container.get_child(i) as Button
		if i < _engine.enemies.size() and _engine.enemies[i].hp > 0:
			btn.disabled = not active

func _refresh_ui() -> void:
	for i in _engine.enemies.size():
		var e: Combatant = _engine.enemies[i]
		var btn: Button = _enemies_container.get_child(i) as Button
		if e.hp <= 0:
			btn.text = "%s\n(已死亡)" % e.display_name
			btn.disabled = true
		else:
			var action: EnemyActionData = _engine.get_enemy_action(i)
			btn.text = "%s\nHP:%d/%d 挡:%d\n%s" % [
				e.display_name, e.hp, e.max_hp, e.block,
				_intent_text(action, e)
			]
			btn.disabled = (_pending_card_index < 0)
	_lbl_player_hp.text = "生命：%d / %d" % [_engine.player.hp, _engine.player.max_hp]
	_lbl_player_block.text = "格挡：%d" % _engine.player.block
	_lbl_energy.text = "能量：%d / 3" % _engine.energy
	var relic_names: PackedStringArray = []
	for r: RelicData in GameManager.player_state.relics:
		relic_names.append(r.display_name)
	_lbl_relics.text = "遗物：" + ("、".join(relic_names) if not relic_names.is_empty() else "无")
	_rebuild_hand()

func _intent_text(action: EnemyActionData, e: Combatant) -> String:
	match action.type:
		"attack":
			var val: int = int(action.value * 0.75) if e.weak > 0 else action.value
			return "意图：攻击 %d" % val
		"poison":
			return "意图：投毒 %d" % action.value
		_:
			return "意图：格挡 %d" % action.value

func _rebuild_hand() -> void:
	for btn: Button in _hand_buttons:
		btn.queue_free()
	_hand_buttons.clear()
	for i in _engine.hand.size():
		var card: CardData = _engine.hand[i]
		var btn: Button = Button.new()
		btn.text = card.get_description()
		btn.pressed.connect(_on_card_pressed.bind(i))
		_hand_container.add_child(btn)
		_hand_buttons.append(btn)

func _on_combat_ended(result: String) -> void:
	_btn_end_turn.disabled = true
	for btn: Button in _hand_buttons:
		btn.disabled = true
	if result == "victory":
		_lbl_result.text = "胜利！"
	_lbl_result.visible = true
	if result == "victory":
		if GameManager.is_final_node():
			_btn_win.visible = true
		else:
			_btn_get_reward.visible = true
	else:
		GameManager.go_to_game_over()

func _on_view_deck_pressed() -> void:
	var all_cards: Array[CardData] = []
	for card: CardData in _engine.hand:
		all_cards.append(card)
	for card: CardData in _engine.get_draw_pile():
		all_cards.append(card)
	for card: CardData in _engine.get_discard_pile():
		all_cards.append(card)
	_populate_list(_all_cards_list, all_cards)
	_populate_list(_draw_list, _engine.get_draw_pile())
	_populate_list(_discard_list, _engine.get_discard_pile())
	_deck_view_panel.show()

func _populate_list(container: VBoxContainer, cards: Array[CardData]) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()
	for card: CardData in cards:
		var lbl: Label = Label.new()
		lbl.text = card.get_description()
		container.add_child(lbl)

func _on_proceed() -> void:
	GameManager.end_combat(_engine.player.hp)
```

- [ ] **Step 3: 手动验证**

运行项目（`mcp__godot__run_project` 或直接启动 Godot），进入一场普通战斗，检查：
- 敌人面板正常显示（名字、HP、意图）
- 打出攻击牌时进入选敌模式（敌人按钮亮起）
- 点击敌人按钮后攻击结算，退出选敌模式
- 打出 defend / energize / insight 时直接生效，无需选敌
- 点击手牌取消选敌模式后可重新选牌
- 敌人死亡后按钮显示"已死亡"并变灰
- 所有敌人死亡后战斗结束显示"胜利！"

- [ ] **Step 4: Commit**

```bash
git add combat/CombatScreen.tscn combat/CombatScreen.gd
git commit -m "feat: dynamic multi-enemy panels and card targeting in CombatScreen"
```
