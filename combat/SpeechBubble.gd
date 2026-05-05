class_name SpeechBubble
extends Control

const DISPLAY_SECONDS := 3.0

var _label: Label
var _tween: Tween

func _ready() -> void:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_label = Label.new()
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_label)
	add_child(panel)
	modulate.a = 0.0

func show_text(text: String) -> void:
	_label.text = text
	if _tween and _tween.is_running():
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(DISPLAY_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
