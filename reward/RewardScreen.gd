extends Control

func _ready() -> void:
	var options: Array[CardData] = RewardEngine.get_options()
	for card: CardData in options:
		var btn := Button.new()
		var dmg: int = 0
		var blk: int = 0
		for effect: CardEffectData in card.effects:
			if effect.type == "damage":
				dmg = effect.value
			elif effect.type == "block":
				blk = effect.value
		btn.text = "%s\n费用:%d  攻:%d  挡:%d" % [card.card_name, card.cost, dmg, blk]
		btn.pressed.connect(_on_card_selected.bind(card))
		$CardContainer.add_child(btn)

func _on_card_selected(card: CardData) -> void:
	GameManager.player_state.deck.append(card.duplicate())
	GameManager.go_to_menu()
