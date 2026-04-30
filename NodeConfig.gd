class_name NodeConfig
extends Resource

enum Type { COMBAT, REST }

@export var type: Type = Type.COMBAT
@export var enemy_data: EnemyData
@export var column: int = 0
@export var row: int = 0
