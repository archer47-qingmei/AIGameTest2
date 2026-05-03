extends Control

const ENEMY_SHAKE_KF: Array[Vector2] = [
	Vector2(1.15, 0.85), Vector2(0.9, 1.1), Vector2(1.05, 0.95)
]
const PLAYER_SHAKE_KF: Array[Vector2] = [
	Vector2(1.05, 0.95), Vector2(0.97, 1.03), Vector2(1.02, 0.99)
]

@onready var _enemies_container: HBoxContainer = $VBoxContainer/EnemiesContainer
@onready var _lbl_player_hp: Label     = $VBoxContainer/PlayerCardRow/CardArea/CardStats/LblPlayerHP
@onready var _lbl_player_block: Label  = $VBoxContainer/PlayerCardRow/CardArea/CardStats/LblPlayerBlock
@onready var _lbl_energy: Label        = $VBoxContainer/BottomRow/LeftSection/LblEnergy
@onready var _lbl_sword_intent: Label  = $VBoxContainer/BottomRow/LeftSection/LblSwordIntent
@onready var _player_card: Panel       = $VBoxContainer/PlayerCardRow/CardArea/CardCenter/PlayerCardPanel
@onready var _player_status_row: HBoxContainer = $VBoxContainer/PlayerCardRow/CardArea/CardCenter/PlayerCardPanel/VBoxContainer/PlayerStatusRow
@onready var _hand_area: Control = $VBoxContainer/HandArea
@onready var _btn_end_turn: Button     = $VBoxContainer/BottomRow/RightSection/BtnEndTurn
@onready var _lbl_result: Label        = $LblResult
@onready var _btn_return_menu: Button  = $BtnReturnMenu
@onready var _btn_get_reward: Button   = $BtnGetReward
@onready var _btn_win: Button          = $BtnWin
@onready var _btn_view_deck: Button    = $BtnViewDeck
@onready var _relics_panel: VBoxContainer = $VBoxContainer/BottomRow/LeftSection/RelicsPanel
@onready var _deck_view_panel: Panel   = $DeckViewPanel
@onready var _btn_close_deck: Button   = $DeckViewPanel/VBoxContainer/BtnCloseDeck
@onready var _all_cards_list: VBoxContainer = $DeckViewPanel/VBoxContainer/TabContainer/完整牌组/AllCardsList
@onready var _draw_list: VBoxContainer      = $DeckViewPanel/VBoxContainer/TabContainer/抽牌堆/DrawList
@onready var _discard_list: VBoxContainer   = $DeckViewPanel/VBoxContainer/TabContainer/弃牌堆/DiscardList
@onready var _exhaust_list: VBoxContainer   = $DeckViewPanel/VBoxContainer/TabContainer/消耗区/ExhaustList
@onready var _drag_layer: DragLayer = $DragLayer

var _engine: CombatEngine
var _hand_buttons: Array[Button] = []

func _ready() -> void:
	_lbl_player_hp.add_theme_font_size_override("font_size", 18)
	_lbl_player_block.add_theme_font_size_override("font_size", 18)
	_engine = CombatEngine.new()
	_engine.combat_ended.connect(_on_combat_ended)
	_engine.hits_dealt.connect(_on_hits_dealt)
	_engine.player_damaged.connect(_on_player_damaged)
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
	_engine.state_changed.connect(_refresh_ui)
	_hand_area.resized.connect(_layout_hand)
	_drag_layer.card_played.connect(_on_drag_card_played)
	_drag_layer.drag_cancelled.connect(_on_drag_cancelled)
	_drag_layer.target_changed.connect(_on_drag_target_changed)
	_refresh_ui()

func _build_enemy_panels() -> void:
	for child in _enemies_container.get_children():
		child.free()
	for i in _engine.enemies.size():
		var panel := Panel.new()
		panel.custom_minimum_size = Vector2(150, 120)

		var vbox := VBoxContainer.new()
		vbox.name = "VBoxContainer"
		var lbl_info := Label.new()
		lbl_info.name = "LblInfo"
		lbl_info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var lbl_intent := Label.new()
		lbl_intent.name = "LblIntent"
		var status_row := HBoxContainer.new()
		status_row.name = "StatusRow"
		status_row.add_theme_constant_override("separation", 6)
		vbox.add_child(lbl_info)
		vbox.add_child(lbl_intent)
		vbox.add_child(status_row)
		panel.add_child(vbox)

		var btn := Button.new()
		btn.name = "BtnOverlay"
		btn.flat = true
		btn.disabled = true
		panel.add_child(btn)

		_enemies_container.add_child(panel)
		vbox.anchor_right = 1.0
		vbox.anchor_bottom = 1.0
		btn.anchor_right = 1.0
		btn.anchor_bottom = 1.0

func _refresh_ui() -> void:
	for i in _engine.enemies.size():
		var e: Combatant = _engine.enemies[i]
		var panel: Panel = _enemies_container.get_child(i) as Panel
		var lbl_info: Label = panel.get_node("VBoxContainer/LblInfo") as Label
		var lbl_intent: Label = panel.get_node("VBoxContainer/LblIntent") as Label
		var status_row: HBoxContainer = panel.get_node("VBoxContainer/StatusRow") as HBoxContainer
		var btn: Button = panel.get_node("BtnOverlay") as Button
		if e.hp <= 0:
			lbl_info.text = "%s\n(已死亡)" % e.display_name
			lbl_intent.text = ""
			btn.disabled = true
		else:
			var action: EnemyActionData = _engine.get_enemy_action(i)
			lbl_info.text = "%s\nHP:%d/%d 挡:%d" % [e.display_name, e.hp, e.max_hp, e.block]
			lbl_intent.text = _intent_text(action, e)
			btn.disabled = true
		_build_status_row(status_row, e)
	_lbl_player_hp.text = "生命：%d / %d" % [_engine.player.hp, _engine.player.max_hp]
	_lbl_player_block.text = "格挡：%d" % _engine.player.block
	_lbl_energy.text = "真气：%d / %d" % [_engine.energy, _engine.energy_cap]
	_lbl_sword_intent.text = "剑意：%d / %d" % [_engine.player.sword_intent, _engine.player.sword_intent_cap]
	for child in _relics_panel.get_children():
		child.queue_free()
	for r: RelicData in GameManager.player_state.relics:
		var lbl: Label = Label.new()
		lbl.text = r.display_name
		_relics_panel.add_child(lbl)
	_build_status_row(_player_status_row, _engine.player)
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

func _on_card_button_down(card_index: int) -> void:
	var card: CardData = _engine.hand[card_index]
	if _engine.energy < card.cost:
		_shake_card(card_index)
		return
	var btn := _hand_buttons[card_index]
	btn.position.y -= 20
	var enemy_positions: Array[Vector2] = []
	var enemy_indices: Array[int] = []
	var damage_labels: Array[String] = []
	var damage_boosted: Array[bool] = []
	for i in _engine.enemies.size():
		if _engine.enemies[i].hp > 0:
			var panel := _enemies_container.get_child(i) as Panel
			enemy_positions.append(panel.get_global_rect().get_center())
			enemy_indices.append(i)
			var preview := EffectResolver.preview_damage(card, _engine.player, _engine.enemies[i])
			if preview.is_empty():
				damage_labels.append("")
				damage_boosted.append(false)
			elif preview.hits == 1:
				damage_labels.append(str(preview.per_hit))
				damage_boosted.append(preview.boosted)
			else:
				damage_labels.append("%d×%d" % [preview.per_hit, preview.hits])
				damage_boosted.append(preview.boosted)
	if card.target_type == "all":
		for idx in enemy_indices:
			(_enemies_container.get_child(idx) as Panel).modulate = Color(1.3, 1.3, 1.0)
	_drag_layer.begin_drag(
		card_index,
		btn.global_position,
		card.get_description(),
		card.target_type,
		enemy_positions,
		enemy_indices,
		_player_card.get_global_rect().get_center(),
		damage_labels,
		damage_boosted
	)

func _shake_card(card_index: int) -> void:
	var btn := _hand_buttons[card_index]
	var orig_x := btn.position.x
	var tw := create_tween()
	tw.tween_property(btn, "position:x", orig_x + 4.0, 0.05)
	tw.tween_property(btn, "position:x", orig_x - 4.0, 0.05)
	tw.tween_property(btn, "position:x", orig_x + 4.0, 0.05)
	tw.tween_property(btn, "position:x", orig_x, 0.05)

func _clear_target_highlights() -> void:
	for i in _enemies_container.get_child_count():
		(_enemies_container.get_child(i) as Panel).modulate = Color.WHITE

func _on_drag_card_played(card_index: int, target_engine_index: int) -> void:
	_clear_target_highlights()
	_engine.play_card(card_index, target_engine_index)

func _on_drag_cancelled(card_index: int) -> void:
	_clear_target_highlights()
	if card_index >= 0 and card_index < _hand_buttons.size():
		var btn := _hand_buttons[card_index]
		if is_instance_valid(btn):
			btn.position.y += 20

func _on_drag_target_changed(old_engine_index: int, new_engine_index: int) -> void:
	if old_engine_index >= 0 and old_engine_index < _enemies_container.get_child_count():
		(_enemies_container.get_child(old_engine_index) as Panel).modulate = Color.WHITE
	if new_engine_index >= 0 and new_engine_index < _enemies_container.get_child_count():
		(_enemies_container.get_child(new_engine_index) as Panel).modulate = Color(1.3, 1.3, 1.0)

func _rebuild_hand() -> void:
	for btn: Button in _hand_buttons:
		btn.queue_free()
	_hand_buttons.clear()
	for i in _engine.hand.size():
		var card: CardData = _engine.hand[i]
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(110, 150)
		btn.size = Vector2(110, 150)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		btn.text = card.get_description()
		btn.button_down.connect(_on_card_button_down.bind(i))
		_hand_area.add_child(btn)
		_hand_buttons.append(btn)
	_layout_hand()

func _layout_hand() -> void:
	var n := _hand_buttons.size()
	if n == 0:
		return
	const CARD_W := 110.0
	const CARD_H := 150.0
	const CONTAINER_H := 170.0
	const MIN_GAP := 8.0
	var W := _hand_area.size.x
	if W == 0.0:
		W = get_viewport_rect().size.x
	var step := 0.0
	if n > 1:
		var natural_step := CARD_W + MIN_GAP
		var max_step := (W - CARD_W) / float(n - 1)
		step = min(natural_step, max_step)
	var total_w := CARD_W + float(n - 1) * step
	var start_x := (W - total_w) / 2.0
	var H := _hand_area.size.y
	if H == 0.0:
		H = CONTAINER_H
	var start_y := (H - CARD_H) / 2.0
	for i in n:
		_hand_buttons[i].position = Vector2(start_x + float(i) * step, start_y)

func _on_combat_ended(result: String) -> void:
	_btn_end_turn.disabled = true
	for btn: Button in _hand_buttons:
		btn.disabled = true
	for i in _enemies_container.get_child_count():
		var panel: Panel = _enemies_container.get_child(i) as Panel
		(panel.get_node("BtnOverlay") as Button).disabled = true
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
	var draw_pile := _engine.get_draw_pile()
	var discard_pile := _engine.get_discard_pile()
	var exhaust_pile := _engine.get_exhaust_pile()
	var all_cards: Array[CardData] = []
	all_cards.append_array(_engine.hand)
	all_cards.append_array(draw_pile)
	all_cards.append_array(discard_pile)
	all_cards.append_array(exhaust_pile)
	_populate_list(_all_cards_list, all_cards)
	_populate_list(_draw_list, draw_pile)
	_populate_list(_discard_list, discard_pile)
	_populate_list(_exhaust_list, exhaust_pile)
	_deck_view_panel.show()

func _populate_list(container: VBoxContainer, cards: Array[CardData]) -> void:
	for child in container.get_children():
		child.queue_free()
	for card: CardData in cards:
		var lbl: Label = Label.new()
		lbl.text = card.get_description()
		container.add_child(lbl)

func _on_hits_dealt(enemy_index: int, amounts: Array[int]) -> void:
	var panel: Panel = _enemies_container.get_child(enemy_index) as Panel
	if panel == null:
		return
	var tw := create_tween()
	for amount: int in amounts:
		if amount > 0:
			tw.tween_callback(_play_damage_animation.bind(panel, str(amount), ENEMY_SHAKE_KF))
			tw.tween_interval(0.22)

func _on_player_damaged(amount: int) -> void:
	_play_damage_animation(_player_card, "-%d" % amount, PLAYER_SHAKE_KF)

func _play_damage_animation(target: Control, label_text: String, shake_kf: Array[Vector2]) -> void:
	target.pivot_offset = target.size / 2

	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(target, "modulate", Color(1.0, 0.2, 0.2), 0.05)
	flash_tween.tween_property(target, "modulate", Color(1.0, 1.0, 1.0), 0.2)

	var shake_tween: Tween = create_tween()
	for kf: Vector2 in shake_kf:
		shake_tween.tween_property(target, "scale", kf, 0.06)
	shake_tween.tween_property(target, "scale", Vector2(1.0, 1.0), 0.07)

	var lbl: Label = Label.new()
	lbl.text = label_text
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.pivot_offset = Vector2(15, 12)
	lbl.z_index = 10
	add_child(lbl)
	lbl.global_position = target.get_global_rect().get_center() - Vector2(15, 12)

	var direction: float = 1.0 if randi() % 2 == 0 else -1.0
	var drift_x: float = direction * randf_range(20.0, 60.0)

	var flyout_tween: Tween = create_tween().set_parallel(true)
	flyout_tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	flyout_tween.tween_property(lbl, "position:x", lbl.position.x + drift_x, 0.4)
	flyout_tween.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.1)
	flyout_tween.finished.connect(lbl.queue_free)

func _build_status_row(row: HBoxContainer, combatant: Combatant) -> void:
	for child in row.get_children():
		child.free()
	if combatant.weak > 0:
		var lbl := Label.new()
		lbl.text = "虚弱×%d" % combatant.weak
		lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.2))
		row.add_child(lbl)
	if combatant.vulnerable > 0:
		var lbl := Label.new()
		lbl.text = "脆弱×%d" % combatant.vulnerable
		lbl.add_theme_color_override("font_color", Color(1.0, 0.55, 0.1))
		row.add_child(lbl)

func _on_proceed() -> void:
	GameManager.end_combat(_engine.player.hp)
