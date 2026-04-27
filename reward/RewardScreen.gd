extends Control

@onready var _card_container: HBoxContainer = $VBoxContainer/CardContainer

func _ready() -> void:
	var options: Array[CardData] = RewardEngine.get_options()
	for card: CardData in options:
		var btn := Button.new()
		btn.text = card.get_description()
		btn.pressed.connect(_on_card_selected.bind(card))
		_card_container.add_child(btn)

func _on_card_selected(card: CardData) -> void:
	GameManager.player_state.deck.append(card.duplicate())
	GameManager.go_to_map()
