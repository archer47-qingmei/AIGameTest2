# 竖向地图 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 将 MapScreen 节点坐标从横向布局改为竖向布局，起点在屏幕底部，Boss 在顶部。

**Architecture:** 只修改 `map/MapScreen.gd` 中的 `_get_node_pos()` 函数，将 column 映射到 Y 轴（col 0=底部，col 3=顶部），row 映射到 X 轴（row 0=左，row 1=右）。连线绘制、按钮生成、标签逻辑均不变。

**Tech Stack:** Godot 4 GDScript，项目分辨率 480×854（竖屏，已有）。

---

## Task 1: 替换 `_get_node_pos()` 为竖向坐标映射

**Files:**
- Modify: `map/MapScreen.gd`

**背景：** 当前 `_get_node_pos()` 将 column 映射到 X 轴（100/210/320/430），row 映射到 Y 轴（250/500）。在 480×854 的竖屏画布上，这导致地图节点横向排列在屏幕中部。新实现将列映射到 Y 轴，行映射到 X 轴，节点从底（起点）到顶（Boss）分布。

**当前 `_get_node_pos()` 实现（第 50–59 行）：**

```gdscript
func _get_node_pos(nd: NodeData) -> Vector2:
	if nd.config.column == 3:
		return Vector2(430.0, 375.0)
	var col_x: float
	match nd.config.column:
		0: col_x = 100.0
		1: col_x = 210.0
		2: col_x = 320.0
		_: col_x = 100.0
	return Vector2(col_x, 250.0 if nd.config.row == 0 else 500.0)
```

- [ ] **Step 1: 替换 `_get_node_pos()` 实现**

将 `map/MapScreen.gd` 中的 `_get_node_pos()` 函数（第 50–59 行）替换为：

```gdscript
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
```

其余代码（`_ready`、`_build_map`、`_draw`、`_get_node_label`）不变。

- [ ] **Step 2: 运行游戏验证**

使用 `mcp__godot__run_project` 启动项目（projectPath: `E:\MyWork\AIGameTest2`），用 `mcp__godot__get_debug_output` 确认无 GDScript 解析错误（`icon.svg` 报错是预存问题，忽略）。然后 `mcp__godot__stop_project`。

- [ ] **Step 3: Commit**

```bash
git add map/MapScreen.gd
git commit -m "feat: vertical map layout for portrait screen"
```
