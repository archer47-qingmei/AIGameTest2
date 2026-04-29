class_name NodeData
extends Resource

enum Type { COMBAT, REST }

var type: Type = Type.COMBAT
var enemy_data: EnemyData
var connections: Array[NodeData] = []
var col: int = 0
var row: int = 0
