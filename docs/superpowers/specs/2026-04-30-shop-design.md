# 商店系统 Design Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 新增商店节点类型，玩家可花金币购买卡牌和遗物；金币作为战斗奖励选项与卡牌、遗物同级。

**Architecture:** 新增 ShopEngine（RefCounted）处理商店业务逻辑，ShopScreen（Control）纯显示；金币存储在 PlayerState；RewardEngine 扩展生成金币奖励；MapGenerator 在中间列随机放置一个 SHOP 节点。

**Tech Stack:** Godot 4 GDScript，严格类型，数据通过 .tres 文件外置，遵循现有 CLAUDE.md 架构原则。

---

## 第一段：数据层

### CardData.gd
新增字段：
```gdscript
@export var price: int = 0
```

### RelicData.gd
新增字段：
```gdscript
@export var price: int = 0
```

### NodeConfig.gd
`Type` 枚举新增 `SHOP`：
```gdscript
enum Type { COMBAT, REST, ELITE, BOSS, SHOP }
```

### .tres 文件价格配置

卡牌价格（普通卡 30，稀有卡 50）：

| 文件 | price |
|------|-------|
| strike.tres | 30 |
| defend.tres | 30 |
| bash.tres | 50 |
| slash.tres | 30 |
| dash.tres | 30 |
| energize.tres | 50 |
| entangle.tres | 30 |
| insight.tres | 30 |
| quick_strike.tres | 30 |

遗物价格：

| 文件 | price |
|------|-------|
| burning_gem.tres | 100 |
| life_ring.tres | 150 |

---

## 第二段：PlayerState + 金币系统

### PlayerState.gd
新增字段：
```gdscript
var gold: int = 0
```

### RewardEngine.gd
新增方法，根据节点类型返回金币奖励范围：
```gdscript
func get_gold_reward(node_type: NodeConfig.Type) -> int:
    match node_type:
        NodeConfig.Type.COMBAT:  return randi_range(15, 25)
        NodeConfig.Type.ELITE:   return randi_range(25, 40)
        NodeConfig.Type.BOSS:    return randi_range(40, 60)
        _:                       return 0
```

### RewardScreen.gd
新增"拾取 X 金币"按钮，与遗物选择、卡牌选择同级展示。点击后调用 `GameManager.collect_gold(amount)`，按钮变为已领取状态（禁用）。

### GameManager.gd
新增方法：
```gdscript
func collect_gold(amount: int) -> void:
    player_state.gold += amount
```

金币不强制领取，玩家可选择不点。

---

## 第三段：地图 SHOP 节点

### MapGenerator.gd
生成地图时，在第 1 列或第 2 列随机选一行替换为 SHOP 节点。规则：
- 每局保证出现 **1 个** SHOP 节点
- 仅出现在 col 1 或 col 2（不在 col 0 起点和 col 3 Boss 列）
- 随机选列（col 1 或 col 2），再随机选该列的一行

### GameManager.gd
`Phase` 枚举新增 `SHOP`：
```gdscript
enum Phase { MENU, MAP, COMBAT, REWARD, REST, SHOP, WIN, GAME_OVER }
```

`select_node()` 新增分支：
```gdscript
NodeConfig.Type.SHOP:
    go_to_shop()
```

新增方法：
```gdscript
func go_to_shop() -> void:
    current_phase = Phase.SHOP
    get_tree().change_scene_to_file("res://shop/ShopScreen.tscn")
```

### MapScreen.gd
`_get_node_label()` 新增 SHOP 类型显示：
```gdscript
NodeConfig.Type.SHOP: return "商"
```

---

## 第四段：ShopEngine + ShopScreen

### ShopEngine.gd（新建，RefCounted）
```gdscript
class_name ShopEngine
extends RefCounted

var inventory_cards: Array[CardData] = []
var inventory_relics: Array[RelicData] = []

func generate(card_pool: Array[CardData], relic_pool: Array[RelicData]) -> void:
    # 从 card_pool 随机取 4 张（不重复）
    # 从 relic_pool 随机取 1~2 个（不重复）

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
    player_state.relics.append(relic)
    inventory_relics.erase(relic)
    return true
```

### ShopScreen.gd（新建，Control）
- `_ready()`：创建 ShopEngine，调用 `generate()`，渲染 UI
- 顶部 Label 显示当前金币
- 卡牌区：每张卡一个 Button，`text = "%s  %d金" % [card.get_description(), card.price]`，`disabled = player_state.gold < card.price`
- 遗物区：每个遗物一个 Button，同上
- 购买后：调用 `_engine.buy_card()` / `_engine.buy_relic()`，刷新金币 Label，移除已购按钮
- 底部"离开商店"Button → `GameManager.go_to_map()`

### ShopScreen.tscn（新建）
```
ShopScreen (Control)
└── VBoxContainer
    ├── LblGold (Label)
    ├── LblCards (Label)          ← "卡牌"
    ├── CardList (VBoxContainer)
    ├── LblRelics (Label)         ← "遗物"
    ├── RelicList (VBoxContainer)
    └── BtnLeave (Button)         ← "离开商店"
```

### 卡牌池与遗物池

ShopEngine.generate() 所需的完整池由 GameManager 传入：
- 卡牌池：`data/cards/` 下全部 9 张 CardData（preload）
- 遗物池：`data/relics/` 下全部 2 个 RelicData（preload）

GameManager 新增常量：
```gdscript
const SHOP_CARD_POOL: Array[CardData] = [
    preload("res://data/cards/strike.tres"),
    # ... 其余 8 张
]
const SHOP_RELIC_POOL: Array[RelicData] = [
    preload("res://data/relics/burning_gem.tres"),
    preload("res://data/relics/life_ring.tres"),
]
```

---

## PlayerState.relics 字段

若 PlayerState 尚未包含 `relics` 字段，需新增：
```gdscript
var relics: Array[RelicData] = []
```

RelicEngine 已依赖此数组触发遗物效果，确认字段名一致。

---

## 不做的事（本版范围外）

- 移除卡牌（本版不加）
- 商店刷新/重新滚动商品
- 卡牌升级出售
