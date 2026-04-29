class_name NodeData
extends Resource

enum Type { COMBAT, REST }

var type: Type = Type.COMBAT
var enemy_data: EnemyData
# 有向边：指向下一列可到达的节点，仅运行时赋值，不序列化
var connections: Array[NodeData] = []
var column: int = 0
var row: int = 0
