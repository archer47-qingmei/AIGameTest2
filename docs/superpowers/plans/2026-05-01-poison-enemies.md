# v0.28.0 毒液牌机制与新敌人 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 新增毒液牌机制（敌人将毒液牌塞入玩家抽牌堆，留手扣血）及两种使用该机制的中后期敌人。

**Architecture:** 扩展 `CardData` 加 `is_venom` 标识；`CombatEngine` 新增 poison 行动分支和回合结束毒液结算；新建两个敌人 `.tres` 和一个毒液卡 `.tres`；`MapGenerator` 拆分 EARLY/MID 敌人池。

**Tech Stack:** Godot 4 GDScript，数据层 `.tres` 文件。

---

## 涉及文件

| 文件 | 操作 |
|------|------|
| `CardData.gd` | 新增 `@export var is_venom`，更新 `get_description()` |
| `data/cards/venom.tres` | 新建 |
| `CombatEngine.gd` | 扩展 `end_turn()` 和 `_do_enemy_turn()` |
| `data/enemies/poison_spider.tres` | 新建 |
| `data/enemies/swamp_slime.tres` | 新建 |
| `MapGenerator.gd` | 拆分敌人池，`_random_combat_enemy(col)` |

---

## Task 1: CardData 新增 is_venom 字段 + 创建毒液牌

**Files:**
- Modify: `CardData.gd`
- Create: `data/cards/venom.tres`

**背景：** `CardData.gd` 目前有 `card_name`、`cost`、`price`、`effects` 四个导出字段和一个非导出的 `is_upgraded`。需要新增 `@export var is_venom: bool = false` 以便在 `.tres` 中序列化，并在 `get_description()` 中特判毒液牌的显示文本。

**当前 `CardData.gd` 完整内容（第 1–39 行）：**

```gdscript
class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var price: int = 0
@export var effects: Array[CardEffectData]
var is_upgraded: bool = false

func upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	card_name = card_name + "+"
	for effect: CardEffectData in effects:
		effect.value += effect.upgrade_bonus

func get_description() -> String:
	var dmg: int = 0
	var blk: int = 0
	var drw: int = 0
	var nrg: int = 0
	var wk: int = 0
	var vul: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":       dmg = effect.value
		elif effect.type == "block":      blk = effect.value
		elif effect.type == "draw":       drw = effect.value
		elif effect.type == "energy":     nrg = effect.value
		elif effect.type == "weak":       wk = effect.value
		elif effect.type == "vulnerable": vul = effect.value
	var desc: String = "%s\n费用:%d" % [card_name, cost]
	if dmg > 0: desc += "  攻:%d" % dmg
	if blk > 0: desc += "  挡:%d" % blk
	if drw > 0: desc += "  抽:%d" % drw
	if nrg > 0: desc += "  能:%d" % nrg
	if wk > 0: desc += "  虚弱:%d" % wk
	if vul > 0: desc += "  脆弱:%d" % vul
	return desc
```

- [ ] **Step 1: 替换 CardData.gd**

将 `CardData.gd` 完整替换为以下内容：

```gdscript
class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var price: int = 0
@export var effects: Array[CardEffectData]
@export var is_venom: bool = false
var is_upgraded: bool = false

func upgrade() -> void:
	if is_upgraded:
		return
	is_upgraded = true
	card_name = card_name + "+"
	for effect: CardEffectData in effects:
		effect.value += effect.upgrade_bonus

func get_description() -> String:
	if is_venom:
		return "毒液\n费用:0  留手扣血"
	var dmg: int = 0
	var blk: int = 0
	var drw: int = 0
	var nrg: int = 0
	var wk: int = 0
	var vul: int = 0
	for effect: CardEffectData in effects:
		if effect.type == "damage":       dmg = effect.value
		elif effect.type == "block":      blk = effect.value
		elif effect.type == "draw":       drw = effect.value
		elif effect.type == "energy":     nrg = effect.value
		elif effect.type == "weak":       wk = effect.value
		elif effect.type == "vulnerable": vul = effect.value
	var desc: String = "%s\n费用:%d" % [card_name, cost]
	if dmg > 0: desc += "  攻:%d" % dmg
	if blk > 0: desc += "  挡:%d" % blk
	if drw > 0: desc += "  抽:%d" % drw
	if nrg > 0: desc += "  能:%d" % nrg
	if wk > 0: desc += "  虚弱:%d" % wk
	if vul > 0: desc += "  脆弱:%d" % vul
	return desc
```

- [ ] **Step 2: 创建 data/cards/venom.tres**

创建文件 `data/cards/venom.tres`，内容如下（使用与 strike.tres 相同的 CardData.gd uid `uid://13mprie5g221`）：

```
[gd_resource type="Resource" script_class="CardData" load_steps=2 format=3]

[ext_resource type="Script" uid="uid://13mprie5g221" path="res://CardData.gd" id="1_CardData"]

[resource]
script = ExtResource("1_CardData")
card_name = "毒液"
cost = 0
is_venom = true
```

- [ ] **Step 3: 运行项目验证无解析错误**

使用 `mcp__godot__run_project`（projectPath: `E:\MyWork\AIGameTest2`），等待 3 秒，用 `mcp__godot__get_debug_output` 确认无 GDScript 解析错误（忽略 icon.svg 警告），然后 `mcp__godot__stop_project`。

- [ ] **Step 4: Commit**

```bash
git add CardData.gd data/cards/venom.tres
git commit -m "feat: add is_venom field to CardData and create venom card"
```

---

## Task 2: CombatEngine 毒液结算与 poison 行动

**Files:**
- Modify: `CombatEngine.gd`

**背景：** 需要在两处修改 `CombatEngine.gd`：
1. `end_turn()`：弃牌前统计手牌中的毒液牌数量，直接扣 HP（绕过 block），若玩家死亡立即返回
2. `_do_enemy_turn()`：在 `"attack"` 分支后新增 `"poison"` 分支，往 `_draw_pile` 塞 N 张毒液牌并随机打乱

**Note:** `_do_enemy_turn()` 的 poison 分支依赖 Task 1 创建的 `data/cards/venom.tres`，务必在 Task 1 完成后执行本 Task。

**当前 `end_turn()` 实现（第 62–69 行）：**

```gdscript
func end_turn() -> void:
	for card: CardData in hand:
		_discard_pile.append(card)
	hand.clear()
	_do_enemy_turn()
	state_changed.emit()
	if not _check_end():
		_start_player_turn()
```

**当前 `_do_enemy_turn()` 实现（第 113–121 行）：**

```gdscript
func _do_enemy_turn() -> void:
	enemy.block = 0
	enemy.vulnerable = max(0, enemy.vulnerable - 1)
	var action: EnemyActionData = get_current_enemy_action()
	if action.type == "attack":
		EffectResolver.apply_damage(enemy, player, action.value)
		enemy.weak = max(0, enemy.weak - 1)
	else:
		enemy.add_block(action.value)
```

- [ ] **Step 1: 替换 end_turn()**

将 `CombatEngine.gd` 中的 `end_turn()` 函数（第 62–69 行）替换为：

```gdscript
func end_turn() -> void:
	var venom_count: int = 0
	for card: CardData in hand:
		if card.is_venom:
			venom_count += 1
	if venom_count > 0:
		player.hp = max(0, player.hp - venom_count)
		if _check_end():
			return
	for card: CardData in hand:
		_discard_pile.append(card)
	hand.clear()
	_do_enemy_turn()
	state_changed.emit()
	if not _check_end():
		_start_player_turn()
```

- [ ] **Step 2: 替换 _do_enemy_turn()**

将 `CombatEngine.gd` 中的 `_do_enemy_turn()` 函数（第 113–121 行）替换为：

```gdscript
func _do_enemy_turn() -> void:
	enemy.block = 0
	enemy.vulnerable = max(0, enemy.vulnerable - 1)
	var action: EnemyActionData = get_current_enemy_action()
	if action.type == "attack":
		EffectResolver.apply_damage(enemy, player, action.value)
		enemy.weak = max(0, enemy.weak - 1)
	elif action.type == "poison":
		var venom_card: CardData = load("res://data/cards/venom.tres") as CardData
		for i in action.value:
			_draw_pile.append(venom_card.duplicate())
		_draw_pile.shuffle()
	else:
		enemy.add_block(action.value)
```

- [ ] **Step 3: 运行项目验证**

使用 `mcp__godot__run_project`（projectPath: `E:\MyWork\AIGameTest2`），等待 3 秒，用 `mcp__godot__get_debug_output` 确认无解析错误，然后 `mcp__godot__stop_project`。

- [ ] **Step 4: Commit**

```bash
git add CombatEngine.gd
git commit -m "feat: add poison action handling and venom end-turn damage in CombatEngine"
```

---

## Task 3: 创建新敌人 .tres 文件

**Files:**
- Create: `data/enemies/poison_spider.tres`
- Create: `data/enemies/swamp_slime.tres`

**背景：** 参考 `data/enemies/jaw_worm.tres` 的格式（已知 EnemyData.gd uid: `uid://bp7tc2xnj6g4e`，EnemyActionData.gd uid: `uid://dkqvfnm3r8w5y`）创建两个新敌人。

**毒蜘蛛（col 4–5）：** HP 36，行动：攻击 9 → 投毒 2

**沼泽史莱姆（col 6–7 战斗节点）：** HP 52，行动：投毒 3 → 格挡 7 → 攻击 13

- [ ] **Step 1: 创建 data/enemies/poison_spider.tres**

```
[gd_resource type="Resource" script_class="EnemyData" load_steps=5 format=3]

[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="1_EnemyData"]
[ext_resource type="Script" uid="uid://dkqvfnm3r8w5y" path="res://EnemyActionData.gd" id="2_EnemyActionData"]

[sub_resource type="Resource" id="Action_attack"]
script = ExtResource("2_EnemyActionData")
type = "attack"
value = 9

[sub_resource type="Resource" id="Action_poison"]
script = ExtResource("2_EnemyActionData")
type = "poison"
value = 2

[resource]
script = ExtResource("1_EnemyData")
display_name = "毒蜘蛛"
hp = 36
actions = Array[ExtResource("2_EnemyActionData")]([SubResource("Action_attack"), SubResource("Action_poison")])
```

- [ ] **Step 2: 创建 data/enemies/swamp_slime.tres**

```
[gd_resource type="Resource" script_class="EnemyData" load_steps=6 format=3]

[ext_resource type="Script" uid="uid://bp7tc2xnj6g4e" path="res://EnemyData.gd" id="1_EnemyData"]
[ext_resource type="Script" uid="uid://dkqvfnm3r8w5y" path="res://EnemyActionData.gd" id="2_EnemyActionData"]

[sub_resource type="Resource" id="Action_poison"]
script = ExtResource("2_EnemyActionData")
type = "poison"
value = 3

[sub_resource type="Resource" id="Action_block"]
script = ExtResource("2_EnemyActionData")
type = "block"
value = 7

[sub_resource type="Resource" id="Action_attack"]
script = ExtResource("2_EnemyActionData")
type = "attack"
value = 13

[resource]
script = ExtResource("1_EnemyData")
display_name = "沼泽史莱姆"
hp = 52
actions = Array[ExtResource("2_EnemyActionData")]([SubResource("Action_poison"), SubResource("Action_block"), SubResource("Action_attack")])
```

- [ ] **Step 3: 运行项目验证资源可加载**

使用 `mcp__godot__run_project`（projectPath: `E:\MyWork\AIGameTest2`），等待 3 秒，用 `mcp__godot__get_debug_output` 确认无资源加载错误，然后 `mcp__godot__stop_project`。

- [ ] **Step 4: Commit**

```bash
git add data/enemies/poison_spider.tres data/enemies/swamp_slime.tres
git commit -m "feat: add poison_spider and swamp_slime enemy data"
```

---

## Task 4: MapGenerator 拆分敌人池

**Files:**
- Modify: `MapGenerator.gd`

**背景：** 当前 `MapGenerator.gd` 有 `COMBAT_ENEMY_PATHS` 常量，`_random_combat_enemy()` 无参数。需要：
1. 删除 `COMBAT_ENEMY_PATHS`，新增 `EARLY_ENEMY_PATHS`（col 0–3）和 `MID_ENEMY_PATHS`（col 4–7）
2. `_random_combat_enemy(col: int)` 按范围选池
3. `_make_column()` 中对 COMBAT 节点传入 `col`

**当前相关代码：**

```gdscript
const COMBAT_ENEMY_PATHS: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
...
static func _random_combat_enemy() -> EnemyData:
	return load(COMBAT_ENEMY_PATHS[randi() % COMBAT_ENEMY_PATHS.size()]) as EnemyData
```

在 `_make_column()` 内：

```gdscript
		NodeConfig.Type.COMBAT:
			nd.config.enemy_data = _random_combat_enemy()
```

- [ ] **Step 1: 替换 COMBAT_ENEMY_PATHS 为两个分池常量**

将 `MapGenerator.gd` 中的：

```gdscript
const COMBAT_ENEMY_PATHS: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
```

替换为：

```gdscript
const EARLY_ENEMY_PATHS: Array[String] = [
	"res://data/enemies/jaw_worm.tres",
	"res://data/enemies/fire_lizard.tres",
]
const MID_ENEMY_PATHS: Array[String] = [
	"res://data/enemies/poison_spider.tres",
	"res://data/enemies/swamp_slime.tres",
]
```

- [ ] **Step 2: 替换 _random_combat_enemy()**

将：

```gdscript
static func _random_combat_enemy() -> EnemyData:
	return load(COMBAT_ENEMY_PATHS[randi() % COMBAT_ENEMY_PATHS.size()]) as EnemyData
```

替换为：

```gdscript
static func _random_combat_enemy(col: int) -> EnemyData:
	var paths: Array[String] = EARLY_ENEMY_PATHS if col <= 3 else MID_ENEMY_PATHS
	return load(paths[randi() % paths.size()]) as EnemyData
```

- [ ] **Step 3: 更新 _make_column() 中的调用**

将 `_make_column()` 内的：

```gdscript
		NodeConfig.Type.COMBAT:
			nd.config.enemy_data = _random_combat_enemy()
```

替换为：

```gdscript
		NodeConfig.Type.COMBAT:
			nd.config.enemy_data = _random_combat_enemy(col)
```

- [ ] **Step 4: 运行项目验证**

使用 `mcp__godot__run_project`（projectPath: `E:\MyWork\AIGameTest2`），等待 3 秒，用 `mcp__godot__get_debug_output` 确认无解析错误，然后 `mcp__godot__stop_project`。

- [ ] **Step 5: Commit**

```bash
git add MapGenerator.gd
git commit -m "feat: split enemy pools by column range in MapGenerator"
```
