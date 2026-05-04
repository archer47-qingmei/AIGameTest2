class_name NodeConfig
extends Resource

enum Type { COMBAT, REST, ELITE, SHOP, CHEST, BOSS }

@export var type: Type = Type.COMBAT
@export var enemy_group: EnemyGroupData
@export var column: int = 0
@export var row: int = 0
@export var reward_relic: RelicData
@export var map_position: Vector2 = Vector2.ZERO
