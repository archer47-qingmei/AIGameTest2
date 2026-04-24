# Phase 1 战斗系统设计文档

**日期**：2026-04-24  
**项目**：AIGameTest2（Godot 4.6 + GDScript）  
**范围**：Phase 1 — 极简可玩战斗（硬编码牌组 + 单个敌人）

---

## 背景

本项目是 AIGameTest（第一版）的重启。第一版失败的根本原因是一次性生成 36 个文件，导致循环类型依赖和级联报错无法定位。

本次采用方案 A（平铺极简）：Phase 1 只有 4 个文件，所有战斗逻辑集中在一处，确保任何错误都可立刻定位。Phase 1 通过验证后，再按模块逐步抽离。

---

## 目标

在 Godot 4.6 里实现一个可点击的最简战斗场景：
- 玩家可以点击手牌打出卡牌
- 打完一场完整战斗（胜利或游戏结束）
- 没有主菜单、地图、奖励、商店

---

## 文件结构

```
res://
├── CardData.gd
├── Combatant.gd
└── combat/
    ├── CombatScreen.tscn
    └── CombatScreen.gd
```

不使用 Autoload、EventBus、.tres 数据文件。牌组和敌人数据硬编码在 `CombatScreen._setup()` 内。

---

## 数据模型

### CardData.gd

```gdscript
class_name CardData
extends Resource

@export var card_name: String
@export var cost: int
@export var damage: int
@export var block: int
```

Phase 1 只有攻击和格挡两种效果。不使用 `CardEffectData` 数组。

### 硬编码牌组

| 卡牌 | 数量 | 费用 | 攻击 | 格挡 |
|------|------|------|------|------|
| Strike | 4 | 1 | 6 | 0 |
| Defend | 4 | 1 | 0 | 5 |
| Bash | 1 | 2 | 8 | 0 |

起始牌库 9 张，每回合抽 5 张，3 点能量。

### Combatant.gd

```gdscript
class_name Combatant
extends RefCounted

var display_name: String
var hp: int
var max_hp: int
var block: int
```

方法：
- `take_damage(amount: int)` — 先抵 block，再扣 HP，block 归零（不低于 0）
- `add_block(amount: int)` — 累加 block

不发信号，不持有节点引用。`CombatScreen` 调用完方法后自行刷新 UI。

### 硬编码敌人：颚虫（Jaw Worm）

- HP：44
- 行动模式：奇数回合攻击 11，偶数回合格挡 6（严格交替）

---

## 战斗循环

```
_start_player_turn()
  ├─ energy = 3
  ├─ 从牌库抽 5 张（不足时自动洗入弃牌堆再抽）
  └─ 刷新 UI，等待玩家输入

玩家点击卡牌按钮
  ├─ 检查 energy >= card.cost
  ├─ 执行效果（damage → enemy.take_damage / block → player.add_block）
  ├─ 从手牌移除，按钮 queue_free()
  ├─ 刷新 UI
  └─ _check_end()

玩家点击 End Turn
  ├─ 弃掉手牌中剩余卡牌（queue_free 按钮）
  ├─ _do_enemy_turn()
  │   ├─ 奇数回合：player.take_damage(11)
  │   └─ 偶数回合：enemy.add_block(6)
  ├─ 刷新 UI
  ├─ _check_end()
  └─ _start_player_turn()
```

### `_check_end()`

- `enemy.hp <= 0` → 显示 "Victory!"，禁用所有交互按钮
- `player.hp <= 0` → 显示 "Game Over"，禁用所有交互按钮

---

## UI 结构

### 节点树

```
CombatScreen (Control, 全屏)
└── VBoxContainer
    ├── EnemyPanel (VBoxContainer)
    │   ├── LblEnemyName   (Label)
    │   ├── LblEnemyHP     (Label)
    │   ├── LblEnemyBlock  (Label)
    │   └── LblEnemyIntent (Label)
    ├── PlayerPanel (VBoxContainer)
    │   ├── LblPlayerHP    (Label)
    │   ├── LblPlayerBlock (Label)
    │   └── LblEnergy      (Label)
    ├── HandContainer (HBoxContainer)
    └── BtnEndTurn (Button)
└── LblResult (Label, 默认隐藏)
```

### 卡牌按钮规则

- 在 `_draw_hand()` 里动态 `Button.new()`，文本格式：`"[卡名]\n费用:{cost}  攻:{damage}  挡:{block}"`
- `pressed` 信号用 `.bind(card_data)` 绑定，回调签名：`_on_card_pressed(card_data: CardData)`
- 所有按钮引用存入 `_hand_buttons: Array[Button]`，弃牌时统一 `queue_free()` 并清空数组

### 节点引用方式

所有 Label / Button 节点通过 `@onready var` 在脚本顶部声明，**不使用 `find_child()`**（v1 的坑）：

```gdscript
@onready var _lbl_enemy_hp: Label = $VBoxContainer/EnemyPanel/LblEnemyHP
# 等等...
```

---

## GDScript 规范（来自 v1 经验教训）

1. **类型数组下标和 pop_back() 必须显式注解**：
   ```gdscript
   # 错误（Godot 4.6 strict 模式下报错）
   var card := _draw_pile[0]
   # 正确
   var card: CardData = _draw_pile[0]
   ```

2. **整数用 `absi()`，浮点用 `absf()`**，避免 `abs()` 返回 Variant

3. **不使用 `find_child()`**，所有节点引用通过 `@onready var` 或构造时直接赋值

4. **跨模块函数参数如需引用战斗引擎，使用无类型注解（Variant）**——Phase 1 无此场景，记录备用

---

## Phase 1 验收标准

- [ ] 项目在 Godot 4.6 中无报错启动，直接进入战斗场景
- [ ] 手牌显示 5 张卡牌按钮
- [ ] 能量不足时点击卡牌无效果
- [ ] 打出攻击牌 → 敌人 HP 减少，UI 刷新
- [ ] 打出格挡牌 → 玩家格挡增加，UI 刷新
- [ ] 点击 End Turn → 敌人行动，UI 刷新，下一回合开始
- [ ] 敌人 HP 归零 → 显示 "Victory!"，按钮禁用
- [ ] 玩家 HP 归零 → 显示 "Game Over"，按钮禁用
- [ ] 牌库抽完后弃牌堆洗入牌库继续抽牌

---

## 后续计划（Phase 2 起）

Phase 1 通过验收后，按以下顺序扩展，每步独立验证：

1. 抽离 `CombatEngine.gd`（从 CombatScreen 中分离回合逻辑）
2. 抽离 `EffectResolver.gd`（ctx 参数用 Variant，避免循环依赖）
3. 引入 `CardEffectData` 替换 damage/block 硬编码字段
4. 引入 `.tres` 数据文件替换硬编码牌组/敌人
5. 加入 `GameManager`、地图、奖励等完整游戏循环
