class_name SpeechBubble
extends Label

const DISPLAY_SECONDS := 3.0

var _tween: Tween

func _ready() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.1, 0.85)
	style.corner_radius_top_left = 5
	style.corner_radius_top_right = 5
	style.corner_radius_bottom_left = 5
	style.corner_radius_bottom_right = 5
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 5
	style.content_margin_bottom = 5
	add_theme_stylebox_override("normal", style)
	add_theme_color_override("font_color", Color.WHITE)
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	modulate.a = 0.0

func show_text(new_text: String) -> void:
	text = new_text
	size = get_combined_minimum_size()
	if _tween and _tween.is_running():
		_tween.kill()
	modulate.a = 1.0
	_tween = create_tween()
	_tween.tween_interval(DISPLAY_SECONDS)
	_tween.tween_property(self, "modulate:a", 0.0, 0.3)
