class_name ItemContextMenu
extends CanvasLayer
## Menú contextual RMB con acciones dinámicas: Usar / Equipar|Desequipar / Combinar.

signal action_selected(action: StringName, item_ui: ItemUI)

var _panel: PanelContainer
var _vbox: VBoxContainer
var _target: ItemUI
var _buttons: Dictionary = {} # StringName -> Button


func _ready() -> void:
	layer = 100
	_panel = PanelContainer.new()
	_panel.visible = false
	add_child(_panel)
	_vbox = VBoxContainer.new()
	_panel.add_child(_vbox)


func open_for(item_ui: ItemUI, screen_pos: Vector2, actions: Array) -> void:
	_target = item_ui
	_clear_buttons()
	for entry in actions:
		var action: StringName = entry.get("action", &"")
		var label: String = entry.get("label", String(action))
		var enabled: bool = entry.get("enabled", true)
		var btn := Button.new()
		btn.text = label
		btn.focus_mode = Control.FOCUS_NONE
		btn.disabled = not enabled
		btn.pressed.connect(_on_action_pressed.bind(action))
		_vbox.add_child(btn)
		_buttons[action] = btn
	_panel.position = screen_pos
	_panel.visible = true


func close_menu() -> void:
	_panel.visible = false
	_target = null
	_clear_buttons()


func is_open() -> bool:
	return _panel.visible


func _clear_buttons() -> void:
	for child in _vbox.get_children():
		child.queue_free()
	_buttons.clear()


func _on_action_pressed(action: StringName) -> void:
	if _target == null:
		return
	var ui := _target
	close_menu()
	action_selected.emit(action, ui)


func _input(event: InputEvent) -> void:
	if not _panel.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT or mb.button_index == MOUSE_BUTTON_RIGHT:
			var rect := _panel.get_global_rect()
			if not rect.has_point(mb.position):
				close_menu()
