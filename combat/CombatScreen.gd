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
