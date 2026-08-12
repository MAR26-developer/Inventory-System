class_name ItemTooltip
extends CanvasLayer
## Tooltip simple: display_name + description.

var _panel: PanelContainer
var _title: Label
var _body: Label


func _ready() -> void:
	layer = 90
	_panel = PanelContainer.new()
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(_title)

	_body = Label.new()
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.custom_minimum_size = Vector2(180, 0)
	vbox.add_child(_body)


func show_item(item: ItemData, screen_pos: Vector2) -> void:
	if item == null:
		hide_tooltip()
		return
	_title.text = item.display_name
	_body.text = item.description
	_body.visible = not item.description.is_empty()
	_panel.position = screen_pos + Vector2(12, 12)
	_panel.visible = true


func hide_tooltip() -> void:
	_panel.visible = false


func is_showing() -> bool:
	return _panel.visible
