extends Control

@onready var _lbl_gold: Label = $VBoxContainer/LblGold
@onready var _card_list: VBoxContainer = $VBoxContainer/CardList
@onready var _relic_list: VBoxContainer = $VBoxContainer/RelicList
@onready var _btn_leave: Button = $VBoxContainer/BtnLeave

var _engine: ShopEngine

func _ready() -> void:
	_engine = ShopEngine.new()
	_engine.generate(GameManager.player_state)
	_btn_leave.pressed.connect(GameManager.go_to_map)
	_rebuild_ui()

func _rebuild_ui() -> void:
	_lbl_gold.text = "閲戝竵锛?d" % GameManager.player_state.gold
	_rebuild_card_list()
	_rebuild_relic_list()

func _rebuild_card_list() -> void:
	var purchase_blocked: bool = GameManager.player_state.relics.any(
		func(r: RelicData) -> bool: return r.blocks_card_purchase
	)
	for child in _card_list.get_children():
		child.queue_free()
	for card: CardData in _engine.inventory_cards:
		var btn := Button.new()
		btn.text = "%s  [%d閲慮" % [card.get_description(), card.price]
		btn.disabled = GameManager.player_state.gold < card.price or purchase_blocked
		btn.pressed.connect(_on_buy_card.bind(card))
		_card_list.add_child(btn)

func _rebuild_relic_list() -> void:
	var purchase_blocked: bool = GameManager.player_state.relics.any(
		func(r: RelicData) -> bool: return r.blocks_relic_purchase
	)
	for child in _relic_list.get_children():
		child.queue_free()
	for relic: RelicData in _engine.inventory_relics:
		var btn := Button.new()
		btn.text = "%s 鈥?%s  [%d閲慮" % [relic.display_name, _relic_effect_text(relic), relic.price]
		btn.disabled = GameManager.player_state.gold < relic.price or purchase_blocked
		btn.pressed.connect(_on_buy_relic.bind(relic))
		_relic_list.add_child(btn)

func _on_buy_card(card: CardData) -> void:
	_engine.buy_card(card, GameManager.player_state)
	_rebuild_ui()

func _relic_effect_text(relic: RelicData) -> String:
	var parts := relic.description.split("\n\n")
	return parts[0]

func _on_buy_relic(relic: RelicData) -> void:
	_engine.buy_relic(relic, GameManager.player_state)
	_rebuild_ui()
