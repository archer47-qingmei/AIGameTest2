class_name EnemyData
extends Resource

@export var display_name: String
@export var hp: int
@export var actions: Array[EnemyActionData]
@export var random_actions: bool = false
@export var phase2_threshold: float = 0.0
@export var phase2_actions: Array[EnemyActionData] = []
@export var copies_player_cards: bool = false
@export var periodic_interval: int = 0
@export var periodic_action: EnemyActionData = null
