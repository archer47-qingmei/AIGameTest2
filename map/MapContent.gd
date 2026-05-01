extends Control

var on_draw: Callable

func _draw() -> void:
	if on_draw.is_valid():
		on_draw.call()
