class_name PlayerState
extends RefCounted

const REST_HEAL_RATIO: float = 0.3

var deck: Array[CardData] = []
var hp: int = 70
var max_hp: int = 70
var map_all_nodes: Array[NodeData] = []
var available_nodes: Array[NodeData] = []
var completed_nodes: Array[NodeData] = []
var current_node: NodeData = null
var last_rest_heal: int = 0
var relics: Array[RelicData] = []
var gold: int = 0

func apply_rest_heal() -> int:
	last_rest_heal = int(max_hp * REST_HEAL_RATIO)
	hp = mini(hp + last_rest_heal, max_hp)
	return last_rest_heal
