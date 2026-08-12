extends Node2D
## Demo: drag, combine, equip, consumir, tooltip, cámara.

const ZOOM_MIN := 0.75
const ZOOM_MAX := 2.0
const ZOOM_STEP := 0.1

@onready var camera: Camera2D = $Camera2D
@onready var player_inv: InventoryUI = $InventoryWorld/PlayerInventory
@onready var external_inv: InventoryUI = $InventoryWorld/ExternalInventory
@onready var audio: InventoryAudio = $InventoryAudio
@onready var drag_layer: Node2D = $InventoryWorld/DragLayer

var _inventories: Array[InventoryUI] = []
var _combiner: InventoryCombiner = InventoryCombiner.new()
var _equipment: EquipmentSystem = EquipmentSystem.new()
var _consumable: InventoryConsumable = InventoryConsumable.new()
var _context_menu: ItemContextMenu
var _tooltip: ItemTooltip

var _dragging: bool = false
var _drag_ui: ItemUI
var _drag_source: InventoryUI
var _drag_placement
var _drag_rotated: bool = false
var _drag_grab_offset: Vector2 = Vector2.ZERO
var _drop_valid: bool = false
var _drop_inv: InventoryUI
var _drop_cell: Vector2i = Vector2i.ZERO

var _panning: bool = false
var _target_zoom: float = 1.0

var _combine_mode: bool = false
var _combine_source_ui: ItemUI
var _combine_source_inv: InventoryUI
var _hovered_ui: ItemUI


func _ready() -> void:
	_inventories = [player_inv, external_inv]
	camera.make_current()
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	_target_zoom = camera.zoom.x
	_load_recipes()
	_setup_overlay_ui()
	_spawn_demo_items()
	_refresh_all_equipped_indicators()


func _setup_overlay_ui() -> void:
	_context_menu = ItemContextMenu.new()
	add_child(_context_menu)
	_context_menu.action_selected.connect(_on_context_action)
	_tooltip = ItemTooltip.new()
	add_child(_tooltip)


func _load_recipes() -> void:
	var list: Array[CombinationData] = []
	for file_name in [
		"jam_bread.tres",
		"jam_ham.tres",
		"jam_health_potion.tres",
		"jam_ring.tres",
	]:
		var recipe := load("res://inventory/data/combinations/%s" % file_name) as CombinationData
		if recipe != null:
			list.append(recipe)
	_combiner.set_recipes(list)


func _process(delta: float) -> void:
	var z := lerpf(camera.zoom.x, _target_zoom, clampf(delta * 12.0, 0.0, 1.0))
	camera.zoom = Vector2(z, z)
	if _dragging and _drag_ui != null:
		_update_drag_preview()
	elif not _dragging and not _combine_mode and not _context_menu.is_open():
		_update_hover_tooltip()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		_handle_mouse_button(event as InputEventMouseButton)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event as InputEventMouseMotion)
	elif event is InputEventKey and event.pressed and not event.echo:
		var key := (event as InputEventKey).keycode
		if key == KEY_R and _dragging:
			_toggle_drag_rotation()
			get_viewport().set_input_as_handled()
		elif key == KEY_ESCAPE:
			if _dragging:
				_cancel_drag()
			elif _combine_mode:
				_exit_combine_mode()
			elif _context_menu.is_open():
				_context_menu.close_menu()
			get_viewport().set_input_as_handled()


func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
		_target_zoom = clampf(_target_zoom + ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		get_viewport().set_input_as_handled()
		return
	if event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
		_target_zoom = clampf(_target_zoom - ZOOM_STEP, ZOOM_MIN, ZOOM_MAX)
		get_viewport().set_input_as_handled()
		return
	if event.button_index == MOUSE_BUTTON_MIDDLE:
		_panning = event.pressed
		get_viewport().set_input_as_handled()
		return
	if event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _dragging:
			_cancel_drag()
		elif _combine_mode:
			_exit_combine_mode()
		else:
			_try_open_context_menu()
		get_viewport().set_input_as_handled()
		return
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if _combine_mode:
				_try_select_combine_target()
			elif not _dragging:
				_try_begin_drag()
		elif not event.pressed and _dragging:
			_try_drop()
		get_viewport().set_input_as_handled()


func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if _panning:
		var zoom_factor := camera.zoom.x if camera.zoom.x != 0.0 else 1.0
		camera.position -= event.relative / zoom_factor
		get_viewport().set_input_as_handled()


func _build_context_actions(item_ui: ItemUI) -> Array:
	var actions: Array = []
	var instance: ItemInstance = item_ui.instance
	var data: ItemData = item_ui.item_data
	if data == null or instance == null:
		return actions

	if _consumable.can_use(instance):
		actions.append({"action": &"use", "label": "Usar", "enabled": true})

	if data.is_equipable():
		if _equipment.is_equipped(instance):
			actions.append({"action": &"unequip", "label": "Desequipar", "enabled": true})
		else:
			actions.append({"action": &"equip", "label": "Equipar", "enabled": _equipment.can_equip(instance)})

	var can_combine := _combiner.can_participate(data) and not _equipment.is_equipped(instance)
	actions.append({"action": &"combine", "label": "Combinar", "enabled": can_combine})
	return actions


func _try_open_context_menu() -> void:
	_tooltip.hide_tooltip()
	var world := get_global_mouse_position()
	for inv in _inventories:
		var item_ui := inv.get_item_ui_at_world(world)
		if item_ui == null:
			continue
		_context_menu.open_for(item_ui, get_viewport().get_mouse_position(), _build_context_actions(item_ui))
		return


func _on_context_action(action: StringName, item_ui: ItemUI) -> void:
	if item_ui == null:
		return
	match action:
		&"combine":
			if _equipment.is_equipped(item_ui.instance):
				print("Desequipa antes de combinar.")
				return
			_enter_combine_mode(item_ui)
		&"equip":
			_do_equip(item_ui)
		&"unequip":
			_do_unequip(item_ui)
		&"use":
			_do_use(item_ui)


func _do_equip(item_ui: ItemUI) -> void:
	var previous := _equipment.equip(item_ui.instance)
	_refresh_all_equipped_indicators()
	if item_ui.item_data != null:
		audio.play_item_sound(item_ui.item_data)
	if previous != null:
		print("Reemplazado equipo anterior: ", previous.data.display_name if previous.data else "?")


func _do_unequip(item_ui: ItemUI) -> void:
	_equipment.unequip_instance(item_ui.instance)
	_refresh_all_equipped_indicators()


func _do_use(item_ui: ItemUI) -> void:
	var inv := _find_inventory_of(item_ui)
	if inv == null or item_ui.instance == null:
		return
	if not _consumable.use(item_ui.instance):
		return
	audio.play_item_sound(item_ui.item_data)
	item_ui.refresh_visual()
	if _consumable.is_depleted(item_ui.instance):
		_equipment.unequip_instance(item_ui.instance)
		inv.remove_instance_and_ui(item_ui.instance)
		_refresh_all_equipped_indicators()
		print("Consumible agotado y eliminado.")
	else:
		print("Usos restantes: ", item_ui.instance.uses_remaining, "/", item_ui.item_data.max_uses)


func _refresh_all_equipped_indicators() -> void:
	for inv in _inventories:
		for ui in inv.get_all_item_uis():
			ui.set_equipped_indicator(_equipment.is_equipped(ui.instance))


func _enter_combine_mode(source_ui: ItemUI) -> void:
	_combine_mode = true
	_combine_source_ui = source_ui
	_combine_source_inv = _find_inventory_of(source_ui)
	_tooltip.hide_tooltip()
	_apply_combine_highlights()


func _exit_combine_mode() -> void:
	_combine_mode = false
	_combine_source_ui = null
	_combine_source_inv = null
	_clear_combine_highlights()


func _apply_combine_highlights() -> void:
	if _combine_source_inv == null or _combine_source_ui == null:
		return
	for ui in _combine_source_inv.get_all_item_uis():
		if ui == _combine_source_ui:
			ui.set_combine_highlight(true)
		else:
			var ok := (
				not _equipment.is_equipped(ui.instance)
				and _combiner.is_compatible_pair(_combine_source_ui.item_data, ui.item_data)
			)
			ui.set_combine_highlight(ok)


func _clear_combine_highlights() -> void:
	for inv in _inventories:
		for ui in inv.get_all_item_uis():
			ui.clear_combine_highlight()
			ui.set_equipped_indicator(_equipment.is_equipped(ui.instance))


func _try_select_combine_target() -> void:
	var world := get_global_mouse_position()
	if _combine_source_inv == null:
		_exit_combine_mode()
		return
	var target_ui := _combine_source_inv.get_item_ui_at_world(world)
	if target_ui == null or target_ui == _combine_source_ui:
		print("No se puede combinar.")
		_exit_combine_mode()
		return
	if _equipment.is_equipped(target_ui.instance):
		print("Desequipa antes de combinar.")
		_exit_combine_mode()
		return

	var place_a = _combine_source_inv.grid.get_placement_at(_combine_source_ui.grid_origin)
	var place_b = _combine_source_inv.grid.get_placement_at(target_ui.grid_origin)
	if place_a == null or place_b == null:
		_exit_combine_mode()
		return
	if _combiner.find_recipe(place_a.item, place_b.item) == null:
		print("No se puede combinar.")
		_exit_combine_mode()
		return
	if not _combiner.can_combine(_combine_source_inv.grid, place_a, place_b):
		print("No hay espacio para el resultado.")
		_exit_combine_mode()
		return

	var inv := _combine_source_inv
	inv.remove_item_ui_at(place_a)
	inv.remove_item_ui_at(place_b)
	var combine_sound_item: ItemData = place_a.item
	var result_placement = _combiner.try_combine(inv.grid, place_a, place_b)
	_exit_combine_mode()
	if result_placement == null:
		print("Combinación fallida.")
		return
	var result_ui := inv.create_item_ui_for_placement(result_placement)
	result_ui.set_equipped_indicator(false)
	audio.play_item_sound(combine_sound_item)
	print("Combinado: ", result_placement.item.display_name if result_placement.item else "?")


func _find_inventory_of(item_ui: ItemUI) -> InventoryUI:
	for inv in _inventories:
		if item_ui in inv.get_all_item_uis():
			return inv
	return null


func _update_hover_tooltip() -> void:
	var world := get_global_mouse_position()
	var found: ItemUI = null
	for inv in _inventories:
		found = inv.get_item_ui_at_world(world)
		if found != null:
			break
	if found == _hovered_ui:
		if found != null:
			_tooltip.show_item(found.item_data, get_viewport().get_mouse_position())
		return
	_hovered_ui = found
	if found == null:
		_tooltip.hide_tooltip()
	else:
		_tooltip.show_item(found.item_data, get_viewport().get_mouse_position())


func _try_begin_drag() -> void:
	if _context_menu.is_open():
		_context_menu.close_menu()
		return
	var world := get_global_mouse_position()
	for inv in _inventories:
		var item_ui := inv.get_item_ui_at_world(world)
		if item_ui == null:
			continue
		var cell := inv.world_to_cell(world)
		var placement = inv.grid.get_placement_at(cell)
		if placement == null:
			continue
		_tooltip.hide_tooltip()
		_dragging = true
		_drag_ui = item_ui
		_drag_source = inv
		_drag_placement = placement
		_drag_rotated = placement.rotated
		_drag_grab_offset = item_ui.to_local(world)
		_drag_ui.z_index = 100
		if _drag_ui.get_parent() != drag_layer:
			var global := _drag_ui.global_position
			_drag_ui.get_parent().remove_child(_drag_ui)
			drag_layer.add_child(_drag_ui)
			_drag_ui.global_position = global
		return


func _update_drag_preview() -> void:
	_drop_valid = false
	_drop_inv = null
	if _drag_ui == null:
		return
	var origin_world := get_global_mouse_position() - _drag_grab_offset
	_drag_ui.global_position = origin_world
	for inv in _inventories:
		var local := inv.to_local(origin_world)
		var cell := Vector2i(floori(local.x / InventoryUI.CELL_SIZE), floori(local.y / InventoryUI.CELL_SIZE))
		var ignore = _drag_placement if inv == _drag_source else null
		var can := inv.grid.can_place(_drag_ui.item_data, cell, _drag_rotated, ignore)
		# Bloquear transferencia a otro inventario si está equipado.
		if inv != _drag_source and _equipment.is_equipped(_drag_ui.instance):
			can = false
		var over_inv := inv.contains_world_point(origin_world) or inv.grid.is_position_valid(cell)
		if not over_inv and not can:
			continue
		_drag_ui.global_position = inv.cell_to_world(cell)
		_drop_inv = inv
		_drop_cell = cell
		_drop_valid = can
		_drag_ui.set_preview(can)
		return
	_drag_ui.set_preview(false)


func _toggle_drag_rotation() -> void:
	if _drag_ui == null or _drag_ui.item_data == null:
		return
	if not _drag_ui.item_data.can_rotate:
		return
	_drag_rotated = not _drag_rotated
	_drag_ui.set_rotated(_drag_rotated)
	_update_drag_preview()


func _try_drop() -> void:
	if not _dragging or _drag_ui == null:
		return
	_update_drag_preview()
	if _drop_valid and _drop_inv != null:
		_commit_drop()
	else:
		_cancel_drag()


func _commit_drop() -> void:
	var item := _drag_ui.item_data
	var source := _drag_source
	var dest := _drop_inv
	var cell := _drop_cell
	var rotated := _drag_rotated
	var placement = _drag_placement
	var was_equipped := _equipment.is_equipped(_drag_ui.instance)

	if dest != source and was_equipped:
		print("Desequipa antes de transferir.")
		_cancel_drag()
		return

	if dest == source:
		if source.grid.move_item(placement.origin, cell, rotated):
			var updated = source.grid.get_placement_at(cell)
			source.detach_item_ui(_drag_ui)
			source.bind_item_ui(updated, _drag_ui)
			_drag_ui.set_equipped_indicator(was_equipped)
			audio.play_item_sound(item)
			_end_drag_state()
			return
		_cancel_drag()
		return

	if dest.grid.can_place(item, cell, rotated, null):
		var moved_instance := source.grid.remove_instance(placement.origin)
		source.detach_item_ui(_drag_ui)
		dest.grid.place_instance(moved_instance, cell, rotated)
		var new_placement = dest.grid.get_placement_at(cell)
		dest.bind_item_ui(new_placement, _drag_ui)
		_drag_ui.set_equipped_indicator(false)
		audio.play_item_sound(item)
		_end_drag_state()
		return

	_cancel_drag()


func _cancel_drag() -> void:
	if _drag_ui != null and _drag_source != null and _drag_placement != null:
		var was_equipped := _equipment.is_equipped(_drag_ui.instance)
		_drag_ui.set_rotated(_drag_placement.rotated)
		_drag_source.bind_item_ui(_drag_placement, _drag_ui)
		_drag_ui.set_equipped_indicator(was_equipped)
	_end_drag_state()


func _end_drag_state() -> void:
	if _drag_ui != null:
		_drag_ui.z_index = 0
		_drag_ui.clear_preview()
	_dragging = false
	_drag_ui = null
	_drag_source = null
	_drag_placement = null
	_drop_inv = null
	_drop_valid = false


func _spawn_demo_items() -> void:
	var player_items := [
		["res://inventory/data/items/Jam.tres", Vector2i(0, 0), false],
		["res://inventory/data/items/Bread.tres", Vector2i(1, 0), false],
		["res://inventory/data/items/Ham.tres", Vector2i(2, 0), false],
		["res://inventory/data/items/HealthPotion.tres", Vector2i(4, 0), false],
		["res://inventory/data/items/Ring.tres", Vector2i(6, 0), false],
		["res://inventory/data/items/Bow.tres", Vector2i(0, 3), false],
		["res://inventory/data/items/Water.tres", Vector2i(2, 3), false],
		["res://inventory/data/items/Bomb.tres", Vector2i(4, 3), false],
		["res://inventory/data/items/Sword.tres", Vector2i(6, 3), false],
	]
	var external_items := [
		["res://inventory/data/items/CoreArmor.tres", Vector2i(0, 0), false],
		["res://inventory/data/items/Helmet.tres", Vector2i(4, 0), false],
		["res://inventory/data/items/Shield.tres", Vector2i(8, 0), false],
		["res://inventory/data/items/BigSword.tres", Vector2i(0, 5), false],
		["res://inventory/data/items/PracticeSword.tres", Vector2i(2, 5), false],
		["res://inventory/data/items/EnchantBook.tres", Vector2i(4, 5), false],
		["res://inventory/data/items/StrangeEgg.tres", Vector2i(8, 5), false],
		["res://inventory/data/items/SilverRing.tres", Vector2i(10, 5), false],
	]
	_place_list(player_inv, player_items)
	_place_list(external_inv, external_items)


func _place_list(inv: InventoryUI, entries: Array) -> void:
	for entry in entries:
		var data := load(entry[0]) as ItemData
		assert(data != null, "No se pudo cargar %s" % entry[0])
		var ui := inv.try_place(data, entry[1], entry[2])
		assert(ui != null, "No cabe %s en %s" % [data.item_id, inv.name])
