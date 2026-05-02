extends Control

@onready var _enemies_container: HBoxContainer = $VBoxContainer/EnemiesContainer
@onready var _lbl_player_hp: Label     = $VBoxContainer/PlayerPanel/LblPlayerHP
@onready var _lbl_player_block: Label  = $VBoxContainer/PlayerPanel/LblPlayerBlock
@onready var _lbl_energy: Label        = $VBoxContainer/PlayerPanel/LblEnergy
@onready var _lbl_sword_intent: Label  = $VBoxContainer/PlayerPanel/LblSwordIntent
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
@onready var _exhaust_list: VBoxContainer   = $DeckViewPanel/VBoxContainer/TabContainer/消耗区/ExhaustList

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
	_engine.damage_dealt.connect(_on_damage_dealt)
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
	_refresh_ui()

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
	var card: CardData = _engine.hand[card_index]
	if card.target_type in ["none", "all"]:
		_engine.play_card(card_index, -1)
	else:
		_pending_card_index = card_index
		_set_targeting_mode(true)

func _unhandled_input(event: InputEvent) -> void:
	if _pending_card_index >= 0 and event is InputEventMouseButton and event.pressed:
		_pending_card_index = -1
		_set_targeting_mode(false)

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
	_lbl_energy.text = "真气：%d / %d" % [_engine.energy, _engine.energy_cap]
	_lbl_sword_intent.text = "剑意：%d / %d" % [_engine.player.sword_intent, _engine.player.sword_intent_cap]
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
		btn.custom_minimum_size = Vector2(110, 150)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		btn.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		btn.text = card.get_description()
		btn.pressed.connect(_on_card_pressed.bind(i))
		_hand_container.add_child(btn)
		_hand_buttons.append(btn)
	if _pending_card_index >= 0:
		_set_targeting_mode(true)

func _on_combat_ended(result: String) -> void:
	_pending_card_index = -1
	_btn_end_turn.disabled = true
	for btn: Button in _hand_buttons:
		btn.disabled = true
	for i in _enemies_container.get_child_count():
		(_enemies_container.get_child(i) as Button).disabled = true
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
	for card: CardData in _engine.get_exhaust_pile():
		all_cards.append(card)
	_populate_list(_all_cards_list, all_cards)
	_populate_list(_draw_list, _engine.get_draw_pile())
	_populate_list(_discard_list, _engine.get_discard_pile())
	_populate_list(_exhaust_list, _engine.get_exhaust_pile())
	_deck_view_panel.show()

func _populate_list(container: VBoxContainer, cards: Array[CardData]) -> void:
	for child in container.get_children():
		child.queue_free()
	for card: CardData in cards:
		var lbl: Label = Label.new()
		lbl.text = card.get_description()
		container.add_child(lbl)

func _on_damage_dealt(enemy_index: int, amount: int) -> void:
	var btn: Button = _enemies_container.get_child(enemy_index) as Button
	if btn == null:
		return
	btn.pivot_offset = btn.size / 2

	var flash_tween: Tween = create_tween()
	flash_tween.tween_property(btn, "modulate", Color(1.0, 0.2, 0.2), 0.05)
	flash_tween.tween_property(btn, "modulate", Color(1.0, 1.0, 1.0), 0.2)

	var shake_tween: Tween = create_tween()
	shake_tween.tween_property(btn, "scale", Vector2(1.15, 0.85), 0.06)
	shake_tween.tween_property(btn, "scale", Vector2(0.9, 1.1), 0.06)
	shake_tween.tween_property(btn, "scale", Vector2(1.05, 0.95), 0.06)
	shake_tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.07)

	var lbl: Label = Label.new()
	lbl.text = str(amount)
	lbl.add_theme_font_size_override("font_size", 24)
	lbl.pivot_offset = Vector2(15, 12)
	var btn_center: Vector2 = to_local(btn.get_global_rect().get_center())
	lbl.position = btn_center - Vector2(15, 12)
	lbl.z_index = 10
	add_child(lbl)

	var direction: float = [-1.0, 1.0][randi() % 2]
	var drift_x: float = direction * randf_range(20.0, 60.0)

	var flyout_tween: Tween = create_tween().set_parallel(true)
	flyout_tween.tween_property(lbl, "scale", Vector2(1.5, 1.5), 0.15).set_ease(Tween.EASE_OUT)
	flyout_tween.tween_property(lbl, "position:x", lbl.position.x + drift_x, 0.4)
	flyout_tween.tween_property(lbl, "modulate:a", 0.0, 0.3).set_delay(0.1)
	flyout_tween.finished.connect(lbl.queue_free)

func _on_proceed() -> void:
	GameManager.end_combat(_engine.player.hp)
