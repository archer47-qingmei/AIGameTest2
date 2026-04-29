class_name PlayerState
extends RefCounted

var deck: Array[CardData] = []
var hp: int = 70
var max_hp: int = 70
var map_all_nodes: Array[NodeData] = []
var available_nodes: Array[NodeData] = []
var completed_nodes: Array[NodeData] = []
var current_node: NodeData = null
