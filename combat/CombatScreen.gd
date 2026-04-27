extends Control

@onready var _lbl_enemy_name: Label    = $VBoxContainer/EnemyPanel/LblEnemyName
@onready var _lbl_enemy_hp: Label      = $VBoxContainer/EnemyPanel/LblEnemyHP
@onready var _lbl_enemy_block: Label   = $VBoxContainer/EnemyPanel/LblEnemyBlock
@onready var _lbl_enemy_intent: Label  = $VBoxContainer/EnemyPanel/LblEnemyIntent
@onready var _lbl_player_hp: Label     = $VBoxContainer/PlayerPanel/LblPlayerHP
@onready var _lbl_player_block: Label  = $VBoxContainer/PlayerPanel/LblPlayerBlock
@onready var _lbl_energy: Label        = $VBoxContainer/PlayerPanel/LblEnergy
@onready var _hand_container: HBoxContainer = $VBoxContainer/HandContainer
@onready var _btn_end_turn: Button     = $VBoxContainer/BtnEndTurn
@onready var _lbl_result: Label        = $LblResult
@onready var _btn_return_menu: Button  = $BtnReturnMenu
@onready var _btn_get_reward: Button   = $BtnGetReward

var _engine: CombatEngine
var _hand_buttons: Array[Button] = []

func _ready() -> void:
	_engine = CombatEngine.new()
	_engine.state_changed.connect(_refresh_ui)
	_engine.combat_ended.connect(_on_combat_ended)
	_btn_end_turn.pressed.connect(_engine.end_turn)
	_btn_return_menu.pressed.connect(GameManager.go_to_menu)
	_btn_get_reward.pressed.connect(GameManager.go_to_reward)
	_engine.setup(GameManager.player_state.deck)

func _on_card_pressed(card: CardData) -> void:
	_engine.play_card(card)

func _refresh_ui() -> void:
	_lbl_enemy_name.text = _engine.enemy.display_name
	_lbl_enemy_hp.text = "生命：%d / %d" % [_engine.enemy.hp, _engine.enemy.max_hp]
	_lbl_enemy_block.text = "格挡：%d" % _engine.enemy.block
	var action: EnemyActionData = _engine.get_current_enemy_action()
	var intent: String = "攻击 %d" % action.value if action.type == "attack" else "格挡 %d" % action.value
	_lbl_enemy_intent.text = "意图：" + intent
	_lbl_player_hp.text = "生命：%d / %d" % [_engine.player.hp, _engine.player.max_hp]
	_lbl_player_block.text = "格挡：%d" % _engine.player.block
	_lbl_energy.text = "能量：%d / 3" % _engine.energy
	_rebuild_hand()

func _rebuild_hand() -> void:
	for btn: Button in _hand_buttons:
		btn.queue_free()
	_hand_buttons.clear()
	for card: CardData in _engine.hand:
		var btn: Button = Button.new()
		btn.text = card.get_description()
		btn.pressed.connect(_on_card_pressed.bind(card))
		_hand_container.add_child(btn)
		_hand_buttons.append(btn)

func _on_combat_ended(result: String) -> void:
	_lbl_result.text = "胜利！" if result == "victory" else "游戏结束"
	_lbl_result.visible = true
	_btn_end_turn.disabled = true
	if result == "victory":
		_btn_get_reward.visible = true
	else:
		_btn_return_menu.visible = true
	for btn: Button in _hand_buttons:
		btn.disabled = true
