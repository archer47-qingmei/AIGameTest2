class_name DragLayer
extends Control

signal card_played(card_index: int, target_engine_index: int)
signal drag_cancelled(card_index: int)
signal target_changed(old_engine_index: int, new_engine_index: int)

enum State { IDLE, LIFTED, DRAGGING }

const DRAG_THRESHOLD := 8.0
const TARGET_NONE := "none"
const TARGET_SINGLE := "single"
const TARGET_ALL := "all"
const GHOST_SIZE := Vector2(110.0, 150.0)
const PLAY_ZONE_BOTTOM_RATIO := 0.2
const LINE_WIDTH := 2.0
const LINE_DASH := 12.0
const LINE_COLOR_ENEMY := Color(1.0, 0.3, 0.3, 0.85)
const LINE_COLOR_SELF  := Color(0.3, 1.0, 0.4, 0.85)

var _drag_gen: int = 0
var _state: State = State.IDLE
var _card_index: int = -1
var _target_type: String = ""
var _enemy_local_positions: Array[Vector2] = []
var _enemy_engine_indices: Array[int] = []
var _current_slot: int = -1
var _ghost_card: Panel = null
var _origin_local_pos: Vector2 = Vector2.ZERO
var _target_line_ends: Array[Vector2] = []
var _player_local_pos: Vector2 = Vector2.ZERO
var _damage_labels: Array[String] = []
var _damage_boosted: Array[bool] = []

func begin_drag(card_index: int, card_global_pos: Vector2, card_text: String,
		target_type: String, enemy_global_positions: Array[Vector2],
		enemy_engine_indices: Array[int], player_global_pos: Vector2,
		damage_labels: Array[String], damage_boosted: Array[bool]) -> void:
	_drag_gen += 1
	if _ghost_card != null:
		_ghost_card.queue_free()
		_ghost_card = null
	_card_index = card_index
	_target_type = target_type
	_origin_local_pos = get_global_transform().affine_inverse() * card_global_pos
	_enemy_engine_indices = enemy_engine_indices.duplicate()
	_enemy_local_positions.clear()
	for gp in enemy_global_positions:
		_enemy_local_positions.append(get_global_transform().affine_inverse() * gp)
	_player_local_pos = get_global_transform().affine_inverse() * player_global_pos
	_damage_labels = damage_labels.duplicate()
	_damage_boosted = damage_boosted.duplicate()
	_current_slot = -1
	_state = State.LIFTED
	mouse_filter = MOUSE_FILTER_STOP
	_create_ghost(card_text, _origin_local_pos)
	if target_type == TARGET_ALL:
		_target_line_ends = _enemy_local_positions.duplicate()
		if not _enemy_local_positions.is_empty():
			_current_slot = 0
	elif target_type == TARGET_SINGLE:
		if not _enemy_local_positions.is_empty():
			_current_slot = 0
			_target_line_ends = [_enemy_local_positions[0]]
	elif target_type == TARGET_NONE:
		_target_line_ends = [_player_local_pos]

func _create_ghost(text: String, local_pos: Vector2) -> void:
	_ghost_card = Panel.new()
	_ghost_card.custom_minimum_size = GHOST_SIZE
	_ghost_card.size = GHOST_SIZE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.2)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color.WHITE
	_ghost_card.add_theme_stylebox_override("panel", style)
	_ghost_card.modulate.a = 0.9
	_ghost_card.mouse_filter = MOUSE_FILTER_IGNORE
	var lbl := Label.new()
	lbl.text = text
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lbl.anchor_right = 1.0
	lbl.anchor_bottom = 1.0
	lbl.mouse_filter = MOUSE_FILTER_IGNORE
	_ghost_card.add_child(lbl)
	_ghost_card.position = local_pos
	add_child(_ghost_card)

func _gui_input(event: InputEvent) -> void:
	if _state == State.IDLE:
		return
	if event is InputEventMouseMotion:
		_on_move((event as InputEventMouseMotion).position)
	elif event is InputEventScreenDrag:
		_on_move((event as InputEventScreenDrag).position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
			_on_release(mb.position)
	elif event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if not touch.pressed:
			_on_release(touch.position)

func _on_move(local_pos: Vector2) -> void:
	if _state == State.LIFTED:
		if _origin_local_pos.distance_to(local_pos) > DRAG_THRESHOLD:
			_state = State.DRAGGING
	if _state != State.DRAGGING:
		return
	_ghost_card.position = local_pos - GHOST_SIZE / 2.0
	if _target_type == TARGET_SINGLE:
		var new_slot := _detect_slot(local_pos.x)
		if new_slot != _current_slot:
			var old_engine := _engine_index(_current_slot)
			var new_engine := _engine_index(new_slot)
			_current_slot = new_slot
			_target_line_ends = [_enemy_local_positions[new_slot]]
			target_changed.emit(old_engine, new_engine)
	queue_redraw()

func _on_release(local_pos: Vector2) -> void:
	var viewport_h := get_viewport_rect().size.y
	var above := local_pos.y < viewport_h * (1.0 - PLAY_ZONE_BOTTOM_RATIO)
	var can_play := false
	if _state == State.DRAGGING:
		match _target_type:
			TARGET_NONE, TARGET_ALL:
				can_play = above
			TARGET_SINGLE:
				can_play = above and _current_slot >= 0
	if can_play:
		_finish_play()
	else:
		_start_cancel()

func _finish_play() -> void:
	var idx := _card_index
	var engine_idx := _engine_index(_current_slot) if _target_type == TARGET_SINGLE else -1
	_cleanup()
	card_played.emit(idx, engine_idx)

func _start_cancel() -> void:
	var idx_capture := _card_index
	if _state != State.DRAGGING or _ghost_card == null:
		_cleanup()
		drag_cancelled.emit(idx_capture)
		return
	var gen_capture := _drag_gen
	var tw := create_tween()
	tw.tween_property(_ghost_card, "position", _origin_local_pos, 0.15).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		if gen_capture != _drag_gen:
			return
		_cleanup()
		drag_cancelled.emit(idx_capture)
	)

func _cleanup() -> void:
	if _ghost_card != null:
		_ghost_card.queue_free()
		_ghost_card = null
	_state = State.IDLE
	_card_index = -1
	_target_type = ""
	_enemy_local_positions.clear()
	_enemy_engine_indices.clear()
	_target_line_ends.clear()
	_current_slot = -1
	_player_local_pos = Vector2.ZERO
	_damage_labels.clear()
	_damage_boosted.clear()
	mouse_filter = MOUSE_FILTER_IGNORE
	queue_redraw()

func _detect_slot(drag_x: float) -> int:
	if _enemy_local_positions.is_empty():
		return -1
	var best := 0
	var best_dist := absf(_enemy_local_positions[0].x - drag_x)
	for i in range(1, _enemy_local_positions.size()):
		var dist := absf(_enemy_local_positions[i].x - drag_x)
		if dist < best_dist:
			best_dist = dist
			best = i
	return best

func _engine_index(slot: int) -> int:
	if slot < 0 or slot >= _enemy_engine_indices.size():
		return -1
	return _enemy_engine_indices[slot]

func _draw() -> void:
	if _state != State.DRAGGING or _ghost_card == null:
		return
	var from := _ghost_card.position + Vector2(GHOST_SIZE.x / 2.0, 0.0)
	var color := LINE_COLOR_SELF if _target_type == TARGET_NONE else LINE_COLOR_ENEMY
	for i in _target_line_ends.size():
		var target_pos: Vector2 = _target_line_ends[i]
		draw_dashed_line(from, target_pos, color, LINE_WIDTH, LINE_DASH)
		var slot := _current_slot if _target_type == TARGET_SINGLE else i
		if slot >= 0 and slot < _damage_labels.size() and _damage_labels[slot] != "":
			var label_color := Color(0.3, 1.0, 0.4) if _damage_boosted[slot] else Color.WHITE
			var mid := (from + target_pos) * 0.5
			draw_string(ThemeDB.fallback_font, mid, _damage_labels[slot],
				HORIZONTAL_ALIGNMENT_CENTER, -1, 20, label_color)
