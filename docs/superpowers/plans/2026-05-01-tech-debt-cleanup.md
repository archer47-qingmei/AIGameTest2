# v0.25.0 技术债清理 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 清理 5 条已确认技术债：合并重复 CARD_POOL、消除 GameManager 中硬编码遗物奖励、修复 RestScreen 下标同步按钮、RelicData effect_type 改为枚举、魔法数字改为具名常量。

**Architecture:** 全部为纯重构，不新增功能，不改变玩家可见行为。每条债务独立提交，每次提交前通过 Godot 运行验证行为无变化。

**Tech Stack:** Godot 4 GDScript，严格类型，无测试框架（GUT 未安装），验证方式为运行游戏观察行为。

---

## 文件清单

| 操作 | 文件 | 变更说明 |
|------|------|----------|
| 新建 | `CardPool.gd` | CARDS / RELICS 常量唯一来源 |
| 修改 | `RewardEngine.gd` | 删除 CARD_POOL，改用 CardPool.CARDS |
| 修改 | `ShopEngine.gd` | 删除 CARD_POOL / RELIC_POOL，改用 CardPool 常量 |
| 修改 | `NodeConfig.gd` | 新增 `reward_relic: RelicData` 字段 |
| 修改 | `MapGenerator.gd` | 生成 ELITE / BOSS 节点时设置 reward_relic |
| 修改 | `GameManager.gd` | end_combat() 读 node.config.reward_relic，删除硬编码 |
| 修改 | `rest/RestScreen.gd` | _on_upgrade_card 改为传入按钮引用，不用 deck 下标 |
| 修改 | `RelicData.gd` | effect_type 从 String 改为 EffectType 枚举 |
| 修改 | `RelicEngine.gd` | _apply() 改用枚举 match |
| 修改 | `data/relics/burning_gem.tres` | effect_type 字符串 → 整数 0 |
| 修改 | `data/relics/life_ring.tres` | effect_type 字符串 → 整数 1 |
| 修改 | `CombatEngine.gd` | 新增 `const BASE_ENERGY := 3` |
| 修改 | `PlayerState.gd` | 新增 `const REST_HEAL_RATIO := 0.3` |

---

## Task 1: 合并 CARD_POOL 到 CardPool.gd

**Files:**
- Create: `CardPool.gd`
- Modify: `RewardEngine.gd`
- Modify: `shop/ShopEngine.gd`

**背景：** `RewardEngine.gd:4-13` 和 `ShopEngine.gd:4-14` 有完全相同的 `CARD_POOL` 常量数组。新增卡牌时必须改两处。创建 `CardPool.gd` 作为唯一来源。

- [ ] **Step 1: 新建 `CardPool.gd`**

内容如下（项目根目录，与 `RewardEngine.gd` 同级）：

```gdscript
class_name CardPool
extends RefCounted

const CARDS: Array[String] = [
	"res://data/cards/strike.tres",
	"res://data/cards/defend.tres",
	"res://data/cards/bash.tres",
	"res://data/cards/slash.tres",
	"res://data/cards/insight.tres",
	"res://data/cards/quick_strike.tres",
	"res://data/cards/energize.tres",
	"res://data/cards/dash.tres",
	"res://data/cards/entangle.tres",
]

const RELICS: Array[String] = [
	"res://data/relics/burning_gem.tres",
	"res://data/relics/life_ring.tres",
]
```

- [ ] **Step 2: 更新 `RewardEngine.gd`**

删除 `const CARD_POOL` 块（第 4–14 行），将循环中的 `CARD_POOL` 改为 `CardPool.CARDS`：

```gdscript
class_name RewardEngine
extends RefCounted

static func get_options() -> Array[CardData]:
	var pool: Array[CardData] = []
	for path: String in CardPool.CARDS:
		var card := load(path) as CardData
		if card != null:
			pool.append(card)
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))

static func get_gold_reward(is_elite: bool, is_final: bool) -> int:
	if is_final:
		return randi_range(40, 60)
	if is_elite:
		return randi_range(25, 40)
	return randi_range(15, 25)
```

- [ ] **Step 3: 更新 `shop/ShopEngine.gd`**

删除 `const CARD_POOL` 和 `const RELIC_POOL` 块（第 4–18 行），将循环中的引用改为 `CardPool.CARDS` 和 `CardPool.RELICS`：

```gdscript
class_name ShopEngine
extends RefCounted

var inventory_cards: Array[CardData] = []
var inventory_relics: Array[RelicData] = []

func generate() -> void:
	var cards: Array[CardData] = []
	for path: String in CardPool.CARDS:
		var card := load(path) as CardData
		if card != null:
			cards.append(card)
	cards.shuffle()
	inventory_cards.assign(cards.slice(0, mini(4, cards.size())))
	var relics: Array[RelicData] = []
	for path: String in CardPool.RELICS:
		var relic := load(path) as RelicData
		if relic != null:
			relics.append(relic)
	relics.shuffle()
	inventory_relics.assign(relics.slice(0, mini(2, relics.size())))

func buy_card(card: CardData, player_state: PlayerState) -> bool:
	if player_state.gold < card.price:
		return false
	player_state.gold -= card.price
	player_state.deck.append(card.duplicate())
	inventory_cards.erase(card)
	return true

func buy_relic(relic: RelicData, player_state: PlayerState) -> bool:
	if player_state.gold < relic.price:
		return false
	player_state.gold -= relic.price
	player_state.relics.append(relic.duplicate())
	inventory_relics.erase(relic)
	return true
```

- [ ] **Step 4: 运行游戏验证**

用 Godot MCP 工具启动项目，确认：
- 启动无错误
- 打完战斗后奖励界面出现 3 张卡牌选项（RewardEngine 正常工作）
- 进商店后显示 4 张卡牌（ShopEngine 正常工作）

- [ ] **Step 5: Commit**

```bash
git add CardPool.gd RewardEngine.gd shop/ShopEngine.gd
git commit -m "refactor: merge CARD_POOL into single CardPool class"
```

---

## Task 2: NodeConfig 新增 reward_relic，GameManager 读取而非硬编码

**Files:**
- Modify: `NodeConfig.gd`
- Modify: `MapGenerator.gd`
- Modify: `GameManager.gd`

**背景：** `GameManager.gd:60-62` 硬编码了"精英掉燃烧宝石、Boss 掉生命戒指"的逻辑。应将奖励遗物移到 `NodeConfig` 字段，由 `MapGenerator` 在生成节点时设置，`GameManager` 只读接口。

- [ ] **Step 1: 更新 `NodeConfig.gd`，新增 reward_relic 字段**

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

- [ ] **Step 2: 更新 `MapGenerator.gd`**

在现有常量块（`COMBAT_ENEMY_PATHS` 等，第 4–9 行）末尾新增两个常量，并在节点生成时设置 `reward_relic`：

```gdscript
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
```

- [ ] **Step 3: 更新 `GameManager.gd`，`end_combat()` 读取 node config**

将第 56–65 行的 `end_combat()` 改为：

```gdscript
func end_combat(final_hp: int) -> void:
	player_state.hp = final_hp
	pending_gold = RewardEngine.get_gold_reward(is_elite_node(), is_final_node())
	pending_relic = player_state.current_node.config.reward_relic
	go_to_reward()
```

- [ ] **Step 4: 运行游戏验证**

启动游戏，完成一场精英战斗，确认奖励界面仍出现"领取遗物"按钮且是燃烧宝石。完成 Boss 战，确认是生命戒指。

- [ ] **Step 5: Commit**

```bash
git add NodeConfig.gd MapGenerator.gd GameManager.gd
git commit -m "refactor: move reward_relic to NodeConfig, remove hardcoded relic paths from GameManager"
```

---

## Task 3: 修复 RestScreen 下标同步按钮

**Files:**
- Modify: `rest/RestScreen.gd`

**背景：** `RestScreen.gd:30-31` 的 `_on_upgrade_card()` 用 `deck[i]` 下标刷新所有按钮文本，隐式假设 `_upgrade_buttons[i]` 与 `deck[i]` 顺序相同。修复方式：将按钮引用直接绑定到回调，更新时只操作被点击的按钮。

- [ ] **Step 1: 更新 `rest/RestScreen.gd`**

完整新文件内容：

```gdscript
extends Control

@onready var _lbl_heal: Label = $VBoxContainer/LblHeal
@onready var _lbl_hp: Label = $VBoxContainer/LblHP
@onready var _card_list: VBoxContainer = $VBoxContainer/ScrollContainer/CardList
@onready var _btn_continue: Button = $VBoxContainer/BtnContinue

var _upgrade_buttons: Array[Button] = []

func _ready() -> void:
	var state: PlayerState = GameManager.player_state
	_lbl_heal.text = "恢复了 %d 点生命" % state.last_rest_heal
	_lbl_hp.text = "当前生命：%d / %d" % [state.hp, state.max_hp]
	_btn_continue.pressed.connect(GameManager.go_to_map)
	_populate_upgrade_list()

func _populate_upgrade_list() -> void:
	var deck: Array[CardData] = GameManager.player_state.deck
	for card: CardData in deck:
		var btn: Button = Button.new()
		btn.text = card.get_description()
		btn.disabled = card.is_upgraded
		btn.pressed.connect(_on_upgrade_card.bind(card, btn))
		_card_list.add_child(btn)
		_upgrade_buttons.append(btn)

func _on_upgrade_card(card: CardData, btn: Button) -> void:
	card.upgrade()
	btn.text = card.get_description()
	for b: Button in _upgrade_buttons:
		b.disabled = true
```

- [ ] **Step 2: 运行游戏验证**

进入休息站，升级一张卡牌，确认：
- 被升级的按钮文本更新（如"打击"→"打击+"）
- 所有按钮变为灰色（不可再次升级）
- 无报错

- [ ] **Step 3: Commit**

```bash
git add rest/RestScreen.gd
git commit -m "refactor: bind button reference in RestScreen, remove index-based deck sync"
```

---

## Task 4: RelicData effect_type 改为枚举

**Files:**
- Modify: `RelicData.gd`
- Modify: `RelicEngine.gd`
- Modify: `data/relics/burning_gem.tres`
- Modify: `data/relics/life_ring.tres`

**背景：** `RelicEngine._apply()` 用字符串 `"energy"` / `"heal_hp"` 匹配效果类型，.tres 文件写错不会报错。改为 `EffectType` 枚举后，Godot 会在加载时做类型检查。

**注意：** .tres 文件和 GDScript 必须同时更新——枚举在 .tres 中存储为整数（`ENERGY=0`，`HEAL_HP=1`），旧 String 值会导致加载失败。本任务将两个文件在同一次提交中更新。

- [ ] **Step 1: 更新 `RelicData.gd`，新增 EffectType 枚举**

```gdscript
class_name RelicData
extends Resource

enum Trigger { COMBAT_START, TURN_START }
enum EffectType { ENERGY, HEAL_HP }

@export var display_name: String = ""
@export var description: String = ""
@export var trigger: Trigger = Trigger.COMBAT_START
@export var effect_type: EffectType = EffectType.ENERGY
@export var value: int = 0
@export var price: int = 0
```

- [ ] **Step 2: 更新 `RelicEngine.gd`，改用枚举 match**

```gdscript
class_name RelicEngine
extends RefCounted

static func apply_combat_start(relics: Array[RelicData], engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		if relic.trigger == RelicData.Trigger.COMBAT_START:
			_apply(relic, engine)

static func apply_turn_start(relics: Array[RelicData], engine: CombatEngine) -> void:
	for relic: RelicData in relics:
		if relic.trigger == RelicData.Trigger.TURN_START:
			_apply(relic, engine)

static func _apply(relic: RelicData, engine: CombatEngine) -> void:
	match relic.effect_type:
		RelicData.EffectType.ENERGY:
			engine.energy += relic.value
		RelicData.EffectType.HEAL_HP:
			engine.player.hp = mini(engine.player.hp + relic.value, engine.player.max_hp)
```

- [ ] **Step 3: 更新 `data/relics/burning_gem.tres`**

将第 10 行 `effect_type = "energy"` 改为 `effect_type = 0`：

```
[gd_resource type="Resource" script_class="RelicData" format=3]

[ext_resource type="Script" path="res://RelicData.gd" id="1_RelicData"]

[resource]
script = ExtResource("1_RelicData")
display_name = "燃烧宝石"
description = "每次战斗开始时，额外获得 1 点能量。"
trigger = 0
effect_type = 0
value = 1
price = 100
```

- [ ] **Step 4: 更新 `data/relics/life_ring.tres`**

将第 10 行 `effect_type = "heal_hp"` 改为 `effect_type = 1`：

```
[gd_resource type="Resource" script_class="RelicData" format=3]

[ext_resource type="Script" path="res://RelicData.gd" id="1_RelicData"]

[resource]
script = ExtResource("1_RelicData")
display_name = "生命之环"
description = "每回合开始时，恢复 1 点生命。"
trigger = 1
effect_type = 1
value = 1
price = 150
```

- [ ] **Step 5: 运行游戏验证**

启动游戏，进入一场包含精英的地图，拾取燃烧宝石后进入战斗，确认每回合开始额外获得 1 点能量（能量显示为 4）。确认无报错。

- [ ] **Step 6: Commit**

```bash
git add RelicData.gd RelicEngine.gd data/relics/burning_gem.tres data/relics/life_ring.tres
git commit -m "refactor: change RelicData.effect_type from String to EffectType enum"
```

---

## Task 5: 魔法数字改为具名常量

**Files:**
- Modify: `CombatEngine.gd`
- Modify: `PlayerState.gd`

**背景：** `CombatEngine._start_player_turn()` 第 72 行 `energy = 3`，`PlayerState.apply_rest_heal()` 第 16 行 `int(max_hp * 0.3)` 均为内联魔法数字，改为具名常量提升可读性和可维护性。

- [ ] **Step 1: 更新 `CombatEngine.gd`**

在第 1 行类声明下方（`signal state_changed` 之前）新增常量，并更新引用：

```gdscript
class_name CombatEngine
extends RefCounted

const BASE_ENERGY: int = 3

signal state_changed
signal combat_ended(result: String)
```

将第 72 行 `energy = 3` 改为 `energy = BASE_ENERGY`。其余代码不变。

- [ ] **Step 2: 更新 `PlayerState.gd`**

在第 1 行类声明下方新增常量，并更新引用：

```gdscript
class_name PlayerState
extends RefCounted

const REST_HEAL_RATIO: float = 0.3

var deck: Array[CardData] = []
var hp: int = 70
var max_hp: int = 70
var map_all_nodes: Array[NodeData] = []
var available_nodes: Array[NodeData] = []
var completed_nodes: Array[NodeData] = []
var current_node: NodeData = null
var last_rest_heal: int = 0
var relics: Array[RelicData] = []
var gold: int = 0

func apply_rest_heal() -> int:
	last_rest_heal = int(max_hp * REST_HEAL_RATIO)
	hp = mini(hp + last_rest_heal, max_hp)
	return last_rest_heal
```

- [ ] **Step 3: 运行游戏验证**

启动游戏，确认：
- 每回合开始能量为 3（BASE_ENERGY 生效）
- 进入休息站后恢复约 30% 最大生命值（REST_HEAL_RATIO 生效）
- 无报错

- [ ] **Step 4: Commit**

```bash
git add CombatEngine.gd PlayerState.gd
git commit -m "refactor: replace magic numbers with named constants BASE_ENERGY and REST_HEAL_RATIO"
```
