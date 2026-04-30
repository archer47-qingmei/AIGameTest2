class_name PlayerState
extends RefCounted

var deck: Array[CardData] = []
var hp: int = 70
var max_hp: int = 70
var map_all_nodes: Array[NodeData] = []
var available_nodes: Array[NodeData] = []
var completed_nodes: Array[NodeData] = []
var current_node: NodeData = null
var last_rest_heal: int = 0

func apply_rest_heal() -> int:
	last_rest_heal = int(max_hp * 0.3)
	hp = mini(hp + last_rest_heal, max_hp)
	return last_rest_heal
