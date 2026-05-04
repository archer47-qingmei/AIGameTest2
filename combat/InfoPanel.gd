class_name InfoPanel
extends Control

var _overlay: ColorRect
var _lbl_title: Label
var _lbl_desc: RichTextLabel
var _btn_close: Button

func _ready() -> void:
	anchor_right = 1.0
	anchor_bottom = 1.0
	z_index = 10
	visible = false

	_overlay = ColorRect.new()
	_overlay.anchor_right = 1.0
	_overlay.anchor_bottom = 1.0
	_overlay.color = Color(0.0, 0.0, 0.0, 0.5)
	_overlay.mouse_filter = MOUSE_FILTER_STOP
	_overlay.gui_input.connect(_on_overlay_input)
	add_child(_overlay)

	var center := CenterContainer.new()
	center.anchor_right = 1.0
	center.anchor_bottom = 1.0
	center.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(260.0, 0.0)
	center.add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	_lbl_title = Label.new()
	_lbl_title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(_lbl_title)

	vbox.add_child(HSeparator.new())

	_lbl_desc = RichTextLabel.new()
	_lbl_desc.bbcode_enabled = true
	_lbl_desc.fit_content = true
	_lbl_desc.scroll_active = false
	_lbl_desc.custom_minimum_size = Vector2(0.0, 40.0)
	vbox.add_child(_lbl_desc)

	_btn_close = Button.new()
	_btn_close.text = "关闭"
	_btn_close.pressed.connect(hide_info)
	vbox.add_child(_btn_close)

func show_info(title: String, description: String) -> void:
	_lbl_title.text = title
	_lbl_desc.text = description
	visible = true

func hide_info() -> void:
	visible = false

func _on_overlay_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			hide_info()
