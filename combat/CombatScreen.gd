extends Control

# -- 节点引用 --
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

# -- 战斗状态 --
var _player: Combatant
var _enemy: Combatant
var _draw_pile: Array[CardData] = []
var _discard_pile: Array[CardData] = []
var _hand: Array[CardData] = []
var _hand_buttons: Array[Button] = []
var _energy: int = 3
var _turn_number: int = 0

func _ready() -> void:
	_btn_end_turn.pressed.connect(_on_end_turn_pressed)
	_setup()
	_start_player_turn()

func _setup() -> void:
	_player = Combatant.new()
	_player.display_name = "Player"
	_player.hp = 70
	_player.max_hp = 70
	_player.block = 0

	_enemy = Combatant.new()
	_enemy.display_name = "Jaw Worm"
	_enemy.hp = 44
	_enemy.max_hp = 44
	_enemy.block = 0

	# 硬编码牌库
	for i in 4:
		var c: CardData = CardData.new()
		c.card_name = "Strike"
		c.cost = 1
		c.damage = 6
		c.block = 0
		_draw_pile.append(c)

	for i in 4:
		var c: CardData = CardData.new()
		c.card_name = "Defend"
		c.cost = 1
		c.damage = 0
		c.block = 5
		_draw_pile.append(c)

	var bash: CardData = CardData.new()
	bash.card_name = "Bash"
	bash.cost = 2
	bash.damage = 8
	bash.block = 0
	_draw_pile.append(bash)

	_draw_pile.shuffle()

func _start_player_turn() -> void:
	_turn_number += 1
	_energy = 3
	_player.block = 0
	_draw_hand()
	_refresh_ui()

func _draw_hand() -> void:
	_clear_hand()
	for i in 5:
		if _draw_pile.is_empty():
			if _discard_pile.is_empty():
				break
			for card: CardData in _discard_pile:
				_draw_pile.append(card)
			_discard_pile.clear()
			_draw_pile.shuffle()
		if _draw_pile.is_empty():
			break
		var card: CardData = _draw_pile.pop_back()
		_hand.append(card)
		_create_card_button(card)

func _create_card_button(card: CardData) -> void:
	var btn: Button = Button.new()
	btn.text = "%s\n费用:%d  攻:%d  挡:%d" % [card.card_name, card.cost, card.damage, card.block]
	btn.pressed.connect(_on_card_pressed.bind(card))
	_hand_container.add_child(btn)
	_hand_buttons.append(btn)

func _clear_hand() -> void:
	for btn: Button in _hand_buttons:
		btn.queue_free()
	_hand_buttons.clear()
	_hand.clear()

func _on_card_pressed(card: CardData) -> void:
	if _energy < card.cost:
		return
	_energy -= card.cost
	if card.damage > 0:
		_enemy.take_damage(card.damage)
	if card.block > 0:
		_player.add_block(card.block)
	var idx: int = _hand.find(card)
	if idx >= 0:
		_hand.remove_at(idx)
		var btn: Button = _hand_buttons[idx]
		_hand_buttons.remove_at(idx)
		btn.queue_free()
	_discard_pile.append(card)
	_refresh_ui()
	_check_end()

func _on_end_turn_pressed() -> void:
	for card: CardData in _hand:
		_discard_pile.append(card)
	_clear_hand()
	_do_enemy_turn()
	_refresh_ui()
	if not _check_end():
		_start_player_turn()

func _do_enemy_turn() -> void:
	_enemy.block = 0
	if _turn_number % 2 == 1:
		_player.take_damage(11)
	else:
		_enemy.add_block(6)

func _check_end() -> bool:
	if _enemy.hp <= 0:
		_lbl_result.text = "Victory!"
		_lbl_result.visible = true
		_btn_end_turn.disabled = true
		for btn: Button in _hand_buttons:
			btn.disabled = true
		return true
	if _player.hp <= 0:
		_lbl_result.text = "Game Over"
		_lbl_result.visible = true
		_btn_end_turn.disabled = true
		for btn: Button in _hand_buttons:
			btn.disabled = true
		return true
	return false

func _refresh_ui() -> void:
	_lbl_enemy_name.text = _enemy.display_name
	_lbl_enemy_hp.text = "HP: %d / %d" % [_enemy.hp, _enemy.max_hp]
	_lbl_enemy_block.text = "Block: %d" % _enemy.block
	var intent: String = "攻击 11" if _turn_number % 2 == 1 else "格挡 6"
	_lbl_enemy_intent.text = "Intent: " + intent
	_lbl_player_hp.text = "HP: %d / %d" % [_player.hp, _player.max_hp]
	_lbl_player_block.text = "Block: %d" % _player.block
	_lbl_energy.text = "Energy: %d / 3" % _energy
